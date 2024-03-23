local M = {}

function M.setup()
	vim.cmd('command! -nargs=* Claude lua require("claude").claude_command(<f-args>)')
end

function M.claude_command(...)
	local args = table.concat({ ... }, " ")
	vim.fn.systemlist({ "python3", vim.fn.stdpath("data") .. "/lazy/claude.nvim/rplugin/python3/claude.py", args })
end

return M
