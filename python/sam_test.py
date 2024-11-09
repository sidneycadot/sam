#! /usr/bin/env -S python3 -B

import argparse
import struct

from reciter import Reciter
from reciter_rewrite_rules import read_reciter_rules_into_dictionary
from sam_emulator import emulate_sam

def write_wav_file(filename: str, samples: bytes, sample_rate: int) -> None:
    with open(filename, "wb") as fo:
        # Write samples as a WAV file with a 44-byte header.
        filesize = 44 + len(samples)
        audio_format = 1 # pcm
        num_channels = 1
        byte_rate = sample_rate
        bits_per_sample = 8
        bytes_per_sample = 1
        size_of_data = len(samples)
        wav_header  = struct.pack("<4sI4s4sIHHIIHH4sI",
                              b"RIFF", filesize, b"WAVE",
                              b"fmt ", 16,
                              audio_format, num_channels, sample_rate, byte_rate,
                              bytes_per_sample, bits_per_sample, b"data", size_of_data)
        fo.write(wav_header + samples)


def main():

    parser = argparse.ArgumentParser()

    parser.add_argument("--reciter-rules-file", default="reciter_rules_english.txt", help="name of reciter source-to-phoneme rules file")
    parser.add_argument("--clock-frequency", default=1.79, help="6502 clock frequency in MHz")
    parser.add_argument("--sample-rate", default=48000, help="WAV file sample rate")
    parser.add_argument("--wav-file", default="sam.wav", help="WAV file to be created")
    parser.add_argument("source_text", help="Text to render.")

    args = parser.parse_args()

    reciter_rules_dictionary = read_reciter_rules_into_dictionary(args.reciter_rules_file)
    reciter = Reciter(reciter_rules_dictionary, fix_bugs=False)

    print("source text ..................... :", repr(args.source_text))

    phonemes = reciter(args.source_text)
    print("phonemes ........................ :", repr(phonemes))

    samples = emulate_sam(phonemes, args.clock_frequency * 1e6, args.sample_rate)

    print("Number of rendered samples ...... :", len(samples))

    write_wav_file(args.wav_file, samples, args.sample_rate)

    print("WAV file name ................... :", repr(args.wav_file))


if __name__ == "__main__":
    main()
