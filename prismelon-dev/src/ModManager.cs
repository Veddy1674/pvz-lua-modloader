using System.Text.Json;
using static Prismelon.src.Utils;

namespace Prismelon.src
{
    // classes related to mod-making

    /// <summary>
    /// A "Profile" is a configuration of mods and quickmods.
    /// Used to easily turn on and off multiple mods at once.
    /// </summary>
    public class Profile(string id, string shortdesc, Mod? mod, Mod[] quickMods)
    {
        public string id = id;
        public string shortdesc = shortdesc;
        public Mod? mod = mod; // can be null
        public Mod[] quickMods = quickMods; // can be empty

        public Profile(string id, string shortdesc) : this(id, shortdesc, null, []) { }
    }

    public class Mod(string path, ushort priority = 1) // default 0 for quickmods, 1 for mods
    {
        public string path = path; // path to mod folder or a lua script inside quickmods/
        public ushort priority = priority; // execution from highest to lowest
    }

    public static class ModManager
    {
        public readonly static List<Profile> Profiles = []; // TODO use dictionary with id as key? for O(1) complexity, currently O(n)

        public static Profile? GetProfile(string id)
            => Profiles.FirstOrDefault(p => p.id == id);

        private static readonly JsonSerializerOptions jsonOptions = new()
        {
            WriteIndented = true,
            IncludeFields = true
        };

        public static bool LoadProfiles()
        {
            string path = LuaExecutor.ModsPath + "profiles.json";
            if (!File.Exists(path)) return false;

            try
            {
                string json = File.ReadAllText(path);

                var dict = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(json, jsonOptions);
                if (dict == null) return false;

                Profiles.Clear();
                foreach (var kvp in dict)
                {
                    var elem = kvp.Value;
                    Profiles.Add(new Profile(
                        id: kvp.Key, // primary key is id
                        shortdesc: elem.GetProperty("shortdesc").GetString() ?? "",
                        mod: elem.GetProperty("mod").Deserialize<Mod>(jsonOptions),
                        quickMods: elem.GetProperty("quickMods").Deserialize<Mod[]>(jsonOptions) ?? []
                    ));
                }
            }
            catch (Exception e)
            {
                Log($"&cAn unknown error has occurred whilst trying to read &v'profiles.json'&c: &v{e.Message}");
                return false;
            }

            return true;
        }

        public static bool SaveProfiles()
        {
            try
            {
                string path = LuaExecutor.ModsPath + "profiles.json";

                var dict = new Dictionary<string, object>();
                foreach (var profile in Profiles)
                {
                    dict[profile.id] = new
                    {
                        profile.shortdesc,
                        profile.mod,
                        profile.quickMods
                    };
                }

                string json = JsonSerializer.Serialize(dict, jsonOptions);

                File.WriteAllText(path, json);
            }
            catch (Exception e)
            {
                Log($"&cAn error has occurred whilst trying to save profiles.json: &v{e.Message}");
                return false;
            }

            return true;
        }
    }
}
