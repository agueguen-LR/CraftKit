---@module "startup"
---@author "agueguen-LR"
---@license MIT
---
--- Startup script for CraftKit, following the style of CC: Tweaked's rom/startup.lua.

local completion = require("cc.shell.completion")

local craftkit_dir = settings.get("craftkit.path")

shell.setPath(shell.path() .. ":/" .. fs.combine(craftkit_dir, "bin"))

shell.run(fs.combine(craftkit_dir, "sbin/craftd.lua"))
