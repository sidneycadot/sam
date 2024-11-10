"""Play sound using Python's sounddevice module."""

from typing import Optional

import numpy as np
import sounddevice

def play_sound(samples: bytes, sample_rate: float, volume_db: Optional[float] = None) -> None:
    """Play sound samples"""
    np_samples = np.frombuffer(samples, dtype=np.uint8).astype(np.float32) / 127.5 - 1.0

    if volume_db is None:
        volume_db = 0.0

    if volume_db != 0.0:
        signal_multiplier = 10.0 ** (volume_db / 20.0)
        np_samples *= signal_multiplier

    sounddevice.play(np_samples, sample_rate)
    sounddevice.wait()
