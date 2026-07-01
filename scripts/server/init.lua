require("lib.utils")

local function wait_for_wireless_modem()
	while true do
		local modem = Get_Wireless_Modem()

		if modem then
			return modem
		end

		term.clear()
		term.setCursorPos(1, 1)

		print("No wireless modem detected.")
		print("Please connect a wireless modem.")
		print()
		print("Waiting...")

		os.pullEvent("peripheral")
	end
end

local modem = wait_for_wireless_modem()

term.clear()
term.setCursorPos(1, 1)
print("Wireless modem detected!")
