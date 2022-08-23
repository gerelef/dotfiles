import os
import multiprocessing as mp
from evdev import InputDevice, categorize, ecodes
from abc import ABC
from enum import Enum
from typing import Callable

# https://stackoverflow.com/questions/71121522/turn-py-file-to-an-appimage

# cat /proc/bus/input/devices  | highlight sysrq
#  https://old.reddit.com/r/linux/comments/8geyru/diy_linux_macro_board/
# https://python-evdev.readthedocs.io/en/latest/usage.html#accessing-event-codes


class Physical(Enum):
    KEY_UP = 0
    KEY_DOWN = 1
    KEY_HOLD = 2
    
    
class Combination:
    def __init__(self, exclusive=True, *args):
        pass
        

class Bind:
    def __init__(self, key_code, action: Callable,
                        repeat=False, interval=80):
        self.key = key_code
        self.action = action
        self.repeat = repeat
        self.interval = interval # in millisecond


class Keyboard:
    def __init__(self, dev1ce: InputDevice):
        self.dev = dev1ce
    
    def main(self):
        self.dev.grab()
        for event in self.dev.read_loop():
            #print(f"EVENT: {event}\n\tTYPE: {event.type}")
            if event.type == ecodes.EV_KEY:
                print(f"EVENT: {event}\n\tTYPE: {event.type}")
                key = categorize(event)
                print(f"KEY: {key}\n\tSTATE: {key.keystate}\n\tCODE: {key.keycode}")
                if key.keystate == key.key_down:
                    if key.keycode == 'KEY_ESC':
                        os.system('echo Hello World')
                
if __name__ == "__main__":
    macroboard = Keyboard(InputDevice('/dev/input/event25'))
    macroboard_extra = Keyboard(InputDevice('/dev/input/event26'))
    # https://docs.python.org/3.8/library/multiprocessing.html#the-process-class
    mb  = mp.Process(target=macroboard.main)
    mbe = mp.Process(target=macroboard_extra.main)
    mb.start()
    mbe.start()
    mb.join()
    mbe.join()
    
