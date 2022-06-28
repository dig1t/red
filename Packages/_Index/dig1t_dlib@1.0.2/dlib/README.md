# dLib
Modules and Libraries for development in Roblox. _Feel free to read through the modules while documentation is written!_

#### Setup
```lua
-- Require dLib from your installation location
-- For this example we'll use ReplicatedStorage as dLib's parent location
local dLib = require(game:GetService('ReplicatedStorage'):WaitForChild('dLib'))
```

#### Usage
```lua
local Palette = dLib.import('Palette')

print(Palette('blue', 500))
```