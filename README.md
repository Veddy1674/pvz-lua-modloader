# Prismelon ![Prismelon](https://img.shields.io/badge/v1.0-green.svg)
A Lua-based user-friendly framework along with tools designed specifically for modding the classic game **Plants vs. Zombies** through memory manipulation, which is significantly easier and more versatile than manually finding and editing addresses, creating Cheat Engine scripts, or editing decompiled/remake versions of the game.  
  
  
Traditionally, Plants vs. Zombies modding is tedious and error-prone:

❌ Manually editing the executable with HxD (requires backups, is slow and not advanced)  
❌ ...Which leads to restarting the game for every little change  
❌ Creating brittle Cheat Engine .CT scripts (difficult to create and debug)  
❌ Managing multiple game executables for different mods, merging mods is often difficult  
❌ Swapping asset folders manually for visual changes  
❌ Advanced C++ knowledge to implement advanced features to the game through the decomp  
***  

### ❓ Why it's a good alternative
__Prismelon__ overcomes most of the issues with clever alternatives, specifically, this project is divided in a three-part architecture:
1. ### Lua Framework <sub>(`mods/core/`)</sub>  
   A carefully designed framework that __*abstracts away low-level memory manipulation*__.  
   What would normally require manual ASM injection and manual address lookups becomes more straightforward:  
   `print(game.sun())`, `game.placePlant(0, 0, Plants.melon_pult.id)`, both syntaxes go through memory lookups and ASM injection on the second one, but it remains simple to understand even for newcomers to programming, allowing a bigger majority of people to try modding!

2. ### CLI for Developers <sub>(`Prismelon-Dev.exe`)</sub>  
   **Prismelon**, or, better, *Prismelon-Dev.exe*, is a standalone tool I've developed to be just as simple as the framework to use, it's utility is to easily test and debug your mods and scripts, with a simple CLI interface.  
   The game is *attached* and scripts can be easily run, e.g. through the command `run example.lua`; the command `lua` lets you create in-lined wrapped mods that are executed right away: `lua game.placePlant(4, 3, Plants.sunflower.id)`, which is a good way of testing if your mod is working correctly, "prints" are shown in the CLI in real time, allowing you to watch out variables... `lua print(memory.readInt(0x123456))`.

3. ### End-User Launcher <sub>(`Prismelon.exe`)</sub> (in development)
   A visual interface for anyone to manage and launch multiple mods simultaneously without any development knowledge required.
   If all you want is to try out mods and scripts, this is all you need (along with the framework).


## Pre-Requisites
- Your game version MUST be exactly `1.0.0.1051` (EN), as it's the most documented and known. Different versions means different memory addresses!
(You can look up the version by right clicking your PlantsVsZombies.exe -> Properties -> Details -> Product Version)
- Your game should be [patched](https://plantsvszombies.fandom.com/wiki/Modify_Plants_vs._Zombies#Before_Modifying) for mods that modify game assets to work.
A ready copy of the game can be found in the [modding docs](https://docs.google.com/document/d/1seslfFxBSvCFPRbXxeaSO-RJ6IrwfDBQ).

## Structure
`mods` is necessary, must be in the same path your game is.
The `mods/core` folder contains the framework:
- `mem.dll` is a C++ library which contains all what's needed for attaching to the process and allow memory manipulation
- `memory.lua` is a wrapper of *mem.dll*, contains well-documented functions and more features
- `definitions.lua`, `offsets.lua`... are huge files containing hexadecimal addresses of pretty much anything that can be modified in the game
- `utils.lua` is a simple utilities file that implements common features such as `math.clamp()`, `table.copy()`, `table.substract`, ...

## Tipologies of Mods
A mod can either be "simple/quick" and work by itself inside `mods/quickmods`, or, more commonly, be a separate folder inside `mods`, inside will be a lua script named after the folder (e.g: `mods/example/example.lua`) or universally `main.lua`.
A mod/quickmod can run **Synchronously**, **Asynchronously** or **in Background**:
- Synchronously means it will be executed inside prismelon-dev.exe itself, you won't be able to run commands until the script has ended (usually instantaneous)
- Asynchronously means it will be executed in another window through a batch file, you will be able to run commands in the main CLI
- In Background means it will be executed asynchronously and hidden; ~~if an error occurs, a window will pop up~~

## Getting Started
(to create a mod):
1. Create a folder inside "mods"
2. Create a .lua file inside the folder, make sure its name is the same as the mod (e.g: mods/test/test.lua) or main.lua
3. Write the script (look up the examples) and execute it through `Prismelon-Dev.exe` via "`run`", (e.g: `run test`)

(to create a quickmod, a mod that doesn't modify game assets)
2. Create a .lua file inside `mods/quickmods/`
3. Write the script (look up the examples) and execute it through `Prismelon-Dev.exe` via "`run`", (e.g: `run test.lua`), note the ".lua"

### Documentation: (WIP)
<details>
   <summary> Event Listeners </summary>

```lua
   memory.addListener(game._sun(), function(old, new)
      if old == nil then return end -- ignore first time
   
      print("Sun changed from " .. old .. " to " .. new)
   end)

   memory.onUpdate(function()
      memory.processListeners()
   end, 16)
```
</details>
<details>
   <summary> Using *memory.onUpdate()* </summary>

```lua
   -- sync loop
   memory.onUpdate(function()
      -- no worries about conflicts such as alt+tab, they're not detected!
      if memory.isKeyPressed("tab") then
         memory.stopUpdate() -- exits
         return
      end
   end, 16) -- every 16ms (roughly 57.6 fps)
```
</details>
<details>
   <summary> Spawning plants, zombies, ladders, rakes... </summary>

```lua
   local x, y = 2, 2 -- 0-indexed! it's the third column and row
   local isImitator = false -- self-explanatory
   local type = defs.plants.peashooter.id -- just a more comprehensible alternative to integers (in this case 0)

   local plant = game.placePlant(x, y, type, isImitator)
   printx(plant) -- prints the address of the plant in hexadecimal

   -- With zombies, ladders, rakes it's roughly the same syntax:
   game.placeZombie(x, y, defs.zombies.buckethead_zombie)

   -- TODO add rakes and ladders examples
```
</details>

<sub>This idea was inspired by the project "[PvZ Toolkit](https://github.com/lmintlcx/pvztoolkit/)" A big thank you to the developers!  Along with whoever made the game [fandom](https://plantsvszombies.fandom.com/wiki/Modify_Plants_vs._Zombies), which helped alot with understanding how this game is traditionally modded, and how I could make it easier and possible for everyone!</sub>
