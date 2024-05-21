import os
import sys
import gettext

from textual.app import App, ComposeResult, RenderResult
from textual.containers import Horizontal, Vertical, VerticalScroll, ScrollableContainer
from textual.widget import Widget
from textual.widgets import Button, ContentSwitcher, Footer, Header, MarkdownViewer, Static, Tree
from textual import events
from textual_terminal import Terminal
from rich_pixels import Pixels


gettext.translation('HAL9000-installer', 'resources/locales', fallback=True, languages=['en', 'de']).install()


class HAL9000(Widget):
	def __init__(self, id):
		super().__init__(id=id)
	def render(self) -> RenderResult:
		w,h = os.get_terminal_size()
		h = h*2 - 4
		w = int(h / 3)
		return Pixels.from_image_path('resources/images/HAL9000.jpg', (w,h))


class HAL9000InstallerApp(App):
	CSS_PATH = 'HAL9000.tcss'
	BINDINGS = [ ('1', 'tab_installer', _("Show the HAL9000 installer")),
	             ('2', 'tab_terminal',  _("Show a terminal window")),
	             ('9', 'tab_help', _("Help")),
	             ('ctrl+c', 'app_exit', _("Exit")) ]


	def __init__(self):
		super().__init__()
		self.installer_node = None
		self.installer_log_timer = None


	def on_mount(self) -> None:
		self.title = _("HAL9000 Installer")


	def compose(self) -> ComposeResult:
		self.installer_menu_system: Tree[str] = Tree("System setup", id='installer_menu_system', data=None)
		self.installer_menu_system_software = self.installer_menu_system.root.add(_("Install software"),  data='resources/scripts/linux/software/run.sh')
		self.installer_menu_system_software.add_leaf(_("Install required system packages"),               data='resources/scripts/linux/software/install_packages.sh')
		for node_model in [self.installer_menu_system_software.add(_("Device-specific software"),         data=None)]:
			if os.getenv('HAL9000_HARDWARE_VENDOR', default='unknown') == 'Raspberry Pi':
				if os.getenv('HAL9000_HARDWARE_PRODUCT', default='unknown') == 'Zero 2W':
					for node in [node_model.add("Raspberry Pi:Zero 2W",               data='resources/scripts/linux/software/rpi-zero2w/run.sh')]:
						node.add_leaf(_("Install voicecard/respeaker sound driver"), data='resources/scripts/linux/software/rpi-zero2w/install_voicecard.sh')
			if os.getenv('HAL9000_HARDWARE_VENDOR', default='unknown') == 'Orange Pi':
				if os.getenv('HAL9000_HARDWARE_PRODUCT', default='unknown') == 'Zero 2W':
					for node in [node_model.add("Orange Pi: Zero 2W",           data='resources/scripts/linux/software/opi-zero2w/run.sh')]:
						node.add_leaf(_("Install voicecard/respeaker sound driver"), data='resources/scripts/linux/software/rpi-zero2w/install_voicecard.sh')
			if os.getenv('HAL9000_HARDWARE_VENDOR', default='unknown') == 'Radxa':
				if os.getenv('HAL9000_HARDWARE_PRODUCT', default='unknown') == 'Zero 3W':
					for node in [node_model.add("Radxa: Zero 3W",              data='resources/scripts/linux/software/radxa-zero3w/run.sh')]:
						node.add_leaf(_("Install voicecard/respeaker sound driver"), data='resources/scripts/linux/software/radxa-zero3w/install_voicecard.sh')
			if len(node_model.children) == 0:
				node_model.remove()
		self.installer_menu_system_configure = self.installer_menu_system.root.add(_("Configure system"), data='resources/scripts/linux/configure/run.sh')
		self.installer_menu_system_configure.add_leaf(_("Create 'hal9000' (application) user & group"),   data='resources/scripts/linux/configure/create_user.sh')
		self.installer_menu_system_configure.add_leaf(_("Configure TTY device"),                          data='resources/scripts/linux/configure/create_udev_tty.sh')
		self.installer_menu_system_configure.add_leaf(_("Configure ALSA sound card"),                     data='resources/scripts/linux/configure/create_udev_alsa.sh')
		for node_model in [self.installer_menu_system_configure.add(_("Device-specific configurations"),   data=None)]:
			if os.getenv('HAL9000_HARDWARE_VENDOR', default='unknown') == 'Raspberry Pi':
				if os.getenv('HAL9000_HARDWARE_PRODUCT', default='unknown') == 'Zero 2W':
					for node in [node_model.add("Raspberry Pi: Zero 2W",          data='resources/scripts/linux/configure/rpi-zero2w/run.sh')]:
						node.add_leaf(_("Reduce GPU memory to 16MB"),         data='resources/scripts/linux/configure/rpi-zero2w/configure_gpu.sh 16')
						node.add_leaf(_("Deactivate CPUs #2 and #3"),           data='resources/scripts/linux/configure/rpi-zero2w/configure_maxcpus.sh 2')
						node.add_leaf(_("Configure swap (1GB & swapiness=0)"),  data='resources/scripts/linux/configure/rpi-zero2w/configure_swap.sh 1024')
			if os.getenv('HAL9000_HARDWARE_VENDOR', default='unknown') == 'Orange Pi':
				if os.getenv('HAL9000_HARDWARE_PRODUCT', default='unknown') == 'Zero 2W':
					for node in [node_model.add("Orange Pi: Zero 2W",          data='resources/scripts/linux/configure/opi-zero2w/run.sh')]:
						pass
			if os.getenv('HAL9000_HARDWARE_VENDOR', default='unknown') == 'Radxa':
				if os.getenv('HAL9000_HARDWARE_PRODUCT', default='unknown') == 'Zero 3W':
					for node in [node_model.add("Radxa: Zero 3W",                  data='resources/scripts/linux/configure/radxa-zero3w/run.sh')]:
						pass
			if len(node_model.children) == 0:
				node_model.remove()
		for node_mcu in [self.installer_menu_system.root.add(_("Microcontroller"), data=None)]:
			if os.getenv('HAL9000_ARDUINO_VENDOR', default='unknown') in ['SBComponents', 'M5Stack', 'Waveshare']:
				if os.getenv('HAL9000_ARDUINO_PRODUCT', default='unknown') in ['RoundyPi', 'Core2', 'RP2040_LCD128']:
					for node in [node_mcu.add(_("Build firmware"),           data='resources/scripts/arduino/build/run.sh')]:
						node.add_leaf(_("Prepare build environment"),    data='resources/scripts/arduino/build/prepare_buildenv.sh')
						node.add_leaf(_("Compile firmware"),             data='resources/scripts/arduino/build/compile.sh')
						node.add_leaf(_("Flash firmware"),               data='resources/scripts/arduino/build/flash.sh')
					for node_github in [node_mcu.add(_("Pre-build firmware"),data=None)]:
						for node in [node_github.add(_("Version 'stable'"),      data='resources/scripts/arduino/github.com/run.sh stable')]:
							node.add_leaf(_("Download firmware"),            data='resources/scripts/arduino/github.com/download.sh stable')
							node.add_leaf(_("Flash firmware"),               data='resources/scripts/arduino/github.com/flash.sh stable')
						for node in [node_github.add(_("Version 'development'"), data='resources/scripts/arduino/github.com/run.sh development')]:
							node.add_leaf(_("Download firmware"),            data='resources/scripts/arduino/github.com/download.sh development')
							node.add_leaf(_("Flash firmware"),               data='resources/scripts/arduino/github.com/flash.sh development')
			if len(node_mcu.children) == 0:
				node_mcu.add_leaf(_("<No supported microcontroller detected>"),  data=None)
		self.installer_menu_system.root.expand_all()
		self.installer_menu_hal9000: Tree[str] = Tree(_("Application (HAL9000)"), id='installer_menu_hal9000', data=None)
		for node_container in [self.installer_menu_hal9000.root.add(_("Container"),              data=self.hook_installer_container_source)]:
			for node_build in [node_container.add(_("Build images"),                         data='resources/scripts/container/build/run.sh')]:
				node_build.add_leaf(_("Prepare build environment"),                      data='resources/scripts/container/build/prepare_buildenv.sh')
				node_build.add_leaf(_("Build images"),                                   data='resources/scripts/container/build/build_images.sh')
				node_build.add_leaf(_("Create containers"),                              data='resources/scripts/container/build/create_containers.sh localhost latest')
				node_build.add_leaf(_("Run containers (via systemd)"),                   data='resources/scripts/container/build/deploy_containers.sh localhost latest')
			if os.getenv('HAL9000_PLATFORM_ARCH', default='unknown') in ['arm64', 'amd64']:
				for node_ghcrio in [node_container.add(_("Pre-build container images"),  data=self.hook_installer_container_download_version)]:
					for node in [node_ghcrio.add(_("Version 'stable'"),              data='resources/scripts/container/ghcr.io/run.sh stable')]:
						node.add_leaf(_("Download images from ghcr.io"),         data='resources/scripts/container/ghcr.io/download_images.sh stable')
						node.add_leaf(_("Create containers"),                    data='resources/scripts/container/ghcr.io/create_containers.sh ghcr.io/juergenpabel stable')
						node.add_leaf(_("Run containers (via systemd)"),         data='resources/scripts/container/ghcr.io/deploy_containers.sh ghcr.io/juergenpabel stable')
					for node in [node_ghcrio.add(_("Version 'development'"),         data='resources/scripts/container/ghcr.io/run.sh development')]:
						node.add_leaf(_("Download images from ghcr.io"),          data='resources/scripts/container/ghcr.io/download_images.sh development')
						node.add_leaf(_("Create containers"),                    data='resources/scripts/container/ghcr.io/create_containers.sh ghcr.io/juergenpabel development')
						node.add_leaf(_("Run containers (via systemd)"),         data='resources/scripts/container/ghcr.io/deploy_containers.sh ghcr.io/juergenpabel development')
		self.installer_menu_hal9000.root.expand_all()
		self.installer_btn = Button(_("Execute"), id='installer_btn')
		self.installer_log = Terminal(command=None, id='installer_log')
		self.terminal = Terminal(command='bash', id='terminal')
		try:
			lang_id = os.getenv('LANG', default='en')
			readme_filename = f'README_{lang_id[0:2].lower()}.md'
			if os.path.exists(readme_filename) is False:
				readme_filename = 'README.md'
			with open(readme_filename, 'r') as file:
				self.help = MarkdownViewer(file.read(), id='help', show_table_of_contents=False)
		except BaseException as e:
			self.help = Static(f"ERROR: failed to open 'README.md' (cwd='{os.getcwd()}')\nException: {e}", id='help')
		with Horizontal():
			yield HAL9000(id='hal9000')
			with Vertical():
				yield Static(_("HAL9000 Installer"), id='title')
				with ContentSwitcher(initial='help', id='content'):
					with Vertical(id='installer'):
						with Horizontal(id='installer_menu'):
							with Vertical(id='installer_system'):
								yield self.installer_menu_system
							with Vertical(id='installer_hal9000'):
								yield self.installer_menu_hal9000
						yield self.installer_btn
						yield self.installer_log
					yield self.terminal
					yield self.help
		yield Footer()


	def on_mount(self) -> None:
		self.query_one('#installer_menu').border_title = _("Just what do you think you're doing, Dave?")
		self.query_one('#help').border_title = 'README.md'
		self.installer_log.border_title = _("Command execution")


	def on_ready(self) -> None:
		self.help.document.load = self.hacky_markdown_document_load_hook
		self.terminal.start()
		self.set_focus(self.installer_menu_system)
		self.refresh()


	def on_tree_node_highlighted(self, event: Tree.NodeHighlighted) -> None:
		self.installer_node = event.node
		if self.installer_node.data is None:
			self.installer_btn.disabled = True
		else:
			self.installer_btn.disabled = False


	def on_tree_node_selected(self, event: Tree.NodeSelected) -> None:
		self.on_button_pressed(Button.Pressed(self.installer_btn))


	def on_button_pressed(self, event: Button.Pressed) -> None:
		if event.button.id == 'installer_btn':
			if isinstance(self.installer_node.data, str) is True:
				self.installer_execute_command(self.installer_node.data, self.installer_node.data)
			elif callable(self.installer_node.data) is True:
				data = self.installer_node.data()
				if isinstance(data, dict):
					if 'environments' in data:
						for key, value in data['environments']:
							if value is not None:
								os.environ[key] = str(value)
							else:
								del os.environ[key]
					if 'commands' in data:
						commands = 'sh -c "'
						for command in data['commands']:
							commands += command.replace('"', '\\"')
							commands += ' ; '
						commands += '"'
						self.installer_execute_command(commands, self.installer_node.label)
				else:
					self.notify(f"BUG: unexpected type '{type(data)}' returned from handler (this shouldn't have happened)")


	def installer_execute_command(self, command, title=None) -> None:
		if self.installer_log.command is not None:
			self.notify(f"BUG: an installer command is currently still running (this shouldn't have happened)")
			return
		if title is None:
			title = comman
		executable, *arguments = command.split(' ', 1)
		if os.path.isfile(executable) is True:
			self.installer_menu_system.disabled = True
			self.installer_menu_hal9000.disabled = True
			self.installer_btn.label = _("Abort execution")
			self.installer_log.command = command
			self.installer_log.border_title = _("Command execution: {title}").format(title=title)
			self.installer_log.start()
			self.installer_log_timer = self.installer_log.set_interval(1, self.on_installer_timer)
			self.installer_log.ncol = self.installer_log.content_size.width
			self.installer_log.nrow = self.installer_log.content_size.height
			self.installer_log.send_queue.put_nowait(['set_size', self.installer_log.nrow, self.installer_log.ncol])
			self.installer_log._screen.resize(self.installer_log.nrow, self.installer_log.ncol)
			self.set_focus(self.installer_log)
		else:
			self.notify(f"BUG: command not found or not executable ('{executable}' as per '{command}')")


	def installer_abort_command(self, command) -> None:
		if self.installer_log.command is None:
			self.notify(f"BUG: no installer command is currently running (this shouldn't have happened)")
			return
		self.installer_log.stop()
		self.installer_log.refresh()
		self.installer_log.command = None
		self.installer_log.border_title = _("Command execution")
		self.installer_btn.label = _("Execute")
		self.installer_menu_system.disabled = False
		self.installer_menu_hal9000.disabled = False
		if hasattr(self.installer_node, 'focusable') is True:
			self.set_focus(self.installer_node)
		else:
			self.set_focus(self.installer_menu_system)


	def hook_installer_container_source(self):
		result = {}
		return result


	def hook_installer_container_download_version(self):
		result = {}
		return result


	def action_tab_installer(self) -> None:
		self.query_one(ContentSwitcher).current = 'installer'
		if self.installer_menu_system.disabled is False:
			self.set_focus(self.installer_menu_system)
		else:
			self.set_focus(None)


	def action_tab_terminal(self) -> None:
		self.query_one(ContentSwitcher).current = 'terminal'
		self.set_focus(self.terminal)


	def action_tab_help(self) -> None:
		self.query_one(ContentSwitcher).current = 'help'
		self.set_focus(self.help)


	def action_app_exit(self) -> None:
		if self.installer_log.command is not None:
			self.notify(_("An installer process is currently executing, must wait for its completion (or abort its execution) to exit"))
		else:
			self.exit()


	def on_installer_timer(self) -> None:
		if self.installer_log.emulator is None or self.installer_log.emulator.pid is None or os.path.isdir(f'/proc/{self.installer_log.emulator.pid}/') is False:
			self.installer_log_timer.stop()
			self.installer_log_timer = None
			self.installer_log.refresh()
			self.installer_log.stop()
			self.installer_log.command = None
			self.installer_log.border_title = _("Command execution")
			self.installer_btn.label = _("Execute")
			self.installer_menu_system.disabled = False
			self.installer_menu_hal9000.disabled = False
			if hasattr(self.installer_node, 'focusable') is True:
				self.set_focus(self.installer_node)
			else:
				self.set_focus(self.installer_menu_system)


	async def hacky_markdown_document_load_hook(self, path) -> None:
		pass


if __name__ == "__main__":
	from textual_terminal._terminal import TerminalEmulator
	def hacky_TerminalEmulator_open_terminal_hack(self, command: str):
		import pty
		import shlex
		self.pid, fd = pty.fork()
		if self.pid == 0:
			argv = shlex.split(command)
			# OPTIMIZE: do not use a fixed LC_ALL
			os.execvp(argv[0], argv)
		return fd
	TerminalEmulator.open_terminal = hacky_TerminalEmulator_open_terminal_hack
	app = HAL9000InstallerApp()
	app.run()

