using Prismelon.src;
using System.Diagnostics;
using static Prismelon.src.Utils;

namespace Prismelon.src
{
    class Program
    {
        public const string version = "v1.0";
        public const string exePvzName = "PlantsVsZombies.exe";

        public static string gamePath = ""; // in current dir or parent

        private static void Main(string[] args)
        {
            #region Looks for game path, creates "mods" folder:

            // if finds .exe in current dir
            if (File.Exists(exePvzName))
            {
                // create "mods" folder if it doesn't exist, returns if error
                if (!CreateDirectory("mods"))
                {
                    Log($"&cFolder '&vmods&c' could not be created. It is necessary for this program to work, try to create it manually.");
                    Exit();
                    return;
                }

                gamePath = exePvzName;
                LuaExecutor.ModsPath = "mods/";
            }
            else if (File.Exists($"..\\{exePvzName}")) // look in parent (probably its inside mods folder)
            {
                if (Path.GetFileName(Directory.GetCurrentDirectory()) is not "mods")
                {
                    Log("&cPrismelon.exe must be in the same folder the game is, or inside the mods folder.");
                    Log("&cAny other path is currently not supported, the mods folder name must be exactly \"mods\".");
                    Exit();
                    return;
                }

                gamePath = $"..\\{exePvzName}";
                // LuaExecutor.ModsPath is already "" (current dir) by default.
            }
            else
            {
                Log($"&c'&v{exePvzName}&c' Not found!\nMake sure Prismelon.exe is in the same folder the game is, or inside the mods folder.");
                Log("&cThe name must be as mentioned, and the version MUST be 1.0.0.1051 (EN), check your file properties to verify.");
                Exit(); // pause
                return;
            }
            #endregion

            ModManager.LoadProfiles(); // load profiles.json in mods folder

            // create "quickmods" folder
            if (!CreateDirectory("mods/quickmods"))
            {
                Log($"&cFolder '&vmods/quickmods&c' could not be created. It is necessary for this program to work, try to create it manually.");
                Exit();
                return;
            }

            // check game version
            if (GetFileVersion(exePvzName) is not "1.0.0.1051")
            {
                Log($"&c'&v{exePvzName}&c' is not the correct version, it must be 1.0.0.1051 (EN), check your game properties to verify.");
                Exit();
                return;
            }

            Log(ascii_art);

            Log("Type a command or \"help\" for a list of commands.");
            CommandLoop(); // sync, waits for commands
        }

        private static void CommandLoop()
        {
            while (true)
            {
                bool gameHooked = gameRunning != null;

                Log((gameHooked ? "&q" : "&c") + "> ", newLine: false); // green = game hooked, red = game not hooked

                var input = Console.ReadLine() ?? "";
                var args = input.Split(' ', StringSplitOptions.RemoveEmptyEntries);

                if (input == "exit") break;

                // ctrl+c interrupts

                switch (args.GetOrDefault(0)) // exceptionless extension, default is ""
                {
                    case "help":
                        #region Detailed info about specific commands
                        if (args.Length > 1)
                        {
                            switch (args[1])
                            {
                                case "launch":
                                    PrintUsage_Lunch();
                                    break;
                                default:
                                    Log($"&cUnknown command: '&v{args[1]}&c'.");
                                    break;
                            }
                            break;
                        }
                        #endregion

                        Log("\n&dPrismelon - " + version);
                        Log("&8Commands &d(arguments preceeded by '--' or surrounded by '[]' are optional, '<>' means required):");
                        Log("&6launch &t--speedup --PID <id> &0- &aLaunches the game and hooks it.");
                        Log("&6detect &0- &aDetects the current running game instance and hooks it.");
                        Log("&6run &t<lua script or path> [args] &0- &aRuns a mod (folder) or quick mod (lua script).");
                        Log("&6lua &t<code> &0- &aCreates and runs a REPL script.");
                        Log("&6createdefaultmod &0- &aCreates a mod which restores the game files to their original state.");
                        Log("&6help &t[command name] &0- &aShow this list of commands, or detailed info about a specific command.");
                        Log("&6exit &0- &aExit the program.\n");
                        break;

                    case "launch":
                        if (ModRunning()) break;

                        LaunchGame(); // closes previous instance
                        Log("&qGame launched (PID: " + gameRunning!.Id + ")");

                        HookGame(args.Contains("--speedup"));
                        break;

                    case "detect":
                        if (ModRunning()) break;

                        if (gameRunning != null)
                        {
                            Log("&tGame is already running (PID: " + gameRunning.Id + ")");
                            break;
                        }

                        bool success = false;
                        if (args.Contains("--PID", out int index) && int.TryParse(args.GetOrDefault(index + 1), out int pid))
                        {
                            try
                            {
                                gameRunning = Process.GetProcessById(pid);

                                Log("&qGame detected (PID: " + gameRunning.Id + ")");
                                success = true;
                            }
                            catch
                            {
                                Log("&cNo PID '&v" + pid + "&c' was found.");
                            }
                        }
                        else
                        {
                            try
                            {
                                var processes = Process.GetProcessesByName(exePvzName[..^4]); // cut off ".exe"
                                if (processes.Length > 0)
                                {
                                    gameRunning = processes[0];
                                    Log("&qGame detected (PID: " + gameRunning.Id + ")");
                                    success = true;
                                }
                                else
                                    Log("&cNo process named '&v" + exePvzName + "&c' was found.\nType &v'launch' &cto launch the game.");
                            }
                            catch
                            {
                                Log("&cSomething went wrong trying to detect the game process..."); // missing perms?
                            }
                        }

                        if (success)
                            HookGame(args.Contains("--speedup"));

                        break;

                    case "run":
                        if (NotHooked(gameHooked) || ModRunning()) break;
                        
                        var path = args.GetOrDefault(1);
                        if (path == "")
                        {
                            PrintUsage_Run();
                            break;
                        }

                        // everything after "run " + path.length is runargs
                        string[]? runargs = args.Length > 2
                            ? args[2..] // get everything from index 2 onwards
                            : null;

                        // finds out if it's a quick mod or a mod and runs it (internal check)
                        if (!LuaExecutor.ExecuteQuickMod(path, runargs))
                            if (!LuaExecutor.ExecuteMod(path, runargs))
                                Log("&cMod or quickmod not found: &v'" + path + "'");
                        break;

                    case "profile":
                        /* subcommands:
                         * create - Creates a new profile, a setup that asks for name, short description
                         * addto <profile name> <mod name> [priority, by default: 0 for quickmods, 1 for mods, highest runs first] [args]
                         * info <profile name> - Prints name, short description, mods and quickmods with priority and args, all as a table darkyellow and yellow
                         * run <profile name>
                        */
                        switch (args.GetOrDefault(1))
                        {
                            case "create":
                                Log("&sCreating new profile... Press ESC anytime to cancel.\n");
                                bool escaped;
                                string name, id = "";

                                do
                                {
                                    name = ReadLineUntilValid(
                                        prompt: "&aProfile Name/ID: &q",
                                        errorMessage: "&cProfile name must be atleast 1 character long, all characters must be alphanumeric",
                                        out escaped,
                                        validator: s => s.Length > 0 && s.All(char.IsLetterOrDigit)
                                    );
                                    if (escaped) break;

                                    id = name.NormalizeToID(); // "Example Mod" -> "example_mod"

                                } while (ModManager.GetProfile(id) != null);

                                if (escaped) break; // double check can be simplified..?
                                Log($"&qProfile ID was set to &w{id}&q");

                                string desc = ReadLineUntilValid(
                                    prompt: "&aShort Description (max 150 chars): &q",
                                    errorMessage: "&cDescription length must be between 10 and 150 characters",
                                    out escaped,
                                    validator: s => s.Length >= 10 && s.Length <= 150
                                );
                                if (escaped) break;

                                ModManager.Profiles.Add(new Profile(id, desc));
                                
                                if (ModManager.SaveProfiles())
                                    Log($"&qProfile &w{id} &qcreated and saved successfully!");

                                break;

                            default:
                                PrintUsage_Profile();
                                break;
                        }

                        break;

                    case "lua":
                        if (NotHooked(gameHooked)) break;

                        // everything after "lua " is executed
                        string luaCode = string.Join(" ", args[1..]); // from index 1 onwards

                        if (string.IsNullOrWhiteSpace(luaCode))
                        {
                            PrintUsage_Lua();
                            break;
                        }

                        bool b = LuaExecutor.ExecuteLuaCode(luaCode); // contains loops check is handled internally
                        if (b) Log("&qOK");

                        break;

                    case "createdefaultmod":
                        if (ModRunning() || DefaultModExists()) break;

                        Log("&tWith \"Default Mod\" it is meant a scriptless mod which contains the original game assets.");
                        Log("&tMake sure your game copy is 100% clean before proceeding.");
                        Log("&tType &a'yes' &tto create it, or anything else to abort.");

                        string s = Console.ReadLine() ?? "";
                        if (s == "yes")
                        {
                            LuaExecutor.CreateDefaultMod(); // internal logging
                        }
                        break;

                    case "clearscreen" or "cls":
                        Console.Clear();

                        Log(ascii_art);
                        Log("Type a command or \"help\" for a list of commands.");
                        break;

                    default:
                        // if command is empty, add "type help for a list of commands", otherwise just "Unknown command."
                        Console.WriteLine("Unknown command." + (input.Trim() == "" ? " Type 'help' for a list of commands." : ""));
                        break;
                }
            }
        }

        // Utils for commands
        private static Process? gameRunning = null;
        public static bool closeFromLaunch = false; // db

        public static void LaunchGame()
        {
            closeFromLaunch = true;

            CloseGame();

            gameRunning = Process.Start(gamePath);
        }

        public static void CloseGame()
        {
            if (gameRunning != null)
            {
                gameRunning.CloseMainWindow();
                if (!gameRunning.WaitForExit(500)) // timeout
                {
                    gameRunning.Kill(); // forced, async
                    gameRunning.WaitForExit(); // sync
                }
            }
        }

        public static void HookGame(bool speedUp)
        {
            if (speedUp) // creates default/speedup.lua if doesn't exist, and runs it sync
            {
                Log("&tPress TAB to disable speed up mod (inside the game)");
                if (!LuaExecutor.EnableSpeedUpMod())
                {
                    Log("&cSomething went wrong trying to enable speedup.lua...\nPerhaps mod 'default' is missing? Create it with &v'createdefaultmod' &ccommand.");
                }
            }

            closeFromLaunch = false;

            gameRunning!.EnableRaisingEvents = true;
            gameRunning.Exited += (_, _) => // async!
            {
                gameRunning.Dispose(); // cleanup
                gameRunning = null;

                if (!closeFromLaunch)
                    Log($"&qGame closure detected (type &a'launch' &qto relaunch)\n&c> ", newLine: false);
            };
        }

        private static void Exit()
        {
            Log("\n&0Press any key to exit...");
            Console.ReadKey(); // pause if separate cli to avoid instant exit
        }

        private static void WaitForKey(ConsoleKey key = ConsoleKey.Tab)
        {
            ConsoleKeyInfo info;

            do
                info = Console.ReadKey();
            while (info.Key != key);
        }

        // ignore
        private const string ascii_art =
            """

            &a██████╗ &s██████╗ &d██╗&a███████╗&s███╗   ███╗&d███████╗&a██╗     &s ██████╗ &d███╗   ██╗
            &a██╔══██╗&s██╔══██╗&d██║&a██╔════╝&s████╗ ████║&d██╔════╝&a██║     &s██╔═══██╗&d████╗  ██║
            &a██████╔╝&s██████╔╝&d██║&a███████╗&s██╔████╔██║&d█████╗  &a██║     &s██║   ██║&d██╔██╗ ██║
            &a██╔═══╝ &s██╔══██╗&d██║&a╚════██║&s██║╚██╔╝██║&d██╔══╝  &a██║     &s██║   ██║&d██║╚██╗██║
            &a██║     &s██║  ██║&d██║&a███████║&s██║ ╚═╝ ██║&d███████╗&a███████╗&s╚██████╔╝&d██║ ╚████║
            &a╚═╝     &s╚═╝  ╚═╝&d╚═╝&a╚══════╝&s╚═╝     ╚═╝&d╚══════╝&a╚══════╝&s ╚═════╝ &d╚═╝  ╚═══╝
            """ + $"\n&2{version}\n";

        // Repetitive boring operations done in CommandLoop()
        private static void PrintUsage_Lunch()
        {
            Log("&6launch &t--speedup --PID <id> &0- &aLaunches the game and hooks it.");
            Log("&d'--speedup' runs the game and starts a custom made 'speed up' mod.");
            Log("&d'Default Mod' is required for this mod to work, created with 'createdefaultmod'.");
            Log("&dThe script is created automatically and saved in mods/default/speedup.lua");

            Log("\n&d'--PID' is the game's process ID, found in the task manager.");
            Log("&dIf not provided, the program will detect the process automatically, it can be used in case of multiple instances.");
            Log("&vOnly use it if you know what you're doing, as it might attach to the wrong process and cause issues."); // TODO: add check if the process name is "PlantsVsZombies"
        }

        private static void PrintUsage_Lua()
        {
            Log("&tUsage: lua <inline lua code>");
            Log("&tExamples:");
            Log("  &dlua game.placePlant(2, 3, defs.plants.peashooter, false, 1) &a-- Places 1 peashooter at x=2, y=3, non-imitator");
            Log("  &dlua memory.writeInt(defs.plants.sunflower.cost, 0) &a-- Sets sunflower seed card cost to 0");
            Log("  &dlua print(game.sun()) &a-- Prints the current sun value");
        }

        private static void PrintUsage_Run()
        {
            Log("&tUsage: run <path to mod folder or quickmod script> [arguments]");
            Log("&tExamples:");
            Log("  &drun mymod &0- &aRuns the mod contained in the folder 'mymod', its main script assumed is 'mymod.lua' or 'main.lua'");
            Log("  &drun test.lua disable &0- &aRuns the quick mod specified, in quickmods/test.lua, with 'disable' as argument");
        }

        private static void PrintUsage_Profile()
        {

        }

        private static bool DefaultModExists()
        {
            if (LuaExecutor.DefaultModExists())
            {
                Log("&tDefault Mod already exists.");
                Log("&tIf you wish to overwrite it, delete it manually and try again.");
                return true;
            }
            return false;
        }

        private static bool NotHooked(bool gameHooked)
        {
            if (!gameHooked)
            {
                Log("&cTo execute this command you need to hook the game first.");
                Log("&cUse &v'detect' &cor &v'launch'");
                return true;
            }
            return false;
        }

        private static bool ModRunning()
        {
            if (LuaExecutor.AModIsRunning)
            {
                Log("&cThis command can't be executed because a mod is running.");
                return true;
            }
            return false;
        }
    }
}
