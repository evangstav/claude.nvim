local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local conversation = require("claude.conversation")
local api = require("claude.api")
local utils = require("claude.utils")
local keymaps = require("claude.keymaps")
local floating_windows = require("claude.floating_windows")
local config = require("claude.config")

function M.setup(opts)
	config.setup(opts)
end

function M.browse_conversations()
	local conversations = {}
	for file in vim.fs.dir(config.conversation_dir) do
		if file:sub(-4) == ".txt" then
			table.insert(conversations, file:sub(1, -5))
		end
	end
	pickers
		.new({}, {
			prompt_title = "Select Conversation",
			finder = finders.new_table({
				results = conversations,
			}),
			sorter = sorters.get_generic_fuzzy_sorter(),
			attach_mappings = function(prompt_bufnr, map)
				map("i", "<CR>", function()
					local selection = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)
					conversation.load(selection[1])
					M.open_conversation_window("")
				end)
				map("i", "<C-d>", function()
					local selection = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)
					conversation.delete(selection[1])
					M.browse_conversations()
				end)
				return true
			end,
		})
		:find()
end

function M.open_conversation_window(additional_context)
	local conversation_bufh, conversation_winnr, input_bufh, input_winnr = floating_windows.setup()
	keymaps.setup(input_bufh, input_winnr, conversation_winnr)
	conversation.display(conversation_bufh)

	vim.api.nvim_buf_set_keymap(input_bufh, "i", "<CR>", "", {
		noremap = true,
		callback = function()
			local query = vim.api.nvim_buf_get_lines(input_bufh, 0, -1, false)[1]
			vim.api.nvim_buf_set_lines(input_bufh, 0, -1, false, { "" })
			conversation.display(conversation_bufh)
			api.run_query(conversation_bufh, query, additional_context)
		end,
	})
	vim.api.nvim_set_current_win(input_winnr)
	vim.api.nvim_command("startinsert")
end

vim.api.nvim_create_user_command("ClaudeConversation", function()
	conversation.reset_history()
	M.open_conversation_window("")
end, {})

vim.api.nvim_create_user_command("ClaudeBrowseConversations", function()
	M.browse_conversations()
end, {})

vim.api.nvim_create_user_command("ClaudeConversationWithCurrentFile", function()
	local current_file_content = utils.get_current_file_content()
	conversation.reset_history()
	M.open_conversation_window(current_file_content)
end, {})

vim.api.nvim_create_user_command("ClaudeConversationWithProjectFiles", function()
	local project_files_content = utils.get_project_files_content()
	conversation.reset_history()
	M.open_conversation_window(project_files_content)
end, {})

return M
