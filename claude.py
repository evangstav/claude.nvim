import pynvim
import anthropic
import os


@pynvim.plugin
class ClaudePlugin:
    def __init__(self, nvim):
        self.nvim = nvim
        self.client = anthropic.Anthropic(
            api_key=os.environ["ANTHROPIC_API_KEY"],
        )

    @pynvim.command("Claude", nargs="*", range="", sync=True)
    def claude_command(self, args, range):
        user_input = " ".join(args)

        message = self.client.messages.create(
            model="claude-3-opus-20240229",
            temperature=0.2,
            max_tokens=100,
            system="Respond only in Yoda-speak, unless you receive the 'safe word'. The 'safe word' is pineapple.",
            messages=[{"role": "user", "content": user_input}],
        )

        # Create a new floating window
        floating_window = self.nvim.api.open_win(
            self.nvim.api.create_buf(False, True),
            True,
            {
                "relative": "editor",
                "width": 80,
                "height": 10,
                "col": (self.nvim.api.get_option("columns") - 80) // 2,
                "row": (self.nvim.api.get_option("lines") - 10) // 2,
                "style": "minimal",
                "border": "single",
            },
        )

        # Set the content of the floating window
        self.nvim.api.buf_set_lines(
            self.nvim.api.win_get_buf(floating_window),
            0,
            -1,
            True,
            message.content,
        )

        # Set the highlighting for the floating window
        self.nvim.api.win_set_option(floating_window, "winhl", "Normal:Normal")
