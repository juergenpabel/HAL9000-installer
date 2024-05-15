import os
import sys
import psutil

from textual.app import App, ComposeResult, RenderResult
from textual.containers import Horizontal, Vertical, VerticalScroll, ScrollableContainer
from textual.widget import Widget
from textual.widgets import Button, ContentSwitcher, Footer, Header, MarkdownViewer, Static, Tree
from textual import events
from textual_terminal import Terminal
from rich_pixels import Pixels


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
	BINDINGS = [ ('1', 'tab_installer', "Show the HAL9000 installer"),
	             ('2', 'tab_terminal',  "Show a terminal window"),
	             ('9', 'tab_help', "Help"),
	             ('ctrl+c', 'app_exit', "Exit") ]


	def __init__(self):
		super().__init__()
		self.installer_node = None
		self.installer_log_timer = None


	def on_mount(self) -> None:
		self.title = "HAL9000 Installer"


	def compose(self) -> ComposeResult:
		self.installer_menu_system: Tree[str] = Tree("System setup", id='installer_menu_system', data=None)
		self.installer_menu_system_software = self.installer_menu_system.root.add("Install software",  data='ecripts/system/software/run.sh')
		self.installer_menu_system_software.add_leaf("Install required system packages",               data='scripts/system/software/install_packages.sh')
		for node_model in [self.installer_menu_system_software.add("Device-specific software",            data=None)]:
			if os.getenv('HAL9000_HARDWARE_VENDOR', default='unknown') == 'Raspberry Pi':
				node.add_leaf("Install voicecard/respeaker sound driver", data='scripts/system/software/rpi-zero2w/install_voicecard.sh')
			if os.getenv('HAL9000_HARDWARE_VENDOR', default='unknown') == 'Raxda':
				if os.getenv('HAL9000_HARDWARE_PRODUCT', default='unknown') == 'Zero 3':
					for node in [node_model.add("Radxa Zero 3",                         data='scripts/system/software/radxa-zero3/run.sh')]:
						pass
			if len(node_model.children) == 0:
				node_model.remove()
		self.installer_menu_system_configure = self.installer_menu_system.root.add("Configure system", data='scripts/system/configure/run.sh')
		self.installer_menu_system_configure.add_leaf("Create 'hal9000' (application) user & group",   data='scripts/system/configure/create_user.sh')
		self.installer_menu_system_configure.add_leaf("Configure TTY device",                          data='scripts/system/configure/create_udev_ttyHAL9000.sh')
		self.installer_menu_system_configure.add_leaf("Configure ALSA sound card",                     data='scripts/system/configure/create_udev_alsa.sh')
		for node_model in [self.installer_menu_system_configure.add("Device-specific configurations",   data=None)]:
			if os.getenv('HAL9000_HARDWARE_VENDOR', default='unknown') == 'Raspberry Pi':
				if os.getenv('HAL9000_HARDWARE_PRODUCT', default='unknown') == 'Zero 2 W':
					for node in [node_model.add("Raspberry Pi Zero 2W",          data='scripts/system/configure/rpi-zero2w/run.sh')]:
						node.add_leaf("Deactivate CPUs #2 and #3",           data='scripts/system/configure/rpi-zero2w/configure_maxcpus.sh 2')
						node.add_leaf("Configure swap (1GB & swapiness=0)",  data='scripts/system/configure/rpi-zero2w/configure_swap.sh 1024')
			if os.getenv('HAL9000_HARDWARE_VENDOR', default='unknown') == 'Raxda':
				if os.getenv('HAL9000_HARDWARE_PRODUCT', default='unknown') == 'Zero 3':
					for node in [node_model.add("Radxa Zero 3",                  data='scripts/system/configure/radxa-zero3/run.sh')]:
						pass
			if len(node_model.children) == 0:
				node_model.remove()
		for node_mcu in [self.installer_menu_system_configure.add("Microcontroller", data=None)]:
			for node in [node_mcu.add("Build firmware",           data='scripts/arduino/build/run.sh')]:
				node.add_leaf("Prepare build environment",    data='scripts/arduino/build/prepare_buildenv.sh')
				node.add_leaf("Compile firmware",             data='scripts/arduino/build/compile_firmware.sh')
				node.add_leaf("Flash firmware",               data='scripts/arduino/build/flash_firmware.sh')
			for node in [node_mcu.add("Pre-build firmware",       data='scripts/arduino/pre-build/run.sh')]:
				node.add_leaf("Download firmware",            data='scripts/arduino/pre-build/download_firmware.sh')
				node.add_leaf("Flash firmware",               data='scripts/arduino/pre-build/flash_firmware.sh')
		self.installer_menu_system.root.expand_all()
		self.installer_menu_hal9000: Tree[str] = Tree("Application (HAL9000)", id='installer_menu_hal9000', data=None)
		for node_container in [self.installer_menu_hal9000.root.add("Container",              data=self.hook_installer_hal9000_source)]:
			for node_build in [node_container.add("Build images",                         data='scripts/podman/build/run.sh')]:
				node_build.add_leaf("Prepare build environment",                      data='scripts/podman/build/build_prepare.sh')
				node_build.add_leaf("Build images",                                   data='scripts/podman/build/build_images.sh')
				node_build.add_leaf("Create containers",                              data='scripts/podman/build/create_containers.sh')
				node_build.add_leaf("Run containers (via systemd)",                   data='scripts/podman/build/deploy_containers.sh')
			if os.getenv('HAL9000_PLATFORM_ARCH', default='unknown') in ['arm64', 'amd64']:
				for node_ghcrio in [node_container.add("Pre-build container images",  data=None)]:
					for node in [node_ghcrio.add("Version 'stable'",              data='scripts/podman/pre-build/run.sh stable')]:
						node.add_leaf("Download images from ghcr.io",         data='scripts/podman/pre-build/download_images.sh stable')
						node.add_leaf("Create containers",                    data='scripts/podman/pre-build/create_containers.sh stable')
						node.add_leaf("Run containers (via systemd)",         data='scripts/podman/pre-build/deploy_containers.sh stable')
					for node in [node_ghcrio.add("Version 'development'",         data='scripts/podman/pre-build/run.sh development')]:
						node.add_leaf("Download image from ghcr.io",          data='scripts/podman/pre-build/download_images.sh development')
						node.add_leaf("Create containers",                    data='scripts/podman/pre-build/create_containers.sh development')
						node.add_leaf("Run containers (via systemd)",         data='scripts/podman/pre-build/deploy_containers.sh development')
		self.installer_menu_hal9000.root.expand_all()
		self.installer_btn = Button("Execute", id='installer_btn')
		self.installer_log = Terminal(command=None, id='installer_log')
		self.terminal = Terminal(command='bash', id='terminal')
		try:
			with open('README.md', 'r') as file:
				self.help = MarkdownViewer(file.read(), id='help', show_table_of_contents=False)
		except BaseException as e:
			self.help = Static(f"ERROR: failed to open 'README.md' (cwd='{os.getcwd()}')\nException: {e}", id='help')
		with Horizontal():
			yield HAL9000(id='hal9000')
			with Vertical():
				yield Static("HAL9000 Installer", id='title')
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
		self.query_one('#installer_menu').border_title = "Just what do you think you're doing, Dave?"
		self.query_one('#help').border_title = 'README.md'
		self.installer_log.border_title = "Command execution"


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
			self.installer_btn.label = 'Abort execution'
			self.installer_log.command = command
			self.installer_log.border_title = f"Command execution: {title}"
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
		self.installer_log.border_title = "Command execution"
		self.installer_btn.label = 'Execute'
		self.installer_menu_system.disabled = False
		self.installer_menu_hal9000.disabled = False
		if hasattr(self.installer_node, 'focusable') is True:
			self.set_focus(self.installer_node)
		else:
			self.set_focus(self.installer_menu_system)

	def hook_installer_system_software_model(self) -> None:
		pass
	def hook_installer_system_software_model_pizero2w(self) -> None:
		pass

	def hook_installer_system_configure_model(self) -> None:
		pass

	def hook_installer_system_configure_mcu_model(self) -> None:
		pass

	def hook_installer_hal9000_source(self) -> None:
		pass

	def hook_installer_hal9000_download(self) -> None:
		pass


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
			self.notify("An installer process is currently executing, must wait for its completion (or abort its execution) to exit")
		else:
			self.exit()


	def on_installer_timer(self) -> None:
		if self.installer_log.emulator is None or self.installer_log.emulator.pid is None or psutil.pid_exists(self.installer_log.emulator.pid) is False:
			self.installer_log_timer.stop()
			self.installer_log_timer = None
			self.installer_log.refresh()
			self.installer_log.stop()
			self.installer_log.command = None
			self.installer_log.border_title = "Command execution"
			self.installer_btn.label = 'Execute'
			self.installer_menu_system.disabled = False
			self.installer_menu_hal9000.disabled = False
			if hasattr(self.installer_node, 'focusable') is True:
				self.set_focus(self.installer_node)
			else:
				self.set_focus(self.installer_menu_system)

	async def hacky_markdown_document_load_hook(self, path) -> None:
		pass


if __name__ == "__main__":
	app = HAL9000InstallerApp()
	app.run()
