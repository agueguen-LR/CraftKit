---@module "craftd"
---@author agueguen-LR
---@license MIT

--- CraftKit Service Daemon (craftd)
-- Manages lifecycle of CraftKit services.

local craftkit_path = settings.get("craftkit.path")
local fsutil = require(craftkit_path .. "lib.fsutil")

local config_path = craftkit_path .. "/etc/services.lua"

fsutil.ensureDir(craftkit_path .. "/etc")
fsutil.ensureFile(config_path, "return {}\n")

--- Loaded service configuration table.
-- This file is expected to return a Lua table describing all services
-- managed by craftd.
local services = dofile(config_path)
assert(type(services) == "table", "services.lua must return a table")

--- Table of currently running services.
local running = {}

--- Starts a service if it is not already running.
--
-- A service is executed in an isolated environment and runs inside a coroutine.
-- Service programs must be in `<craftkit_path>/services/`.
-- The environment inherits from the global environment (_G).
--
---@param name string The service name (key in services table)
---@return boolean success True if service started successfully
---@return string|nil err Error message if startup failed
local function startService(name)
	if running[name] then
		return false, "already running"
	end

	local service_path = fs.combine(craftkit_path, "services", name .. ".lua")
	if not fs.exists(service_path) then
		return false, "service does not exist"
	end

	local ok, err = pcall(function()
		--- Service execution environment.
		-- Inherits from global environment.
		-- Can be sandboxed later by modifying __index.
		local env = {}

		setmetatable(env, { __index = _G })

		--- Compiled service function.
		-- Loaded from file with isolated environment.
		local fn = loadfile(service_path, "t", env)

		if not fn then
			error("invalid service: " .. service_path)
		end

		--- Coroutine representing the running service.
		local co = coroutine.create(fn)

		local ok, err = coroutine.resume(co)

		if not ok then
			printError(("Service '%s' crashed: %s"):format(name, err))
		end

		--- Registers running service instance.
		running[name] = {
			coroutine = co,
			def = service_path,
			status = "running",
		}
	end)

	if not ok then
		return false, err
	end

	return true
end

--- Stops a running service.
---@param name string The service name (key in services table)
---@return boolean success True if service stopped successfully
local function stopService(name)
	local service = running[name]
	if not service then
		return false, "not running"
	end

	running[name] = nil
	return true
end

local function disableService(name)
	local service = services[name]
	if not service then
		return false, "service does not exist"
	end

	service.enabled = false
	return true
end

local function enableService(name)
	local service = services[name]
	if not service then
		return false, "service does not exist"
	end

	service.enabled = true
	startService(name)
	return true
end

local function listServices()
	local list = {}
	for name, def in pairs(services) do
		list[name] = {
			enabled = def.enabled,
			status = running[name] and "running" or "stopped",
		}
	end
	return list
end

--- Craftkit's serviced equivalent craftd API for managing services.
_G.craftd = {
	start = startService,
	stop = stopService,
	enable = enableService,
	disable = disableService,
	list = services,
}

--- Initializes and starts all enabled services from configuration.
for name, def in pairs(services) do
	if def.enabled then
		startService(name, def)
	end
end

--- Runs the CraftKit daemon and user shell in parallel.
--
-- This setup creates a persistent system session:
-- - `craftd_main_loop` runs as the background service daemon
-- - the shell is continuously restarted if it exits
-- - neither loop can terminate the other (`parallel.waitForAll`)
--
-- This effectively simulates a simple init system where the daemon
-- and user session coexist indefinitely.
--

--- CraftKit main daemon loop.
-- Processes system events via `os.pullEventRaw` (including `terminate`).
-- Intended to evolve into service scheduling and IPC handling.
local function craftd_main_loop()
	while true do
		local event = { os.pullEventRaw() }

		for _, svc in pairs(running) do
			if coroutine.status(svc.coroutine) ~= "dead" then
				coroutine.resume(svc.coroutine, table.unpack(event))
			end
		end
	end
end

-- Run daemon and shell concurrently.
parallel.waitForAny(function()
	craftd_main_loop()
end, function()
	while true do
		shell.run("/rom/programs/shell.lua")
	end
end)
