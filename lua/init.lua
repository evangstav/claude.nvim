-- For init.lua
require("pynvim").setup({
	plugins = {
		hello_plugin = {
			path = "claude.nvim/rplugin/python3/hello.py",
		},
	},
})
