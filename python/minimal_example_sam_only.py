#! /usr/bin/env -S python3 -B

"""Minimal working example for SAM, without the Reciter."""

from samvoice import SamEmulator, play_sound


def main():
    """Minimal example of using SAM with English input."""

    sam = SamEmulator()

    phonemes = "/HEH3LOW. MAY3 NEYM IHZ SAE4M. AY3 AEM AH  SPIY4CH SIH4NTHAHSAYZER-AA5N AH DIH2SK."
    samples = sam.render_audio_samples(phonemes)
    play_sound(samples, 48000, -10.0)


if __name__ == "__main__":
    main()
