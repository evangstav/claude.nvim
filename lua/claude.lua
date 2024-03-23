return {
	"evangstav/claude.nvim",
	build = ":UpdateRemotePlugins",
	config = function()
		vim.keymap.set("n", "<leader>ep", "<cmd>call ExampleFunction()<CR>", { desc = "Example Python Plugin" })
	end,
}
