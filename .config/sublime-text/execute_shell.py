import os
import sublime
import sublime_plugin
import shlex
import subprocess
from typing import Tuple, List
from pathlib import Path


def run_subprocess(commands, cwd: Path = "~") -> Tuple[bool, str, str]:
    """
    :param cwd: current working directory
    :param commands: commands to run in subshell, sequence of or singular string(s)
    :parm cwd: working directory for subshell
    :returns: status code (True on success, False on error), stdout, stderr
    """
    result = subprocess.run(
        commands,
        cwd=os.path.abspath(os.path.expanduser(cwd)),
        capture_output=True,
        text=True,
    )
    return result.returncode, result.stdout, result.stderr


class ShellCommandInputHandler(sublime_plugin.TextInputHandler):
    LAST_COMMAND=""

    def name(self):
        return "shell_command"

    def placeholder(self):
        return "Enter commands to execute. . ."

    def initial_text(self):
        return ShellCommandInputHandler.LAST_COMMAND

    def preview(self, shell_command):
        return "Line: 1, Column: " + str(len(shell_command))


class ExecuteShell(sublime_plugin.ApplicationCommand):
    def input(self, args):
        return ShellCommandInputHandler()

    def run(self, shell_command):
        ShellCommandInputHandler.LAST_COMMAND = shell_command
        actual_command = [os.path.expanduser(arg) for arg in shlex.split(shell_command.strip())]
        
        print("Running command " + str(actual_command))
        try:
            status_code, stdout, stderr = run_subprocess(actual_command)
        except Exception as e:
            sublime.error_message(f"{e}")
            return

        status_style = "style=\"color:MediumSeaGreen;\"" if status_code == 0 else "style=\"color:Orange;\""
        html_stdout = stdout.replace("\n", "<br>")
        html_stderr = stderr.replace("\n", "<br>")

        # Get the active view
        view = sublime.active_window().active_view()

        # Define the HTML content for the popup
        html_content = f"""
        <html>
            <body>
                <code {status_style}><bold>Status code</bold>: <pre>{status_code}</pre></code><br>
                <code style="color:DodgerBlue;"><pre>{html_stdout}</pre></code> <br>
                <code style="color:Tomato;"><pre>{html_stderr}</pre></code>
            </body>
        </html>
        """

        # Show the popup
        view.show_popup(html_content, max_width=1200)
