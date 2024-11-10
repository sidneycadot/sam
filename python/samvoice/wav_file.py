"""This module provides the write_wav_file method that can write single-channel, one byte-per-sample WAV files."""

import struct

def write_wav_file(filename: str, samples: bytes, sample_rate: int) -> None:
    """Write 1-byte unsigned samples as a WAV file."""

    with open(filename, "wb") as fo:
        # Write samples as a WAV file with a 44-byte header.
        file_size = 44 + len(samples)
        audio_format = 1  # PCM
        num_channels = 1
        byte_rate = sample_rate
        bytes_per_sample = 1
        bits_per_sample = 8
        size_of_data = len(samples)

        wav_header  = struct.pack("<4sI4s4sIHHIIHH4sI",
                              b"RIFF", file_size, b"WAVE", b"fmt ", 16,
                              audio_format, num_channels, sample_rate, byte_rate,
                              bytes_per_sample, bits_per_sample, b"data", size_of_data)

        fo.write(wav_header + samples)
