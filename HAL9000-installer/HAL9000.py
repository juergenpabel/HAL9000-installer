import os
import sys
import gettext
from yaml import safe_load as yaml_safe_load
from importlib import import_module as importlib_import_module

from textual.app import App, ComposeResult, RenderResult
from textual.containers import Horizontal, Vertical, VerticalScroll, ScrollableContainer
from textual.widget import Widget
from textual.widgets import Button, ContentSwitcher, Footer, Header, MarkdownViewer, Static, Select, SelectionList, Tree
from textual.widgets.selection_list import Selection
from textual.widgets.select import InvalidSelectValueError
from textual import events
from textual_terminal import Terminal
from rich_pixels import Pixels


gettext.translation('HAL9000-installer', 'HAL9000-installer/locales', fallback=True, languages=['en', 'de']).install()


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
		self.installer_screen_wizard_dialog = {}
		self.installer_screen_expert_trees = {}
		self.installer_cmd_queue = []
		self.installer_cmd_timer = None


	def recurse_installation_yaml(self, tree_node, data_node, label_prefix):
		show_node = True
		if 'conditions' in data_node:
			for condition in data_node['conditions']:
				if 'variable' in condition:
					if os.getenv(condition['id'], default='') != condition['value']:
						show_node = False
		if show_node is True:
			if 'nodes' in data_node:
				tree_node = tree_node.add(data_node['label'], data=data_node.get('command', None))
				for child_data_node in data_node['nodes']:
					self.recurse_installation_yaml(tree_node, child_data_node, f"{label_prefix} > {data_node['label']}")
			else:
				if 'command' in data_node:
					tree_node.add_leaf(data_node['label'], data=data_node['command'])
					self.installer_cmd_queue.append({'id': data_node['id'],
					                                 'command': data_node['command'],
					                                 'title': f"{label_prefix} > {data_node['label']}"})


	def load_installation_yaml(self, recurse_trees=True):
		self.installer_cmd_queue.clear()
		with open('HAL9000-installer/data/installation.yaml', 'r') as yaml_stream:
			installation_yaml = yaml_safe_load(yaml_stream)
			for yaml_tree_node in installation_yaml['nodes']:
				if yaml_tree_node['id'] not in self.installer_screen_expert_trees:
					self.installer_screen_expert_trees[yaml_tree_node['id']] = Tree(yaml_tree_node['label'],
					                                                                id=f"installer_screen_expert_{yaml_tree_node['id']}")
				tree = self.installer_screen_expert_trees[yaml_tree_node['id']]
				tree.clear()
				if recurse_trees is True:
					for yaml_node in yaml_tree_node['nodes']:
						self.recurse_installation_yaml(tree.root, yaml_node, yaml_tree_node['label'])
					tree.root.expand_all()


	def compose(self) -> ComposeResult:
		with open('HAL9000-installer/data/wizard/index.yaml', 'r') as yaml_stream:
			install_wizard_yaml = yaml_safe_load(yaml_stream)
		self.installer_screen_wizard_dialog['__init__'] = install_wizard_yaml[0]['id']
		for install_dialog_yaml in install_wizard_yaml:
			dialog_widget = None
			with open(install_dialog_yaml['filename'], 'r') as yaml_stream:
				dialog_yaml = yaml_safe_load(yaml_stream)
				if dialog_yaml['type'] == 'select':
					select_value = os.getenv(dialog_yaml['name'], default=None)
					if select_value is None or select_value not in [option['value'] for option in dialog_yaml['options']]:
						select_value = Select.BLANK
					dialog_widget = Select[str]([(option['label'], option['value']) for option in dialog_yaml['options']],
			                                            id=dialog_yaml['id'],
			                                            name=dialog_yaml['name'],
					                            value=select_value,
			                                            allow_blank=False)
				if dialog_yaml['type'] == 'list':
					dialog_widget = SelectionList[str](id=dialog_yaml['id'])
					for option in dialog_yaml['options']:
						dialog_widget.add_option(Selection(option['label'], option['value']))
				if dialog_yaml['type'] == 'plugin':
					plugin_module = importlib_import_module(dialog_yaml['plugin']['module'])
					if dialog_yaml['plugin']['class'] not in plugin_module.__dict__:
						self.notify(f"BUG: {dialog_yaml['plugin']['class']} not found in {dialog_yaml['plugin']['module']}")
					else:
						plugin_class = plugin_module.__dict__[dialog_yaml['plugin']['class']]
						plugin = plugin_class(dialog_yaml['id'], dialog_yaml['name'], self)
						dialog_widget = plugin.build()
			if dialog_widget is not None:
				dialog_widget.border_title = dialog_yaml['label']
				dialog_widget.next_dialog = install_dialog_yaml['next']
				self.installer_screen_wizard_dialog[install_dialog_yaml['id']] = dialog_widget
		self.tab_installer = Vertical(id='tab_installer')
		self.installer_btn = Button(_("Next"), id='installer_btn')
		self.installer_cmd = Terminal(command=None, id='installer_cmd')
		self.tab_terminal = Terminal(command='bash', id='tab_terminal')
		try:
			lang_id = os.getenv('LANG', default='en')
			readme_filename = f'README_{lang_id[0:2].lower()}.md'
			if os.path.exists(readme_filename) is False:
				readme_filename = 'README.md'
			with open(readme_filename, 'r') as file:
				self.tab_help = MarkdownViewer(file.read(), id='tab_help', show_table_of_contents=False)
		except BaseException as e:
			self.tab_help = Static(f"ERROR: failed to open 'README.md' (cwd='{os.getcwd()}')\nException: {e}", id='tab_help')
		with Horizontal():
			yield HAL9000(id='hal9000')
			with Vertical():
				yield Static(_("HAL9000 Installer"), id='title')
				with ContentSwitcher(id='body', initial='tab_help'):
					with self.tab_installer:
						with ContentSwitcher(id='installer_screen', initial='installer_screen_wizard'):
							with Vertical(id='installer_screen_wizard'):
								with ContentSwitcher(id='installer_screen_wizard_dialog', initial='installer_screen_wizard_strategy'):
									next = self.installer_screen_wizard_dialog['__init__']
									while next != '':
										dialog = self.installer_screen_wizard_dialog[next]
										next = dialog.next_dialog
										yield dialog
							with Horizontal(id='installer_screen_expert'):
								self.load_installation_yaml(False)
								for id, tree in self.installer_screen_expert_trees.items():
									yield tree
						yield self.installer_btn
						yield self.installer_cmd
					yield self.tab_terminal
					yield self.tab_help
		yield Footer()


	def on_mount(self) -> None:
		self.title = _("HAL9000 Installer")
		self.query_one('#tab_help').border_title = 'README.md'
		self.query_one('#installer_screen_expert').border_title = _("Just what do you think you're doing, Dave?")
		self.query_one('#installer_cmd').border_title = _("Command execution")


	def on_ready(self) -> None:
		self.tab_help.document.load = self.hacky_markdown_document_load_hook
		self.tab_terminal.start()
		self.refresh()


	def action_tab_installer(self) -> None:
		self.query_one('#body').current = 'tab_installer'


	def action_tab_terminal(self) -> None:
		self.query_one('#body').current = 'tab_terminal'
		self.set_focus(self.tab_terminal)


	def action_tab_help(self) -> None:
		self.query_one('#body').current = 'tab_help'
		self.set_focus(self.tab_help)


	def action_app_exit(self) -> None:
		if self.installer_cmd.command is not None:
			self.notify(_("An installer process is currently executing, must wait for its completion (or abort its execution) to exit"))
		else:
			self.exit()


	def on_select_changed(self, event: Select.Changed) -> None:
		if self.query_one('#installer_screen').current == 'installer_screen_wizard':
			if event.select.name is not None:
				os.environ[event.select.name] = event.select.value


	def on_tree_node_highlighted(self, event: Tree.NodeHighlighted) -> None:
		if self.query_one('#installer_screen').current == 'installer_screen_expert':
			for tree in self.installer_screen_expert_trees.values():
				if tree != event.control:
					tree.select_node(None)
			if event.node.data is None:
				self.installer_btn.disabled = True
			else:
				self.installer_btn.disabled = False


	def on_tree_node_selected(self, event: Tree.NodeSelected) -> None:
		if self.query_one('#installer_screen').current == 'installer_screen_expert':
			self.on_button_pressed(Button.Pressed(self.installer_btn))


	def on_button_pressed(self, event: Button.Pressed) -> None:
		if event.button.id == 'installer_btn':
			if self.query_one('#installer_screen').current == 'installer_screen_wizard':
				if str(self.installer_btn.label) == str(_("Next")):
					dialog_id = self.query_one('#installer_screen_wizard_dialog').current
					dialog_next = self.query_one(f"#{dialog_id}").next_dialog
					if dialog_next in self.installer_screen_wizard_dialog:
						self.query_one('#installer_screen_wizard_dialog').current = self.installer_screen_wizard_dialog[dialog_next].id
						self.set_focus(self.installer_screen_wizard_dialog[dialog_next])
						key = self.installer_screen_wizard_dialog[dialog_next].name
						if key is not None and key in os.environ:
							try:
								self.installer_screen_wizard_dialog[dialog_next].value = os.environ[key]
							except InvalidSelectValueError:
								pass
				elif str(self.installer_btn.label) == str(_("Start installation")):
					self.installer_screen_wizard_dialog['progress'].action_first()
					data = self.installer_cmd_queue.pop(0)
					self.installer_execute_command(data['id'], data['command'], data['title'])
				elif str(self.installer_btn.label) == str(_("Abort")):
					self.installer_abort_command()
					self.query_one('#installer_screen_wizard_dialog').current = 'installer_screen_wizard_strategy'
					self.set_focus(self.installer_screen_wizard_dialog['strategy'])
					self.installer_btn.label = _("Next")
				else:
					self.exit()
				if self.query_one('#installer_screen_wizard_dialog').current == 'installer_screen_wizard_progress':
					if str(self.installer_btn.label) == str(_("Next")):
						self.load_installation_yaml(True)
						if os.environ['HAL9000_INSTALL_STRATEGY'] == 'standard':
							self.installer_screen_wizard_dialog['progress'].clear_options()
							for data in self.installer_cmd_queue:
								if 'command' in data:
									self.installer_screen_wizard_dialog['progress'].add_option(Selection(data['title'],
									                                                                     data['id'],
									                                                                     False,
									                                                                     data['id'],
									                                                                     True))
							self.installer_btn.label = _("Start installation")
							self.set_focus(self.installer_btn)
						elif os.environ['HAL9000_INSTALL_STRATEGY'] == 'expert':
							self.query_one('#installer_screen').current = 'installer_screen_expert'
							self.installer_btn.label = _("Execute")
							self.installer_btn.disabled = True
							self.set_focus(self.query_one('#installer_screen_expert_system'))
			elif self.query_one('#installer_screen').current == 'installer_screen_expert':
				for tree in self.installer_screen_expert_trees.values():
					if tree.cursor_node is not None and tree.cursor_node.data is not None:
						self.installer_execute_command(tree.cursor_node.id, tree.cursor_node.data, tree.cursor_node.data)
				self.installer_btn.label = _("Abort")


	def installer_queue_command(self, id, command, title=None) -> None:
		if self.installer_cmd.command is None:
			self.installer_execute_command(id, command, title)
		else:
			self.installer_cmd_queue.append({'id': id, 'command': command, 'title': title})


	def installer_execute_command(self, id, command, title=None) -> None:
		command = os.path.expandvars(command)
		if self.installer_cmd.command is not None:
			self.notify(f"BUG: an installer command is currently still running (this shouldn't have happened)")
			return
		if title is None:
			title = command
		executable, *arguments = command.split(' ', 1)
		if os.path.isfile(executable) is True:
			self.installer_btn.label = _("Abort")
			self.installer_cmd.command = command
			self.installer_cmd.command_id = id
			self.installer_cmd.border_title = _("Command execution: {title}").format(title=title)
			self.installer_cmd.start()
			self.installer_cmd_timer = self.installer_cmd.set_interval(1, self.on_installer_timer)
			self.installer_cmd.ncol = self.installer_cmd.content_size.width
			self.installer_cmd.nrow = self.installer_cmd.content_size.height
			self.installer_cmd.send_queue.put_nowait(['set_size', self.installer_cmd.nrow, self.installer_cmd.ncol])
			self.installer_cmd._screen.resize(self.installer_cmd.nrow, self.installer_cmd.ncol)
			self.set_focus(self.installer_cmd)
			if self.query_one('#installer_screen').current == 'installer_screen_expert':
				self.installer_screen_expert_trees['system'].disabled = True
				self.installer_screen_expert_trees['application'].disabled = True
		else:
			self.notify(f"BUG: command not found or not executable ('{executable}' as per '{command}')")
			if self.query_one('#installer_screen').current == 'installer_screen_wizard':
				if len(self.installer_cmd_queue) > 0:
					self.installer_screen_wizard_dialog['progress'].action_cursor_down()
					data = self.installer_cmd_queue.pop(0)
					self.installer_execute_command(data['id'], data['command'], data['title'] if 'title' in data else data['command'])
			if self.query_one('#installer_screen').current == 'installer_screen_expert':
				self.installer_screen_expert_trees['system'].disabled = False
				self.installer_screen_expert_trees['application'].disabled = False
				self.installer_btn.label = _("Command execution")
				self.set_focus(self.query_one(f'#{id}'))


	def installer_abort_command(self) -> None:
		if self.installer_cmd.command is None:
			self.notify(f"BUG: no installer command is currently running (this shouldn't have happened)")
			return
		self.installer_cmd_timer.stop()
		self.installer_cmd.stop()
		self.installer_cmd.refresh()
		self.installer_cmd.command = None
		self.installer_cmd.command_id = None
		self.installer_cmd.border_title = _("Command execution")
		self.installer_cmd_queue.clear()
		if self.query_one('#installer_screen').current == 'installer_screen_wizard':
			self.query_one('#installer_screen_wizard_dialog').current = 'installer_screen_wizard_strategy'
			self.set_focus(self.installer_screen_wizard_dialog['strategy'])
			self.installer_btn.label = _("Next")
		if self.query_one('#installer_screen').current == 'installer_screen_expert':
			self.installer_screen_expert_trees['system'].disabled = False
			self.installer_screen_expert_trees['application'].disabled = False
			self.installer_btn.label = _("Execute")


	def on_installer_timer(self) -> None:
		if self.installer_cmd.emulator is None or self.installer_cmd.emulator.pid is None or os.path.isdir(f'/proc/{self.installer_cmd.emulator.pid}/') is False:
			self.installer_cmd_timer.stop()
			self.installer_cmd_timer = None
			self.installer_cmd.stop()
			self.installer_cmd.command = None
			if self.query_one('#installer_screen').current == 'installer_screen_wizard':
				if self.installer_cmd.command_id is not None:
					option = self.installer_screen_wizard_dialog['progress'].get_option(self.installer_cmd.command_id)
					self.installer_screen_wizard_dialog['progress'].select(option)
					self.installer_cmd.command_id = None
				if len(self.installer_cmd_queue) > 0:
					self.installer_screen_wizard_dialog['progress'].action_cursor_down()
					data = self.installer_cmd_queue.pop(0)
					self.installer_execute_command(data['id'], data['command'], data['title'] if 'title' in data else data['command'])
				else:
					self.installer_cmd.border_title = _("Command execution")
					self.installer_btn.label = _("Installation finished, click (or CTRL-C) to exit installer")
					self.set_focus(self.installer_btn)
			if self.query_one('#installer_screen').current == 'installer_screen_expert':
				self.installer_screen_expert_trees['system'].disabled = False
				self.installer_screen_expert_trees['application'].disabled = False
				self.installer_btn.label = _("Execute")
				self.installer_cmd.border_title = _("Command execution")


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

