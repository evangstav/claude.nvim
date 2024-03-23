local M = {}

local curl = require("plenary.curl")

function M.setup()
	-- Plugin setup code goes here
	-- You can define options, configurations, etc.
end

function M.run_query(query, callback)
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
	local data = {
		-- model = "claude-3-opus-20240229",
		model = "claude-3-haiku-20240307",
		max_tokens = 1024,
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
				local decoded_response = vim.json.decode(response.body)
				local result = ""

				if decoded_response.content and type(decoded_response.content) == "table" then
					result = decoded_response.content[1].text
				end

				callback(result)
			end
		end),
	})
end

vim.api.nvim_create_user_command("ClaudeQuery", function(opts)
	local query = opts.args
	M.run_query(query, function(result)
		vim.api.nvim_out_write(result .. "\n")
	end)
end, { nargs = 1 })

return M
