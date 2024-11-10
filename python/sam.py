#! /usr/bin/env -S python3 -B

"""Test for SAM and (optionally) the SAM Reciter."""

import sys
import argparse
import time

from samvoice import Reciter, SamEmulator, SamPhonemeError, write_wav_file, play_sound


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

    # pylint: disable=too-many-branches, too-many-statements

    parser = argparse.ArgumentParser()

    parser.add_argument("--clock-frequency", default=1.79, help="6502 clock frequency, in MHz (default: 1.79 MHz)")
    parser.add_argument("--sample-rate", default=48000, help="WAV file sample rate (default: 48000 samples/s)")
    parser.add_argument("--phonemes", "-p", action="store_true", help="render phonemes directly (disable reciter)")
    parser.add_argument("--silent", "-s", action="store_true", help="do not play rendered audio samples")
    parser.add_argument("--speed", type=int, default=None, help="SAM voice speed")
    parser.add_argument("--pitch", type=int, default=None, help="SAM voice pitch")
    parser.add_argument("--wav-file",type=str,  default=None, help="WAV file to be created")
    parser.add_argument("--volume", type=float, default=-10.0, help="volume in dB relative to max (default: -10.0)")
    parser.add_argument("--noprint", dest="use_stdout", action="store_false",
                        help="do not produce output on stdout")
    parser.add_argument("source_text", metavar="<text-or-phonemes>",
                        help="source text (or phonemes, if the -p flag is used) to render as sound")

    args = parser.parse_args()

    if args.phonemes:
        phonemes = args.source_text
    else:
        if args.use_stdout:
            print("Source text ...... :", repr(args.source_text))
        reciter = Reciter()
        phonemes = reciter.to_phonemes(args.source_text)

    if args.use_stdout:
        print("Phonemes ......... :", repr(phonemes))
        print()

    sam = SamEmulator(args.clock_frequency * 1e6, args.sample_rate)

    if args.speed is not None:
        speed = clamp(args.speed, 0, 255)
        sam.set_speed(speed)

    if args.pitch is not None:
        pitch = clamp(args.pitch, 0, 255)
        sam.set_pitch(pitch)

    if args.use_stdout:
        print(f"Rendering speech with speed={sam.get_speed()}, pitch={sam.get_pitch()}, sample rate {args.sample_rate} Hz ...")

    t1 = time.monotonic()
    try:
        samples = sam.render_audio_samples(phonemes)
    except SamPhonemeError as exception:
        print("SAM reported a phoneme error:", exception, file=sys.stderr)
        return
    t2 = time.monotonic()

    if args.use_stdout:

        audio_duration = len(samples) / args.sample_rate
        render_time = t2 - t1
        realtime_factor = audio_duration / render_time

        print(f"Rendered {len(samples)} audio samples ({audio_duration:.2f} seconds) "
              f"in {t2-t1:.2f} seconds ({realtime_factor:.2f}x realtime).")
        print()

    if args.wav_file is not None:
        if args.use_stdout:
            print(f"Writing WAV file {args.wav_file!r}.")
        write_wav_file(args.wav_file, samples, args.sample_rate)

    if not args.silent:
        if play_sound.available:
            if args.use_stdout:
                print("Playing audio samples.")
            play_sound(samples, args.sample_rate, args.volume)
        else:
            print("Unable to play audio samples.", file=sys.stderr)
            print("Install the 'numpy' and 'sounddevice' modules to enable sound output.", file=sys.stderr)


if __name__ == "__main__":
    main()
