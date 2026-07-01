--- Utility functions for CC: Tweaks
---@module "utils"
---@author agueguen-LR
---@license MIT

--- Returns the device's current coordinates as a string, or nil if it can't be located
---@return string|nil
function Locate()
	local x, y, z = gps.locate(30)
	if x == nil then
		return nil
	end
	return string.format("%d %d %d", x, y, z)
end

--- Get the first wireless modem connected to the computer
---@return peripheral
function Get_Wireless_Modem()
	return peripheral.find("modem", function(name, modem)
		return modem.isWireless()
	end)
end

--- Get the first wired modem connected to the computer
---@return peripheral
function Get_Wired_Modem()
	return peripheral.find("modem", function(name, modem)
		return not modem.isWireless()
	end)
end

--- Waits for a message on the given channel and returns it
---@param channel number
---@return string
function Wait_For_Message(channel)
	local _, _, found_channel, _, message

	repeat
		_, _, found_channel, _, message = os.pullEvent("modem_message")
	until found_channel == channel

	return message
end

--- Sends a message on the given channel, and prints it to the console
---@param info table contains the sender's name, wireless peripheral, target channel, and sender's own reply channel
---@param message string
---@param error boolean
function Send(info, message, error)
	if error then
		message = "ERROR: " .. message
	end
	info.wireless.transmit(info.server_channel, info.device_channel, message)
	print("Sent to server: " .. message)
end

--- Sends an error message every `interval` seconds, including the device's current position if it can be located
---@param info table contains the sender's name, wireless peripheral, target channel, and sender's own reply channel
---@param message string
---@param interval number
function Complain(info, message, interval)
	while true do
		local pos = locate()

		local msg = info.name .. ". " .. message
		if pos then
			msg = msg .. ". I'm at: " .. pos
		end

		send(info, msg, true)

		if not pos then
			locate() -- Retry to get position if it failed before
		end

		os.sleep(interval)
	end
end
