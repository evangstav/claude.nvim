-- floating_windows.lua
local M = {}

function M.setup()
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.7)
	-- local borderchars = { "│", "─", "─", "┌", "│", "┐", "┘", "└" }
	local borderchars = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" }
	local conversation_bufh = vim.api.nvim_create_buf(false, true)
	local conversation_winnr = vim.api.nvim_open_win(conversation_bufh, true, {
		relative = "editor",
		width = width,
		height = 1 + height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2) - 2,
		style = "minimal",
		border = borderchars,
	})

	local input_bufh = vim.api.nvim_create_buf(false, true)
	local input_winnr = vim.api.nvim_open_win(input_bufh, true, {
		relative = "editor",
		width = width,
		height = 1,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2) + height,
		style = "minimal",
		border = borderchars,
	})

	return conversation_bufh, conversation_winnr, input_bufh, input_winnr
end

return M
