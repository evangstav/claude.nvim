local M = {}

local curl = require("plenary.curl")

local conversation_history = {}

function M.setup()
	-- Plugin setup code goes here
	-- You can define options, configurations, etc.
	M.config = vim.tbl_extend("force", {
		api_key = vim.env.ANTHROPIC_API_KEY,
		model = "claude-3-opus-20240229",
		max_tokens = 1024,
		-- Other configuration options
	}, opts or {})
end

local function setup_floating_windows()
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

	vim.api.nvim_buf_set_option(conversation_bufh, "buftype", "nofile")
	vim.api.nvim_buf_set_option(conversation_bufh, "filetype", "claude")
	vim.api.nvim_buf_set_option(conversation_bufh, "bufhidden", "wipe")

	vim.api.nvim_buf_set_option(input_bufh, "buftype", "nofile")
	vim.api.nvim_buf_set_option(input_bufh, "filetype", "claude")
	vim.api.nvim_buf_set_option(input_bufh, "bufhidden", "wipe")

	return conversation_bufh, conversation_winnr, input_bufh, input_winnr
end

local function display_conversation(bufh)
	local conversation_text = ""
	for _, entry in ipairs(conversation_history) do
		local role = entry.role == "user" and "ClaudeUserRole" or "ClaudeAssistantRole"
		local formatted_entry = string.format("%s: %s", entry.role, entry.content)
		conversation_text = conversation_text .. formatted_entry .. "\n"
	end
	vim.api.nvim_buf_set_lines(bufh, 0, -1, false, vim.split(conversation_text, "\n"))
	-- Apply syntax highlighting
	vim.api.nvim_buf_add_highlight(bufh, -1, "ClaudeUserRole", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(bufh, -1, "ClaudeAssistantRole", 1, 0, -1)
end

local function get_conversation_history()
	local history = ""

	for _, entry in ipairs(conversation_history) do
		history = history .. entry.role .. ": " .. entry.content .. "\n"
	end

	return history
end

local function handle_response(bufh, response_body)
	local decoded_response = vim.json.decode(response_body)
	local assistant_response = ""

	if decoded_response.content and type(decoded_response.content) == "table" then
		assistant_response = decoded_response.content[1].text
	end

	table.insert(conversation_history, { role = "assistant", content = assistant_response })
	display_conversation(bufh)
end

local function run_query(bufh, query)
	local api_key = vim.env.ANTHROPIC_API_KEY
	if not api_key then
		vim.api.nvim_err_writeln("ANTHROPIC_API_KEY environment variable is not set.")
		return
	end

	local url = "https://api.anthropic.com/v1/messages"
	local headers = {
		["x-api-key"] = api_key,
		["anthropic-version"] = "2023-06-01",
		["content-type"] = "application/json",
	}

	local conversation_history_text = get_conversation_history()
	local data = {
		model = "claude-3-opus-20240229",
		max_tokens = 1024,
		system = conversation_history_text,
		messages = {
			{
				role = "user",
				content = query,
			},
		},
	}

	local json_data = vim.json.encode(data)

	curl.post(url, {
		body = json_data,
		headers = headers,
		callback = vim.schedule_wrap(function(response)
			if response.status ~= 200 then
				vim.api.nvim_err_writeln("Error: " .. response.body)
			else
				handle_response(bufh, response.body)
			end
		end),
	})
end

function M.open_conversation_window()
	local conversation_bufh, conversation_winnr, input_bufh, input_winnr = setup_floating_windows()
	display_conversation(conversation_bufh)

	vim.api.nvim_buf_set_keymap(input_bufh, "i", "<CR>", "", {
		noremap = true,
		callback = function()
			local query = vim.api.nvim_buf_get_lines(input_bufh, 0, -1, false)[1]
			vim.api.nvim_buf_set_lines(input_bufh, 0, -1, false, { "" })
			table.insert(conversation_history, { role = "user", content = query })
			display_conversation(conversation_bufh)
			run_query(conversation_bufh, query)
		end,
	})

	vim.api.nvim_buf_set_keymap(input_bufh, "i", "<Esc>", "", {
		noremap = true,
		callback = function()
			vim.api.nvim_win_close(input_winnr, true)
			vim.api.nvim_win_close(conversation_winnr, true)
		end,
	})

	vim.api.nvim_set_current_win(input_winnr)
	vim.api.nvim_command("startinsert")
end

vim.api.nvim_create_user_command("ClaudeConversation", function()
	conversation_history = {}
	M.open_conversation_window()
end, {})

-- Custom syntax highlighting
vim.cmd([[
    syntax match ClaudeUserRole /^user:/
    syntax match ClaudeAssistantRole /^assistant:/

    highlight link ClaudeUserRole Keyword
    highlight link ClaudeAssistantRole Identifier
]])

-- Enable word wrapping in the conversation window
vim.cmd([[
    augroup ClaudeConversation
        autocmd!
        autocmd FileType claude setlocal wrap
    augroup END
]])

return M
