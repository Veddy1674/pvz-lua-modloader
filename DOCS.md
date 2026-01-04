# Prismelon ![Prismelon](https://img.shields.io/badge/v1.0-green.svg) <img width="84" height="73" alt="rainbow_melonpult" src="https://github.com/user-attachments/assets/c57b8ed1-f3f3-4b31-9954-c21bdb152aa8" />   
This section is meant for developers and enthusiasts who are ready to create mods with my framework!
Beforehand, it is highly reccomended to have a Lua base knowledge, or atleast some general programming knowledge, the syntax was designed to be as simple and understandable as possible for everyone, but advanced logic still requires some "**problem-solving intuition**"
#
<a name="notes"></a>
### Notes
Usually, a mod always begins with:
```lua
local game = require("gameManager")
local memory = require("memory")
memory.start()
```
(Eventually `local hooker = require("hookManager")` or other utils)

And ends with: **`memory.stop()`** (Eventually `hooker.removeAllHooks()`)

### What each library does
- *`memory`* Is a wrapper of `mem.dll`, a C++ library who attaches to the game process via **`memory.start()`** and allows memory to be read and written in real time

- *`game`* Contains many useful functions to read and write memory, often with compact getter/setters such as **`game.sun(v)`**:  
  `game.sun(150)` ⠀⠀⠀⠀⠀⠀ **->**⠀memory.writeInt(*sun_address*, 150)⠀⠀**-** Sets the new value forcibly  
  `local sun = game.sun()` **->**⠀return memory.readInt(*sun_address*)⠀**-** Returns to you the current value
  
  Along with many other functions, just to mention some: `game.placePlant/Zombie/Rake/Ladder(x, y, ...)`, the returned value is often not an address but an "object" (or class), because the syntax is simpler:  
  `local plant = game.placePlant(1, 3, Plants.peashooter.id)` - Creates a new peashooter at x1 and y3 (starting from zero)
  
  And now "plant" is an object, it's address is "plant.address", and the object contains many useful functions:  
  `plant.visible(false)` - Makes the plant invisible  
  `print(plant.type())` - Prints "0", the peashooter's ID  
  `plant.clear()` - Self explanatory... "clear" sounds nicer than "kill"  

- *`defs`* Is imported by gameManager.lua, which creates global variables such as `Plants`, `Zombies`, `Callbacks`, `Scenes`, `Offsets`... to make it simple, I'll write down examples:
  
  `Plants.sunflower.id` - Returns "1", the ID of a sunflower, it's a constant for every plant  
  `Plants.sunflower.cost(v)` - Compact getter/setter described previously, sets or returns the value of a sunflower's cost, globally for every sunflower in every level  
  `Plants.sunflower.recharge(v)` - Pretty much the same but for the card recharge  
  `Plants.sunflower.launchRate(v)` - Pretty much the same but for how often the plant shoots/produces sun/coins  

#
### Documentation
Examples for pretty much everything you might need, not including the script [start and end](#notes):  

<details>
   <summary> Change a plant's cost, recharge and launch rate </summary>

```lua
-- Making cherry bomb faster to recharge but more expensive
Plants.cherry_bomb.cost(200) -- originally 150
Plants.cherry_bomb.recharge(750) -- originally 5000

Plants.peashooter.launchRate(75) -- originally 150, this makes it shoot x2 faster
print(Plants.sunflower.id, Plants.sunflower.cost(), Plants.sunflower.recharge(), Plants.sunflower.launchRate()) -- testing purposes, prints info about sunflower
```
</details>

<details>
   <summary> Creating "disable" argument </summary>

   It is a good practice for your mod, if it is simple, to have a "disable" as argument  
   In *Prismelon-Dev.exe*, a mod can be executed with custom arguments: `run example.lua disable`  

```lua
if Contains(arg, "disable") then
  -- Disable logic
  game.gameSpeed(1) -- x1 faster
else
  -- Enable logic
  game.gameSpeed(5) -- x5 faster
end
```
</details>

<details>
   <summary> Event Listeners with memory.addListener </summary>

```lua
-- _sun() returns the address at which the sun value is read, an hexadecimal number!
-- Internally, the value of the sun is read each "memory.processListeners()", and if it changes
-- then the function(old, new) below is called
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
   <summary> Using memory.onUpdate() for real-time memory manipulation </summary>

```lua
local f = 0

-- synchronized loop
memory.onUpdate(function()
  f = f + 1
  if f % 60 == 0 then
    f = 0
    print("One second has passed!")
  end

  if memory.isKeyPressed("tab") then -- inside the game, not the CLI!
    return memory.stopUpdate() -- exits loop
  end
end, 16) -- every 16ms (roughly 57.6 fps)
```
</details>  

<sub>This idea was inspired by the project "[PvZ Toolkit](https://github.com/lmintlcx/pvztoolkit/)" A big thank you to the developers!  Along with whoever made the game [fandom](https://plantsvszombies.fandom.com/wiki/Modify_Plants_vs._Zombies), which helped alot with understanding how this game is traditionally modded, and how I could make it easier and possible for everyone!</sub>
