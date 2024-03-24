# Claude.nvim - A Claude API wrapper for neovim

## Features

- **Context-Aware**: The assistant can take into account the current file, project, or any additional context you provide.
- **Persistent Conversation History**: Your conversation history is saved and can be loaded for ongoing discussions.

## Installation

1. Set the `ANTHROPIC_API_KEY` environment variable with your Anthropic API key.
2. Install the Claude Neovim plugin using your preferred plugin manager, for example:
   - Using `packer.nvim`: `use "evangstav/claude.nvim"`
   - Using `vim-plug`: `Plug "evangstav/claude.nvim"`
   - Using `lazy.nvim`: `"evangstav/claude.nvim"`

## Usage

1. Open a Neovim buffer and run the `:ClaudeConversation` command to start a new conversation.
2. Type your question or prompt in the input window and press Enter to send it to Claude.
3. The assistant's response will be displayed in the conversation window.
4. Use the `Ctrl+S` shortcut in the input window to save the current conversation.
5. Run the `:ClaudeBrowseConversations` command to load a saved conversation.
6. Use the `:ClaudeConversationWithCurrentFile` or `:ClaudeConversationWithProjectFiles` commands to include the content of the current file or the entire project in the conversation context.

## Configuration

By default the plugin is reading the ANTHROPIC_API_KEY environment variable.
You can customize the plugin's behavior by calling the `setup` function in your Neovim configuration file.
Possible models at the moment:

1. claude-3-opus-20240229
1. claude-3-sonnet-20240229
1. claude-3-haiku-20240307

Example configuration:

```lua
require("claude").setup({
  api_key = "your_api_key_here",
  model = "claude-3-opus-20240229",
  max_tokens = 4096,
})
```

## Contributing

Contributions to the project are welcome! Please open an issue or submit a pull request on the [GitHub repository](https://github.com/evangstav/claude.nvim).

## License

This project is licensed under the [MIT License](LICENSE).
