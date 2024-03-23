import pynvim
import anthropic
import os


@pynvim.plugin
class ClaudePlugin(object):

    def __init__(self, nvim):
        self.nvim = nvim

    @pynvim.command("Claude", nargs="*", range="", sync=True)
    def claude_command(self, args, range):
        user_input = " ".join(args)
        response = self.generate_response(user_input)
        self.nvim.current.buffer.append(response)

    def generate_response(self, user_input):
        # Add your logic here to generate the response
        # This is just a placeholder example
        response = "Hello, " + user_input + "!"
        return response
