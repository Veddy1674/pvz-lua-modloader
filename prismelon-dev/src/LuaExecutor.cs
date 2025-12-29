using System.Diagnostics;
using System.Text;
using System.Text.RegularExpressions;
using static Prismelon.src.Utils;

namespace Prismelon.src
{
    public static partial class LuaExecutor
    {
        /* Notes:
         * If folder "mods" is removed externally, there are no checks and the program might crash (Program.cs is safer than this class)
         */

        public static string ModsPath { get; set; } = ""; // set in Program.cs, can be either "" or "mods/"
        // ModsPath is the opposite of Program.gamePath

        private static bool ExecuteSync(string scriptPath, string[]? args, bool printsErrors = true) // both bools to false means 100% silent
        {
            // if gamePath starts with . ("../pvz.exe"), path to core is just "core", otherwise it's "mods/core", simplified by having ModsPath which is "" or "mods/"
            string coreReq = $"-e \"package.path = package.path .. ';{ModsPath}core/?.lua'; package.cpath = package.cpath .. ';{ModsPath}core/?.dll'\"";

            var startInfo = new ProcessStartInfo
            {
                FileName = "lua.exe", // must be an environmental variable! must be 32-bit and not too old
                Arguments = $"{coreReq} \"{scriptPath}\" {string.Join(" ", args ?? [])}",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            try
            {
                using var process = Process.Start(startInfo);
                if (process == null) return false;

                // lua prints in real time (instead of all at the end)
                var errorOutput = new StringBuilder();
                bool hasErrors = false;
                int errorLine = -1;

                process.OutputDataReceived += (sender, e) =>
                {
                    if (!string.IsNullOrEmpty(e.Data) && printsErrors)
                        Console.WriteLine(e.Data);
                };

                process.ErrorDataReceived += (sender, e) =>
                {
                    if (!string.IsNullOrEmpty(e.Data))
                    {
                        errorOutput.AppendLine(e.Data);
                        hasErrors = true;

                        // if not already found...
                        if (errorLine == -1)
                            errorLine = ExtractLineNumberFromError(e.Data);
                    }
                };

                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                process.WaitForExit();

                if (hasErrors && printsErrors)
                {
                    Log("&cError during execution:");
                    Console.WriteLine(errorOutput.ToString());

                    if (errorLine != -1)
                    {
                        string faultyLine = ReadScriptLine(scriptPath, errorLine);
                        Log($"&vError in line {errorLine}: &c" + faultyLine);
                    }

                    return false;
                }

                return process.ExitCode == 0;

                // prints everything AFTER execution
                /*
                string output = process.StandardOutput.ReadToEnd();
                string error = process.StandardError.ReadToEnd();

                process.WaitForExit();

                if (!string.IsNullOrEmpty(output) && printsErrors)
                    Console.WriteLine(output);

                if (!string.IsNullOrEmpty(error))
                {
                    if (!printsErrors) return false;

                    Log("&cError during execution:");
                    Console.WriteLine(error);

                    int line = ExtractLineNumberFromError(error);
                    string faultyLine = ReadScriptLine(scriptPath, line);

                    Log($"&vError in line {line}: &c" + faultyLine);

                    return false;
                }

                return true;
                */
            }
            catch (Exception e)
            {
                if (printsErrors)
                    Log($"&cExecution failed: {e.Message}");

                return false;
            }
        }

        public static bool AModIsRunning { get; private set; } = false; // async execution only

        private static bool ExecuteAsync(string scriptPath, string[]? args)
        {
            string scriptName = Path.GetFileName(scriptPath);

            // create batch
            string batchPath = Path.Combine(Path.GetTempPath(), "prismelon_async.bat");

            string coreReq = $"package.path = package.path .. ';{ModsPath}core/?.lua'; package.cpath = package.cpath .. ';{ModsPath}core/?.dll'";

            string batchContent =
$@"@echo off
title Prismelon - {scriptName}
echo - Executing: {scriptName}...
echo Press Ctrl+C to force exit
echo.
lua.exe -e ""{coreReq}"" ""{scriptPath}"" {string.Join(" ", args ?? [])}
echo.
if %ERRORLEVEL% EQU 0 (
    color 0A
    echo - Mod executed successfully.
) else (
    color 0C
    echo - Mod execution failed...
)
echo.
pause
exit";
            File.WriteAllText(batchPath, batchContent);

            var startInfo = new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = $"/c \"{batchPath}\"",
                UseShellExecute = true,
                CreateNoWindow = false
            };

            try
            {
                var currentModProcess = Process.Start(startInfo);
                AModIsRunning = true;

                // background async task that waits for process exit
                _ = Task.Run(() =>
                {
                    currentModProcess?.WaitForExit();
                    AModIsRunning = false;
                });

                return true;
            }
            catch (Exception e)
            {
                Log($"&cAsynchronous mod execution failed: {e.Message}");
                return false;
            }
        }

        public static string ReadScriptLine(string filePath, int lineNumber)
        {
            // omit try and file check?
            try
            {
                if (!File.Exists(filePath))
                    return $"File not found: {filePath}";

                var lines = File.ReadAllLines(filePath);

                // if exists
                if (lineNumber > 0 && lineNumber <= lines.Length)
                {
                    // lineNumber is 1-based
                    return lines[lineNumber - 1].Trim();
                }

                //return $"Line {lineNumber} not found out of {lines.Length} lines...";

                // this might happen if the error is from another script, so i'm returning a simpler to understand message
                return $"The issue occurred in another file...";
            }
            catch (Exception e)
            {
                return $"Error trying to read line {lineNumber}: {e.Message}";
            }
        }

        // precalc
        private static readonly Regex _errorLineRegex = new Regex(@":(\d+):", RegexOptions.Compiled);

        public static int ExtractLineNumberFromError(string errorMessage)
        {
            // e.g: get the "7" out of: lua.exe: mod\mod.lua:7: unexpected symbol near 'nil'
            // using regex :%d:
            var match = _errorLineRegex.Match(errorMessage);

            if (match.Success && int.TryParse(match.Groups[1].Value, out int lineNumber))
            {
                return lineNumber;
            }
            return -1;
        }

        // realtime memory access
        public static bool ExecuteLuaCode(string code)
        {
            if (string.IsNullOrWhiteSpace(code))
                return false;

            if (ContainsLoops(code))
            {
                Log("&cThe provided code contains loops or periodically called functions (.onUpdate), which are not reccomended.");
                Log("&cPlease create a mod if you wish to run a script asynchronously.");
                return false;
            }

            // create temp wrapped script
            string tempScript = CreateWrappedScript(code);

            bool s = ExecuteSync(tempScript, null, printsErrors: true);

            // cleanup temp file
            if (File.Exists(tempScript))
            {
                try { File.Delete(tempScript); }
                catch { } // ignore
            }
            return s;
        }

        private static int luaReplSessionId = 0;

        private static string CreateWrappedScript(string userCode)
        {
            luaReplSessionId++;
            string tempPath = Path.Combine(Path.GetTempPath(), $"prismelon_repl_{luaReplSessionId}.lua");

            string wrappedCode =
$@"-- Auto-Generated REPL Script
local game, memory = require('core')
memory.start()

-- User code begins
do
    -- Create a copy to avoid 'memory = nil'
    local memory = memory
    {userCode}
end
-- User code ends

memory.stop()
"; // tbf one could run "end memory = nil do" to avoid memory.stop()

            File.WriteAllText(tempPath, wrappedCode);
            return tempPath;
        }

        public static bool EnableSpeedUpMod() // sync!
        {
            if (!DefaultModExists()) return false;

            string scriptPath = ModsPath + "default/speedup.lua";
            if (File.Exists(scriptPath))
                return ExecuteSync(scriptPath, null, printsErrors: false);
            else
            {
                var temp = CreateWrappedScript(
@"
    game.frameDuration(1) -- speed up game

    memory.onUpdate(function()
        local ui = game.getGameUI()

        if (--[[ui == 2 or ]]ui == 3) or memory.isKeyPressed('tab') then
            memory.stopUpdate()
            return true
        end
    end, 16)

    game.frameDuration(10) -- default speed
");
                File.Copy(temp, scriptPath, overwrite: true);

                return ExecuteSync(scriptPath, null, printsErrors: false);
            }
        }

        public static void CreateDefaultMod()
        {
            // shouldn't cause file-used or create folder issues, but just in case...
            try
            {
                var def = ModsPath + "default"; // default or mods/default
                Directory.CreateDirectory(def);

                CopyFolders(def, "reanim", "images", "sounds", "particles");//, "properties", "data", "compiled", "src");

                var gameRoot = ModsPath == "" ? "../" : "";

                var lawnstrings = gameRoot + "properties/LawnStrings.txt";

                //if (File.Exists(lawnstrings))
                File.Copy(lawnstrings, def + "/LawnStrings.txt", overwrite: true);
                //else // removed because the try catch is good enough, but it might be a good idea to be specific about the error
                //Log("&cCouldn't find LawnStrings.txt in the game/properties folder!\nMake sure your game version is exactly 1.0.0.1051 (EN) and the LawnStrings.txt is there!");

                // ignoring bass.dll and game exe

                // create a placeholder default.lua
                File.WriteAllText(def + "/default.lua", "-- placeholder");


                Log("&qDefault Mod created.");
            }
            catch
            {
                Log("&cCouldn't create Default Mod because an error occurred.");
                Log("&cRetry after closing the game process, reopening this executable as administrator.");
                Log("&cAlternatively, copy the folders manually, from the game root to mods/default/");
                Log("&cThe folders are: reanim, images, sounds, particles, and the file LawnStrings.txt inside properties/");
            }
        }

        private static string?[] GetModAssets(string modPath)
        {
            string? reanim = Directory.Exists($"{modPath}/reanim") ? $"{modPath}/reanim" : null;
            string? images = Directory.Exists($"{modPath}/images") ? $"{modPath}/images" : null;
            string? sounds = Directory.Exists($"{modPath}/sounds") ? $"{modPath}/sounds" : null;
            string? particles = Directory.Exists($"{modPath}/particles") ? $"{modPath}/particles" : null;

            return [reanim, images, sounds, particles];
        }

        // returns success
        public static bool ReplaceGameAssetsWithMod(string modPath, out bool modHasAssets) // modHasAssets is wheter GetModAssets() found anything
        {
            modHasAssets = false;
            //var modPath = ModsPath + modName;
            if (!Directory.Exists(modPath)) return false;

            string?[] modFolders = GetModAssets(modPath);
            modHasAssets = modFolders.Any(x => x != null);

            var gameRoot = ModsPath == "" ? "../" : "";
            CopyFolders(gameRoot, modFolders); // nulls are ignored

            var lawnstrings = modPath + "/LawnStrings.txt";

            if (File.Exists(lawnstrings))
                File.Copy(lawnstrings, gameRoot + "properties/LawnStrings.txt", overwrite: true);

            return true;
        }

        private static bool ContainsLoops(string content)
        {
            return content.Contains(".onUpdate") || content.Contains("while true do");
            // extremely simplified, there are workarounds such as obfuscation, but that's on the user.
        }

        // executes if found, returns success
        public static bool ExecuteQuickMod(string scriptName, string[]? args = null)
        {
            var modPath = ModsPath + "quickmods/" + scriptName;
            if (!File.Exists(modPath)) return false;

            // 1. run script, that's it.
            bool async = ContainsLoops(File.ReadAllText(modPath));

            string argsString = args?.Length > 0 ? " &s" + string.Join(" ", args) : "";
            Log($"&aExecuting quick mod: &d{Path.GetFileName(modPath)}{argsString}" + (async ? " &a(asynchronously)" : ""));

            if (async)
                ExecuteAsync(modPath, args);
            else
                ExecuteSync(modPath, args);

            return true;
        }

        public static bool ExecuteMod(string folderName, string[]? args = null)
        {
            var modPath = ModsPath + folderName;
            if (!Directory.Exists(modPath)) return false;

            var mainScript = modPath + "/" + folderName + ".lua";

            if (!File.Exists(mainScript)) // if doesn't find folder name .lua, looks for main.lua
                mainScript = modPath + "/main.lua";

            if (!File.Exists(mainScript))
            {
                // try main.lua...
                Log("&cCouldn't find mod's main script!\nMake sure it is named &v" + folderName + ".lua or &vmain.lua");
                return false;
            }

            // execution
            Program.closeFromLaunch = true; // avoid "manual closure detection" to be triggered falsely
            Program.CloseGame(); // 1. shut down game, waits 500ms for process to close

            ReplaceGameAssetsWithMod(modPath, out bool modHasAssets); // sync, 2. replace game assets with mod assets

            if (modHasAssets)
                Log("&aReplaced game assets with mod's successfully");

            Program.LaunchGame(); // sync, 3. launch and hook game
            Program.HookGame(speedUp: false);

            // 4. run the mod's main script
            bool async = ContainsLoops(File.ReadAllText(mainScript));

            string argsString = args?.Length > 0 ? " &s" + string.Join(" ", args) : "";
            Log($"&aExecuting mod with main script: &d{mainScript}{argsString}" + (async ? " &a(asynchronously)" : ""));

            if (async)
                ExecuteAsync(mainScript, args);
            else
                ExecuteSync(mainScript, args);

            return true;
        }

        public static bool DefaultModExists()
            => Directory.Exists(ModsPath + "default");
    }
}