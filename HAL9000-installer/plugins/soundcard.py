import os
import alsaaudio 
from typing import Union
from textual.app import App
from textual.widget import Widget
from textual.widgets import Select

from . import Plugin

class Soundcard(Plugin):
	def __init__(self, id: str, name: str, app: App):
		super().__init__(id, name, app)

	def build(self) -> Union[Widget, None]:
		options = []
		options_default = Select.BLANK
		cards = alsaaudio.cards()
		if os.getenv('HAL9000_SYSTEM_ID', default='') == 'raspberrypi-zero2w' and len(cards) == 1 and cards[0] == 'vc4hdmi':
			options_default = 'seeed2micvoicec'
			options.append(('ReSpeaker 2-Mic (driver will be installed automatically)', options_default))
		else:
			for id in cards:
				options.append((id, id))
		return Select(options, id=self.id, name=self.name, value=options_default, allow_blank=False)

