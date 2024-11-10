"""Toplevel package file for the "samvoice" Python package.

We import public types and functions here to let clients import everything they need from the
toplevel "samvoice" package.
"""

# The reciter and its support functions.
from .reciter import Reciter
from .reciter_rewrite_rules_dictionary import  (
            parse_rewrite_rules_dictionary,
            read_rewrite_rules_dictionary_from_file,
            get_default_rewrite_rules_dictionary
    )

# The SAM emulator and support classes.
from .sam_emulator import SamEmulator, SamPhonemeError

# Miscellaneous functions.
from .wav_file import write_wav_file

try:
    from .play_sound import play_sound
except ModuleNotFoundError:
    play_sound = None
