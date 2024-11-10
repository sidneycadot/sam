#! /usr/bin/env python3

"""Count from zero up to a thousand."""

from samvoice import Reciter, SamEmulator, play_sound

english_numbers_to_words = {
    0: "zero",
    1: "one",
    2: "two",
    3: "three",
    4: "four",
    5: "five",
    6: "six",
    7: "seven",
    8: "eight",
    9: "nine",
    10: "ten",
    11: "eleven",
    12: "twelve",
    13: "thirteen",
    14: "fourteen",
    15: "fifteen",
    16: "sixteen",
    17: "seventeen",
    18: "eighteen",
    19: "nineteen",
    20: "twenty",
    30: "thirty",
    40: "forty",
    50: "fifty",
    60: "sixty",
    70: "seventy",
    80: "eighty",
    90: "ninety"
}

def as_english_number(n: int) -> str:
    assert 0 <= n <= 1000
    s = english_numbers_to_words.get(n)
    if s is not None:
        return s
    if n < 100:
        return "{}-{}".format(as_english_number(n - n % 10), as_english_number(n % 10))
    if n < 1000:
        if n % 100 == 0:
            return "{} hundred".format(as_english_number(n // 100))
        return "{} and {}".format(as_english_number(n - n % 100), as_english_number(n % 100))
    if n == 1000:
        return "one thousand"

def main():
    """Count in English."""

    reciter = Reciter()
    sam = SamEmulator()

    replacements = {
        "zero"  : "0",
        "one"   : "1",
        "two"   : "2",
        "three" : "3",
        "four"  : "4",
        "five"  : "5",
        "six"   : "6",
        "seven" : "7",
        "eight" : "8",
        "nine"  : "9",
        "6ty"   : "sixty",
        "7ty"   : "seventy",
        "8y"    : "eighty",
        "9ty"   : "ni'nty"
    }

    ba = bytearray()

    for k in range(85, 1001):
        english = as_english_number(k)

        reciter_input = english
        for (replacement_from, replacement_to) in replacements.items():
            reciter_input = reciter_input.replace(replacement_from, replacement_to)
        reciter_input = reciter_input + "."

        phonemes = reciter.to_phonemes(reciter_input)

        print(f"{english:20} -> {reciter_input:30} -> {phonemes:30}")
        samples = sam.render_audio_samples(phonemes)
        play_sound(samples, 48000, -10.0)
        ba.extend(samples)

    #write_wav_file("counter.wav", ba, 48000)


if __name__ == "__main__":
    main()
