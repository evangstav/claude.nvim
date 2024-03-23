import pynvim
import anthropic
import os


@pynvim.plugin
class ClaudePlugin:
    def __init__(self, nvim):
        self.nvim = nvim
        # self.client = anthropic.Anthropic(
        #     api_key=os.environ["ANTHROPIC_API_KEY"],
        # )

    @pynvim.command("Claude", nargs="*", range="", sync=True)
    def claude_command(self, args, range):
        # user_input = " ".join(args)

        # message = self.client.messages.create(
        #     model="claude-3-opus-20240229",
        #     temperature=0.2,
        #     max_tokens=100,
        #     system="Respond only in Yoda-speak, unless you receive the 'safe word'. The 'safe word' is pineapple.",
        #     messages=[{"role": "user", "content": user_input}],
        # )
        #
        response = "Hello World"
        self.nvim.command(f"echo '{response}'")
