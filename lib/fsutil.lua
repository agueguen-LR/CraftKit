local M = {}

--- Ensure that a directory exists at the given path. If it does not exist, it will be created. If a file exists at the path, an error will be thrown.
---@param path ccTweaked.fs.path The path to the directory.
function M.ensureDir(path)
	if not fs.exists(path) then
		fs.makeDir(path)
	elseif not fs.isDir(path) then
		error(("'%s' exists but is not a directory"):format(path))
	end
end

--- Ensure that a file exists at the given path. If it does not exist, it will be created with the given contents. If a directory exists at the path, an error will be thrown.
---@param path ccTweaked.fs.path The path to the file.
---@param contents string Optional contents to write to the file if it is created.
function M.ensureFile(path, contents)
	if fs.exists(path) then
		return
	end

	local file = fs.open(path, "w")
	if not file then
		error(("Failed to create '%s'"):format(path))
	end

	file.write(contents or "")
	file.close()
end

return M
