local M = {}

function M.claude_command(...)
	local args = table.concat({ ... }, " ")
	vim.fn.systemlist({ "python3", vim.fn.expand("~/.config/nvim/plugins/claude.nvim/claude.py"), args })
end

return M
