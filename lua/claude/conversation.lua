-- conversation.lua
local M = {}

M.history = {}
M.conversation_dir = vim.fn.stdpath("data") .. "/claude_conversations"

function M.reset_history()
	M.history = {}
end

function M.add_to_history(role, content)
	table.insert(M.history, { role = role, content = content })
end

function M.display(bufh)
	-- Display conversation history in the buffer
	local conversation_text = ""
	for _, entry in ipairs(M.history) do
		local formatted_entry = string.format("**%s**: %s", entry.role, entry.content)
		conversation_text = conversation_text .. formatted_entry .. "\n"
	end
	vim.api.nvim_buf_set_lines(bufh, 0, -1, false, vim.split(conversation_text, "\n"))
	-- Apply syntax highlighting
	vim.api.nvim_buf_set_option(bufh, "filetype", "markdown")
end

function M.load(conversation_name)
	-- Save conversation history to a file
	local file_path = M.conversation_dir .. "/" .. conversation_name .. ".txt"
	local file = io.open(file_path, "r")
	if file then
		M.history = {}
		for line in file:lines() do
			local role, content = line:match("^(%w+):%s*(.*)$")
			if role and content then
				table.insert(M.history, { role = role, content = content })
			end
		end
		file:close()
		vim.notify("Conversation loaded: " .. conversation_name, vim.log.levels.INFO)
	else
		vim.notify("Conversation not found: " .. conversation_name, vim.log.levels.WARN)
	end
end

function M.save(conversation_name)
	-- Load conversation history from a file
	local file_path = M.conversation_dir .. "/" .. conversation_name .. ".txt"
	local file = io.open(file_path, "w")
	if file then
		for _, entry in ipairs(M.history) do
			file:write(string.format("%s: %s\n", entry.role, entry.content))
		end
		file:close()
		vim.notify("Conversation saved: " .. conversation_name, vim.log.levels.INFO)
	else
		vim.notify("Failed to save conversation: " .. conversation_name, vim.log.levels.ERROR)
	end
end

function M.delete(conversation_name)
	local file_path = M.conversation_dir .. "/" .. conversation_name .. ".txt"
	local success, err = os.remove(file_path)
	if success then
		vim.notify("Conversation deleted: " .. conversation_name, vim.log.levels.INFO)
	else
		vim.notify("Failed to delete conversation: " .. conversation_name, vim.log.levels.ERROR)
	end
end

return M
