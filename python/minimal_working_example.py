#! /usr/bin/env python3

"""Minimal working example for SAM."""

from reciter import Reciter
from sam_emulator import SamEmulator
from sound_output import play_sound


def main():
    """Minimal example of using SAM with English input."""

    reciter = Reciter()
    sam = SamEmulator()

    phonemes = reciter.to_phonemes("The quick brown fox jumps over the lazy dog.")
    samples = sam.render_audio_samples(phonemes)
    play_sound(samples, 48000, -10.0)


if __name__ == "__main__":
    main()
