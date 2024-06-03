import os
import alsaaudio 
from textual.app import App
from textual.widget import Widget
from textual.widgets import Select

from . import Plugin

class Soundcard(Plugin):
	def __init__(self, id: str, name: str, app: App):
		super().__init__(id, name, app)

	def build(self) -> Widget:
		options = []
		cards = alsaaudio.cards()
		if os.getenv('HAL9000_SYSTEM_ID', default='') == 'raspberrypi-zero2w' and len(cards) == 1 and cards[0] == 'vc4hdmi':
			options.append(('seeed-voicecard (driver will be installed automatically)', '0'))
			default_value = '0'
		else:
			default_value = Select.BLANK
			for pos in range(0, len(cards)):
				name = cards[pos]
				value = str(pos)
				options.append((name, value))
				if name == 'HAL9000':
					default_value = value
		return Select(options, id=self.id, name=self.name, value=default_value, allow_blank=False)

