-- utils.lua
local M = {}

function M.get_current_file_content()
	-- Get the content of the current file
	local bufnr = vim.api.nvim_get_current_buf()
	local file_content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	return file_content
end

function M.get_project_files_content()
	local project_root = vim.fn.getcwd()
	print(project_root)
	local project_files = {}

	local file_extensions = { ".lua", ".py", ".js", ".ts", ".cpp", ".c", ".h", ".txt", ".md" }

	for _, file_extension in ipairs(file_extensions) do
		local files = vim.fn.glob(project_root .. "/**/*" .. file_extension, false, true)
		for _, file in ipairs(files) do
			if vim.fn.filereadable(file) == 1 then
				local file_content = table.concat(vim.fn.readfile(file), "\n")
				table.insert(project_files, file_content)
			end
		end
	end

	return table.concat(project_files, "\n")
end

return M
