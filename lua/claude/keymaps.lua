-- keymaps.lua
local conversation = require("claude.conversation")

local M = {}

function M.setup(input_bufh, input_winnr, conversation_winnr)
	vim.api.nvim_buf_set_keymap(input_bufh, "i", "<C-s>", "", {
		noremap = true,
		callback = function()
			vim.ui.input({ prompt = "Enter conversation name: " }, function(conversation_name)
				if conversation_name then
					conversation.save(conversation_name)
				end
			end)
		end,
	})

	vim.api.nvim_buf_set_keymap(input_bufh, "i", "<C-c>", "", {
		noremap = true,
		callback = function()
			vim.api.nvim_win_close(input_winnr, true)
			vim.api.nvim_win_close(conversation_winnr, true)
		end,
	})
end

return M
