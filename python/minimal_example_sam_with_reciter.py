#! /usr/bin/env -S python3 -B

"""Minimal working example for SAM."""

from samvoice import Reciter, SamEmulator, play_sound


def main():
    """Minimal example of using SAM with English input."""

    reciter = Reciter()
    sam = SamEmulator()

    phonemes = reciter.to_phonemes("Hello, my name is Sam. I am a speech synthesizer on a disk.")
    samples = sam.render_audio_samples(phonemes)
    play_sound(samples, 48000, -10.0)


if __name__ == "__main__":
    main()
