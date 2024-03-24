-- utils.lua
local M = {}

function M.get_current_file_content()
	-- Get the content of the current file
	local bufnr = vim.api.nvim_get_current_buf()
	local file_content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	return file_content
end

function M.get_project_files_content()
	-- Get the content of the files in the project root directory
	local project_root = vim.fn.getcwd()
	local project_files = {}

	for _, file in ipairs(vim.fn.glob(project_root .. "/*", 0, 1)) do
		if vim.fn.filereadable(file) == 1 then
			local file_content = table.concat(vim.fn.readfile(file), "\n")
			table.insert(project_files, file_content)
		end
	end
	return table.concat(project_files, "\n")
end

function M.display_loading_indicator(bufh)
	local loading_text = "Loading..."
	vim.api.nvim_buf_set_lines(bufh, -1, -1, false, { loading_text })
end

function M.clear_loading_indicator(bufh)
	vim.api.nvim_buf_set_lines(bufh, -1, -1, false, {})
end

return M
