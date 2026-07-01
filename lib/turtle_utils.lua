--- abbreviations for item names for select_item()
_G.digital_miner = "mekanism:digital_miner"
_G.chunk_loader = "mekanism:dimensional_stabilizer"
_G.tesseract = "mekanism:quantum_entangloporter"
_G.lava = "minecraft:lava_bucket"

--- Moves the turtle forward n times, complaining to the server if it can't
---@param n number
---@param turtle_info table contains the turtle's name, wireless peripheral, server channel, and turtle's own reply channel
---@param move_func function the turtle's move function to call (turtle.forward, turtle.up, or turtle.down)
function move(n, turtle_info, move_func)
	for _ = 1, n, 1 do
		::retry_move::
		local ok, err = move_func()
		if not ok then
			if err == "Out of fuel" then
				refuel(turtle_info)
				goto retry_move
			else
				complain(turtle_info, "Failed to move forward: " .. err, 5)
			end
		end
	end
end

--- Safely places an item, complaining to the server if it can't.
---@param item_name string
---@param turtle_info table contains the turtle's name, wireless peripheral, server channel, and reply channel
---@param place_func function -- turtle.place, turtle.placeUp, or turtle.placeDown
function place(item_name, turtle_info, place_func)
	select_item(item_name, turtle_info)

	while true do
		local ok, err = place_func()
		if ok then
			return
		end

		complain(turtle_info, "Failed to place " .. item_name .. ": " .. err, 5)
	end
end

--- Selects the turtle's first slot containing the given item name.
---@param item_name string
---@param turtle_info table contains the turtle's name, wireless peripheral, server channel, and reply channel
function select_item(item_name, turtle_info)
	for i = 1, 16 do
		local item_info = turtle.getItemDetail(i)
		if item_info and item_info.name == item_name then
			turtle.select(i)
			return
		end
	end

	complain(turtle_info, "Missing required item: " .. item_name, 5)
end

--- Safely digs a block, complaining to the server if it can't.
---@param turtle_info table contains the turtle's name, wireless peripheral, server channel, and reply channel
---@param dig_func function -- turtle.dig, turtle.digUp, or turtle.digDown
function dig(turtle_info, dig_func)
	while true do
		local ok, err = dig_func()

		if ok then
			return
		end

		complain(turtle_info, "Failed to dig: " .. err, 5)
	end
end

--- Refuels the turtle using a lava bucket if it has fuel, or does nothing if the turtle has unlimited fuel
---@param turtle_info table contains the turtle's name, wireless peripheral, server channel, and turtle's own reply channel
function refuel(turtle_info)
	local level = turtle.getFuelLevel()
	if level == "unlimited" then
		return
	end

	select_item(lava, turtle_info)
	local ok, err = turtle.refuel()
	if not ok then
		complain(turtle_info, "Failed to refuel: " .. err, 5)
	else
		send(turtle_info, turtle_info.name .. " has refueled with a lava bucket.", false)
	end
end
