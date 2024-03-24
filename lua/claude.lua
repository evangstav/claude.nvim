local M = {}

local curl = require("plenary.curl")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local conversation_dir = vim.fn.stdpath("data") .. "/claude_conversations"
local conversation_history = {}

function M.setup()
	-- Plugin setup code goes here
	-- You can define options, configurations, etc.
	M.config = vim.tbl_extend("force", {
		api_key = vim.env.ANTHROPIC_API_KEY,
		model = "claude-3-haiku-20240307",
		max_tokens = 1024,
		system_prompt = "You are an AI assistant with expertise in data science, software development, and project planning.\
Your role is to help users with questions related to data science, planning, designing, and\
conceptualizing ideas in these fields.\
When a user provides a topic and asks a question, follow these steps to provide a helpful response:\
1. Analyze the question to understand the context and the specific assistance the\
user is seeking.\
2. In <thought> tags, break down the problem and outline the key considerations, best practices, and\
potential solutions relevant to the topic and question. Consider factors such as:\
- Data collection, processing, and analysis techniques\
- Machine learning algorithms and their applications\
- Software development methodologies and tools\
- Project planning and management strategies\
- Design principles and user experience considerations\
3. Based on your analysis, provide a detailed answer to the question. Your\
answer should include:\
- A clear explanation of the concepts, techniques, or strategies relevant to the topic\
- Specific examples or use cases to illustrate your points\
- Recommendations for tools, libraries, or frameworks that can be used to implement the solutions\
- Best practices and tips for success in the given area\
- Potential challenges or considerations to keep in mind\
4. If the question is broad or multi-faceted, break down your answer into smaller, organized\
sections to ensure clarity and comprehensiveness.\
5. Use a professional and friendly tone throughout your response, and aim to provide actionable\
insights and guidance that the user can apply to their work.\
Remember, as an expert in data science and software development, your goal is to empower the user\
with the knowledge and tools they need to succeed in their projects. Provide thorough explanations,\
relevant examples, and practical recommendations to help them make informed decisions and achieve\
their goals.\
6. Always return answers in Markdown format\
7. If there is additional context it will be provided here.\
\
\
",
		-- Other configuration options
	}, opts or {})
	vim.fn.mkdir(conversation_dir, "p")
	-- Load custom syntax file
	vim.cmd("autocmd BufRead,BufNewFile *.claude set filetype=claude")
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
		local formatted_entry = string.format("**%s**: %s", entry.role, entry.content)
		conversation_text = conversation_text .. formatted_entry .. "\n"
	end
	vim.api.nvim_buf_set_lines(bufh, 0, -1, false, vim.split(conversation_text, "\n"))

	-- Apply syntax highlighting
	vim.api.nvim_buf_set_option(bufh, "filetype", "markdown")
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

local function make_request(callback, additional_context)
	local api_key = vim.env.ANTHROPIC_API_KEY
	if not api_key then
		vim.api.nvim_err_writeln("ANTHROPIC_API_KEY environment variable is not set.")
		return
	end
	local system_prompt_with_context = M.config.system_prompt .. "Additional context: \n\n" .. additional_context
	local url = "https://api.anthropic.com/v1/messages"
	local headers = {
		["x-api-key"] = M.config.api_key,
		["anthropic-version"] = "2023-06-01",
		["content-type"] = "application/json",
	}

	local data = {
		model = M.config.model,
		max_tokens = M.config.max_tokens,
		system = system_prompt_with_context,
		messages = conversation_history,
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

local function run_query(bufh, query, additional_context)
	table.insert(conversation_history, { role = "user", content = query .. "\n" })
	display_conversation(bufh)

	make_request(function(response)
		if response.status ~= 200 then
			vim.api.nvim_err_writeln("Error: " .. response.body)
		else
			handle_response(bufh, response.body)
		end
	end, additional_context)
end

local function save_conversation(conversation_name)
	local file_path = conversation_dir .. "/" .. conversation_name .. ".txt"
	local file = io.open(file_path, "w")
	if file then
		for _, entry in ipairs(conversation_history) do
			file:write(string.format("%s: %s\n", entry.role, entry.content))
		end
		file:close()
		vim.notify("Conversation saved: " .. conversation_name, vim.log.levels.INFO)
	else
		vim.notify("Failed to save conversation: " .. conversation_name, vim.log.levels.ERROR)
	end
end

local function load_conversation(conversation_name)
	local file_path = conversation_dir .. "/" .. conversation_name .. ".txt"
	local file = io.open(file_path, "r")
	if file then
		conversation_history = {}
		for line in file:lines() do
			local role, content = line:match("^(%w+):%s*(.*)$")
			if role and content then
				table.insert(conversation_history, { role = role, content = content })
			end
		end
		file:close()
		vim.notify("Conversation loaded: " .. conversation_name, vim.log.levels.INFO)
	else
		vim.notify("Conversation not found: " .. conversation_name, vim.log.levels.WARN)
	end
end

local function delete_conversation(conversation_name)
	local file_path = conversation_dir .. "/" .. conversation_name .. ".txt"
	local success, err = os.remove(file_path)
	if success then
		vim.notify("Conversation deleted: " .. conversation_name, vim.log.levels.INFO)
	else
		vim.notify("Failed to delete conversation: " .. conversation_name, vim.log.levels.ERROR)
	end
end

function M.browse_conversations()
	local conversations = {}
	for file in vim.fs.dir(conversation_dir) do
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
					load_conversation(selection[1])
					M.open_conversation_window()
				end)
				map("i", "<C-d>", function()
					local selection = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)
					delete_conversation(selection[1])
					M.browse_conversations()
				end)
				return true
			end,
		})
		:find()
end

local function get_current_file_content()
	local bufnr = vim.api.nvim_get_current_buf()
	local file_content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	return file_content
end

local function get_project_files_content()
	local project_root = vim.fn.getcwd()
	local project_files = {}

	for _, file in ipairs(vim.fn.glob(project_root .. "/*", 0, 1)) do
		if vim.fn.filereadable(file) == 1 then
			local file_content = table.concat(vim.fn.readfile(file), "\n")
			table.insert(project_files, file_content)
		end
	end

	return table.concat(project_files, "\n")
end

function M.open_conversation_window(additional_context)
	local conversation_bufh, conversation_winnr, input_bufh, input_winnr = setup_floating_windows()
	display_conversation(conversation_bufh)

	vim.api.nvim_buf_set_keymap(input_bufh, "i", "<CR>", "", {
		noremap = true,
		callback = function()
			local query = vim.api.nvim_buf_get_lines(input_bufh, 0, -1, false)[1]
			vim.api.nvim_buf_set_lines(input_bufh, 0, -1, false, { "" })
			display_conversation(conversation_bufh)
			run_query(conversation_bufh, query, additional_context)
		end,
	})

	vim.api.nvim_buf_set_keymap(input_bufh, "i", "<C-s>", "", {
		noremap = true,
		callback = function()
			vim.ui.input({ prompt = "Enter conversation name: " }, function(conversation_name)
				if conversation_name then
					save_conversation(conversation_name)
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

	vim.api.nvim_set_current_win(input_winnr)
	vim.api.nvim_command("startinsert")
end

vim.api.nvim_create_user_command("ClaudeConversation", function()
	conversation_history = {}
	M.open_conversation_window("")
end, {})

vim.api.nvim_create_user_command("ClaudeBrowseConversations", function()
	M.browse_conversations()
end, {})

vim.api.nvim_create_user_command("ClaudeConversationWithCurrentFile", function()
	local current_file_content = get_current_file_content()
	conversation_history = {}
	M.open_conversation_window(current_file_content)
end, {})

vim.api.nvim_create_user_command("ClaudeConversationWithProjectFiles", function()
	local project_files_content = get_project_files_content()
	conversation_history = {}
	M.open_conversation_window(project_files_content)
end, {})

return M
