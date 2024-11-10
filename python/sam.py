#! /usr/bin/env -S python3 -B

"""Test for SAM and (optionally) the SAM Reciter."""

import argparse
import struct
import time

from reciter import Reciter
from sam_emulator import SamEmulator, SamPhonemeError

try:
    # This import will fail if the numpy and/or sounddevice modules are not installed.
    from sound_output import play_sound
    play_sound_available = True  # pylint: disable=invalid-name
except ModuleNotFoundError:
    play_sound_available = False  # pylint: disable=invalid-name

def write_wav_file(filename: str, samples: bytes, sample_rate: int) -> None:
    """Write 1-byte unsigned samples as WAV file."""
    with open(filename, "wb") as fo:
        # Write samples as a WAV file with a 44-byte header.
        file_size = 44 + len(samples)
        audio_format = 1 # pcm
        num_channels = 1
        byte_rate = sample_rate
        bits_per_sample = 8
        bytes_per_sample = 1
        size_of_data = len(samples)
        wav_header  = struct.pack("<4sI4s4sIHHIIHH4sI",
                              b"RIFF", file_size, b"WAVE",
                              b"fmt ", 16,
                              audio_format, num_channels, sample_rate, byte_rate,
                              bytes_per_sample, bits_per_sample, b"data", size_of_data)
        fo.write(wav_header + samples)


def clamp(value, min_value, max_value):
    """Return value clamped between min_value and max_value."""
    assert min_value <= max_value
    if value <= min_value:
        return min_value
    if value >= max_value:
        return max_value
    return value


def main():
    """Run the SAM test program."""
    parser = argparse.ArgumentParser()

    parser.add_argument("--clock-frequency", default=1.79, help="6502 clock frequency, in MHz (default: 1.79 MHz)")
    parser.add_argument("--sample-rate", default=48000, help="WAV file sample rate (default: 48000 samples/s)")
    parser.add_argument("--phonemes", "-p", action="store_true", help="render phonemes without reciter step")
    parser.add_argument("--silent", "-s", action="store_true", help="do not play rendered audio samples")
    parser.add_argument("--speed", type=int, default=None, help="SAM voice speed")
    parser.add_argument("--pitch", type=int, default=None, help="SAM voice pitch")
    parser.add_argument("--wav-file",type=str,  default=None, help="WAV file to be created")
    parser.add_argument("--volume", type=float, default=-10.0, help="volume in dB relative to max (default: -10.0)")
    parser.add_argument("source_text", help="Text to render.")

    args = parser.parse_args()

    if args.phonemes:
        phonemes = args.source_text
    else:
        print("Source text ...... :", repr(args.source_text))
        reciter = Reciter()
        phonemes = reciter.to_phonemes(args.source_text)

    print("Phonemes ......... :", repr(phonemes))
    print()

    sam = SamEmulator(args.clock_frequency * 1e6, args.sample_rate)

    if args.speed is not None:
        speed = clamp(args.speed, 0, 255)
        sam.set_speed(speed)

    if args.pitch is not None:
        pitch = clamp(args.pitch, 0, 255)
        sam.set_pitch(pitch)

    print(f"Rendering speech with speed={sam.get_speed()}, pitch={sam.get_pitch()}, sample rate {args.sample_rate} Hz ...")

    t1 = time.monotonic()
    try:
        samples = sam.render_audio_samples(phonemes)
    except SamPhonemeError as exception:
        print("SAM reported a phoneme error:", exception)
        return
    t2 = time.monotonic()

    print(f"Rendered {len(samples)} audio samples in {t2-t1:.2f} seconds.")

    if args.wav_file is not None:
        print(f"Writing WAV file {args.wav_file!r}.")
        write_wav_file(args.wav_file, samples, args.sample_rate)

    if not args.silent:
        if play_sound_available:
            print("Playing audio samples.")
            play_sound(samples, args.sample_rate, args.volume)
        else:
            print("Unable to play audio samples.")
            print("Install the 'numpy' and 'sounddevice' modules to enable sound output.")


if __name__ == "__main__":
    main()
