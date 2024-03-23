local M = {}

local curl = require("plenary.curl")
local conversation_history = {}

function M.setup()
	-- Plugin setup code goes here
	-- You can define options, configurations, etc.
end

local function setup_floating_window()
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" }

	local bufh = vim.api.nvim_create_buf(false, true)

	local winnr = vim.api.nvim_open_win(bufh, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = borderchars,
	})

	vim.api.nvim_buf_set_option(bufh, "buftype", "nofile")
	vim.api.nvim_buf_set_option(bufh, "filetype", "claude")
	vim.api.nvim_buf_set_option(bufh, "bufhidden", "wipe")

	return bufh, winnr
end

local function display_conversation(bufh)
	local conversation_text = ""

	for _, entry in ipairs(conversation_history) do
		conversation_text = conversation_text .. entry.role .. ": " .. entry.content .. "\n\n"
	end

	vim.api.nvim_buf_set_lines(bufh, 0, -1, false, vim.split(conversation_text, "\n"))
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
	local bufh, winnr = setup_floating_window()
	display_conversation(bufh)

	local prompt_bufh = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(prompt_bufh, "buftype", "prompt")
	vim.fn.prompt_setprompt(prompt_bufh, "Query: ")

	local prompt_winnr = vim.api.nvim_open_win(prompt_bufh, true, {
		relative = "editor",
		width = math.floor(vim.o.columns * 0.8),
		height = 1,
		col = (vim.o.columns - vim.o.columns * 0.8) / 2,
		row = (vim.o.lines - vim.o.lines * 0.8) / 2 + vim.o.lines * 0.8,
		style = "minimal",
	})

	vim.fn.prompt_setcallback(prompt_bufh, function(query)
		table.insert(conversation_history, { role = "user", content = query })
		display_conversation(bufh)
		run_query(bufh, query)
	end)

	vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("ClaudeConversation", function()
	conversation_history = {}
	M.open_conversation_window()
end, {})

return M
