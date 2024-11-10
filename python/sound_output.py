"""Play sound using Python's sounddevice module."""

import numpy as np
import sounddevice as sd

def play_sound(samples: bytes, samplerate: float, volume_db: float) -> None:
    """Play sound samples"""
    np_samples = np.frombuffer(samples, dtype=np.uint8)

    np_samples = np_samples.astype(np.float32) / 127.5 - 1.0

    if volume_db is None:
        volume_db = 0.0

    if volume_db != 0.0:
        signal_multiplier = 10.0 ** (volume_db / 20.0)
        np_samples *= signal_multiplier

    sd.play(np_samples, samplerate)
    sd.wait()
