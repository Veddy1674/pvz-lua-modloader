using System.Diagnostics;
using System.Text;

namespace Prismelon.src
{
    public static class Utils
    {
        private static readonly Dictionary<char, ConsoleColor> logColorMap = new()
        {
            // inspired by Minecraft's color codes
            ['0'] = ConsoleColor.Gray, // default
            ['1'] = ConsoleColor.DarkGray,
            ['2'] = ConsoleColor.White,
            ['3'] = ConsoleColor.Black, // invisible on black background!

            // greens
            ['q'] = ConsoleColor.Green,
            ['w'] = ConsoleColor.DarkGreen,

            // cyans/blues
            ['a'] = ConsoleColor.Cyan,
            ['s'] = ConsoleColor.DarkCyan,
            ['d'] = ConsoleColor.Blue,
            ['f'] = ConsoleColor.DarkBlue,

            // reds/magentas
            ['z'] = ConsoleColor.Magenta,
            ['x'] = ConsoleColor.DarkMagenta,
            ['c'] = ConsoleColor.Red,
            ['v'] = ConsoleColor.DarkRed,

            // yellows
            ['t'] = ConsoleColor.Yellow,
            ['y'] = ConsoleColor.DarkYellow,

            // made for QWERTY keyboards, as "qwerty", "asdfgh", "zxcvbn" are all near eachother
            // and the colors go from light to dark, all whats need to be remembered is q = greens, a = cyans..
            // and then it's just about using the key nearby to get a darker tone...
        };

        public static void Log(string text, bool newLine = true)
        {
            // no check for "if text doesn't contain & then skip" because regardless, .Contains() cycles through the characters anyway
            for (int i = 0; i < text.Length; i++)
            {
                if (text[i] == '&' && i + 1 < text.Length)
                {
                    char code = text[i + 1];
                    if (logColorMap.ContainsKey(code))
                    {
                        Console.ForegroundColor = logColorMap[code];
                        i++;
                        continue;
                    }
                }
                Console.Write(text[i]);
            }
            if (newLine) Console.WriteLine();
            Console.ResetColor();
        }

        // to easily work with arguments
        public static string GetOrDefault(this string[] args, int index, string defaultValue = "") =>
            index >= 0 && index < args.Length ? args[index] : defaultValue; // doesn't throw IndexOutOfRangeException

        public static bool AnyEmpty(params string[] strings)
            => strings.Any(string.IsNullOrEmpty);

        public static int? ParseOrNull(this string s)
            => int.TryParse(s, out int n) ? n : null;

        // IO management
        public static void CopyFolder(string source, string destination) // throws Exception
        {
            // tbf the 4 folders "reanim", "images", "sounds", "particles" do not contain subfolders (unlike goty and other versions)
            var rootName = Path.GetFileName(source.TrimEnd(Path.DirectorySeparatorChar));
            var finalDest = Path.Combine(destination, rootName);

            foreach (var file in Directory.GetFiles(source, "*", SearchOption.AllDirectories)) // recursive
            {
                var relative = Path.GetRelativePath(source, file);
                var destFile = Path.Combine(finalDest, relative);

                Directory.CreateDirectory(Path.GetDirectoryName(destFile)!);

                if (!FilesEqual(file, destFile))
                    File.Copy(file, destFile, true);
            }
        }

        public static void CopyFolders(string destination, params string?[] sources)
        {
            if (sources == null) return;

            foreach (string? source in sources)
                if (!string.IsNullOrEmpty(source))
                    CopyFolder(source, destination);
        }

        // cheaper alternative..? (i forgot to what)
        private static bool FilesEqual(string source, string destination)
        {
            if (!File.Exists(destination)) return false; // important

            var a = new FileInfo(source);
            var b = new FileInfo(destination);

            return a.Length == b.Length && a.LastWriteTimeUtc == b.LastWriteTimeUtc;
        }

        public static bool CreateDirectory(string path) // returns false if exception
        {
            // if exists check seems to be useless
            try { Directory.CreateDirectory(path); } catch { return false; }
            return true;
        }

        public static string? GetFileVersion(string filePath)
        {
            if (!File.Exists(filePath)) return null;
            return FileVersionInfo.GetVersionInfo(filePath).FileVersion;
        }

        // the same as .Contains but out index
        public static bool Contains(this string[] arr, string value, out int index)
        {
            index = Array.IndexOf(arr, value); // -1 when invalid
            return index >= 0;
        }

        // usual console input reader, escaped is true if ESC was pressed
        public static string ReadLineUntilValid(string prompt, string errorMessage, out bool escaped, string defaultValue = "", Func<string, bool>? validator = null)
        {
            escaped = false;

            while (true)
            {
                Console.Write(prompt);

                var input = new StringBuilder(defaultValue);
                Console.Write(defaultValue);

                while (true)
                {
                    var key = Console.ReadKey(intercept: true);

                    if (key.Key == ConsoleKey.Escape)
                    {
                        escaped = true;
                        return "";
                    }

                    if (key.Key == ConsoleKey.Enter)
                        break;

                    if (key.Key == ConsoleKey.Backspace && input.Length > 0)
                    {
                        input.Length--;
                        Console.Write("\b \b");
                    }
                    else if (!char.IsControl(key.KeyChar))
                    {
                        input.Append(key.KeyChar);
                        Console.Write(key.KeyChar);
                    }
                }
                Console.WriteLine();

                string result = input.ToString();
                if (validator == null || validator(result))
                    return result;

                Console.WriteLine(errorMessage);
            }
        }

        // e.g: "Hello World" -> "hello_world", doesn't consider special characters!
        public static string NormalizeToID(this string input)
        {
            if (string.IsNullOrEmpty(input)) return "";

            return input.ToLowerInvariant()
                        .Replace(' ', '_')
                        .Trim('_');
        }
    }
}
