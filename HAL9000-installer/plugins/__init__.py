from typing import Union
from textual.app import App
from textual.widget import Widget

class Plugin:
	def __init__(self, id: str, name: str, app: App):
		self.id = id
		self.name = name
		self.app = app

	def build(self) -> Union[Widget, None]:
		return None

