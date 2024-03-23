import pynvim


@pynvim.plugin
class HelloPlugin(object):
    def __init__(self, nvim):
        self.nvim = nvim

    @pynvim.command("Hello", nargs="*", range="")
    def hello_command(self, args, range):
        self.nvim.out_write("Hello\n")
