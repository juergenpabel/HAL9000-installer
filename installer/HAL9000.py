import os
import sys

from textual.app import App, ComposeResult, RenderResult
from textual import events
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.widgets import *
from textual.containers import ScrollableContainer
from textual.widget import Widget
from textual_terminal import Terminal
from rich_pixels import Pixels

class HAL9000(Widget):
	def __init__(self, id):
		super().__init__(id=id)

	def render(self) -> RenderResult:
		w,h = os.get_terminal_size()
		h = h*2 - 4
		w = int(h / 3)
		return Pixels.from_image_path("resources/images/HAL9000.jpg", (w,h))


class HAL9000InstallerApp(App):
	CSS_PATH = "HAL9000.tcss"
	BINDINGS = [
	             ("1", "tab_installer", "Show the HAL9000 installer"),
	             ("2", "tab_terminal",  "Show a terminal window"),
	]

	def __init__(self):
		super().__init__()
		self.installer_cmd = "/bin/true"

	def on_mount(self) -> None:
		self.title = "HAL9000 Installer"

	def compose(self) -> ComposeResult:
		self.installer_menu = Select[str]([("Create user+group 'hal9000' (sudo)", 'scripts/system/user_create.sh'),
		                                   ("Configure /dev/ttyHAL9000",         'scripts/system/udev_configure.sh'),
		                                   ("Configure ALSA:HAL9000",            'scripts/system/alsa_configure.sh'),
		                                   ("Flash Arduino Application",         'scripts/arduino/flash_firmware.sh'),
		                                   ("Flash Arduino Filesystem",          'scripts/arduino/flash_filesystem.sh'),
		                                   ("Download container images",         'scripts/podman/download_images.sh'),
		                                   ("Create containers",                 'scripts/podman/create_containers.sh'),
		                                   ("Activate startup on boot",          'scripts/podman/deploy_containers.sh')],
		                                  id='installer_menu')
		self.installer_btn = Button("Start", id="installer_btn")
		self.installer_log = Terminal(command=self.installer_cmd, id="installer_log")
		self.terminal = Terminal(command="bash", id="terminal")
		with Horizontal():
			yield HAL9000(id='hal9000')
			with Vertical():
				yield Static("HAL9000 Installer", id='title')
				with ContentSwitcher(initial="installer", id='content'):
					with Vertical(id='installer'):
						yield self.installer_menu
						yield self.installer_btn
						yield self.installer_log
					yield self.terminal
		yield Footer()

	def on_mount(self) -> None:
		self.installer_menu.border_title = "Just what do you think you're doing, Dave?"

	def on_ready(self) -> None:
		self.terminal.start()
		self.set_focus(self.installer_menu)

	def on_button_pressed(self, event: Button.Pressed) -> None:
		if event.button.id == 'installer_btn':
			if self.installer_menu.disabled == False:
				self.installer_menu.disabled = True
				self.installer_btn.label = 'Stop'
				self.installer_log.command = self.installer_menu.value
				self.installer_log.start()
				self.set_focus(None)
			else:
				self.installer_log.stop()
				self.installer_log.refresh()
				self.installer_log.command = '/bin/true'
				self.installer_btn.label = 'Start'
				self.installer_menu.disabled = False
				self.set_focus(self.installer_menu)
			event.button.refresh()

	def action_tab_installer(self) -> None:
		self.query_one(ContentSwitcher).current = 'installer'
		if self.installer_menu.disabled is False:
			self.set_focus(self.installer_menu)
		else:
			self.set_focus(None)

	def action_tab_terminal(self) -> None:
		self.query_one(ContentSwitcher).current = 'terminal'
		self.set_focus(self.terminal)

if __name__ == "__main__":
	app = HAL9000InstallerApp()
	app.run()

