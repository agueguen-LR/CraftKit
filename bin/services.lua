local args = { ... }

local command = args[1]

if command == "list" then
	for name, def in pairs(craftd.list) do
		print(name, def.status)
	end
elseif command == "start" then
	local name = args[2]
	assert(name, "Missing service name")

	local ok, err = craftd.start(name)

	if not ok then
		printError(err)
	end
elseif command == "stop" then
	local name = args[2]
	assert(name, "Missing service name")

	local ok, err = craftd.stop(name)

	if not ok then
		printError(err)
	end
else
	print("Usage:")
	print("  services list")
	print("  services start <name>")
	print("  services stop <name>")
end
