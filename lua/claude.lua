local M = {}

function M.setup()
	-- Plugin setup code goes here
	-- You can define options, configurations, etc.
end

function M.run_query(query)
	local api_key = vim.env.ANTHROPIC_API_KEY
	if not api_key then
		vim.api.nvim_err_writeln("ANTHROPIC_API_KEY environment variable is not set.")
		return
	end

	local url = "https://api.anthropic.com/v1/messages"
	local headers = {
		"x-api-key: " .. api_key,
		"anthropic-version: 2023-06-01",
		"content-type: application/json",
	}
	local data = {
		model = "claude-3-opus-20240229",
		max_tokens = 1024,
		messages = {
			{
				role = "user",
				content = query,
			},
		},
	}

	local cmd = {
		"curl",
		url,
		"--silent",
		"--header",
		table.concat(headers, " --header "),
		"--data",
		vim.fn.json_encode(data),
	}

	local output = vim.fn.system(table.concat(cmd, " "))
	local response = vim.fn.json_decode(output)

	if response.error then
		vim.api.nvim_err_writeln("Error: " .. response.error.message)
	else
		local result = response.messages[1].content
		vim.api.nvim_out_write(result .. "\n")
	end
end

vim.api.nvim_create_user_command("Claude", function(opts)
	local query = opts.args
	M.run_query(query)
end, { nargs = 1 })

return M
