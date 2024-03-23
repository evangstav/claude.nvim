local M = {}

function M.setup()
	vim.cmd('command! -nargs=* Claude lua require("claude").claude_command(<f-args>)')
end

function M.claude_command(...)
	local args = table.concat({ ... }, " ")
	vim.fn.systemlist({ "python", vim.fn.expand("~/.config/nvim/plugins/claude.nvim/lua/claude/claude.py"), args })
end

return M
