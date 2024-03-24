-- api.lua
local curl = require("plenary.curl")
local conversation = require("claude.conversation")

local M = {}

function M.make_request(config, query, callback, additional_context)
	-- Prepare the API request and make the request using curl
	local api_key = vim.env.ANTHROPIC_API_KEY
	if not api_key then
		vim.api.nvim_err_writeln("ANTHROPIC_API_KEY environment variable is not set.")
		return
	end

	table.insert(conversation.history, { role = "user", content = query .. "\n" })

	local system_prompt_with_context = config.system_prompt .. "Additional context: \n\n" .. additional_context
	local url = "https://api.anthropic.com/v1/messages"
	local headers = {
		["x-api-key"] = api_key,
		["anthropic-version"] = "2023-06-01",
		["content-type"] = "application/json",
	}

	local data = {
		model = config.model,
		max_tokens = config.max_tokens,
		system = system_prompt_with_context,
		messages = conversation.history,
	}
	local json_data = vim.json.encode(data)

	curl.post(url, {
		body = json_data,
		headers = headers,
		callback = vim.schedule_wrap(function(response)
			callback(response)
		end),
	})
end

function M.handle_response(bufh, response_body)
	-- Handle the API response and update the conversation history
	local decoded_response = vim.json.decode(response_body)
	local assistant_response = ""

	if decoded_response.content and type(decoded_response.content) == "table" then
		assistant_response = decoded_response.content[1].text .. "\n"
	end

	table.insert(conversation.history, { role = "assistant", content = assistant_response })
	conversation.display(bufh)
end

return M
