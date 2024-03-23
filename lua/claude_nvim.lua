local M = {}

function M.setup()
	vim.cmd([[
    command! Hello lua require('claude.nvim').hello()
  ]])
end

function M.hello()
	vim.fn["hello#hello"]()
end

return M
