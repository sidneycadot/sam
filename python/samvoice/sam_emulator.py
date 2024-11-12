"""SAM speech synthesizer in Python.

The SAM speech synthesizer was originally written in 6502 assembly. It was released for the
Apple II, Commodore 64, and Atari 8-bit computers in 1982. This module provides a cycle-exact
emulation of the Atari version of SAM.

The 6502 code processes SAM-style phonemes (represented as ASCII text) and renders them as
sound, by writing data to the 4-bit DAC of the first of the Atari's four audio channels.

A significant complication is that the 6502 code does not write DAC samples at a fixed
rate which is the way that modern hardware processes sample data.

The rate at which samples are written to the DAC differs per phoneme, and even within a
phoneme the time intervals between successive samples are not constant.

To exactly reproduce SAM's behavior, we are therefore forced to effectively emulate the
6502 code, and to keep a precise clock count of the 6502 instructions emulated. When samples
are written to the DAC (the low four bits of address 0xd201, on the Atari), we then know
precisely the time at which this happens, expressed in clock cycles since the first
instruction (at address 0x2004 in SAM).

In this way, the process of rendering SAM phonemes yields a list of (clock, sample) tuples.

In post-processing, we re-sample these to a constant-frequency sample grid, so we end up with
a list of samples at regular intervals. Those samples can be then written to a WAV file,
or passed to a modern, constant-sample-rate sound playback device.
"""

from typing import Optional

from .sam_6502_code import SAM_6502_CODE


class SamVirtualMachine:
    """The SAM Virtual Machine is a partial implementation of a 6502 CPU with some RAM memory.

    The following is a list of simplifications of the CPU implemented here relative to a
    real 6502 processor:

    * The SVM does not implement interrupts.
    * The SVM does not implement decimal mode.
    * The SVM only implements the Zero, Negative, and Carry status flags.
    * The SVM only supports the subset of 6502 opcodes needed to run SAM.
    """

    # pylint: disable=too-many-instance-attributes, superfluous-parens

    MEM_SIZE = 0x4651  # Last address of RAM, plus 1.

    def __init__(self):
        self.clocks = 0
        self.pc = 0
        self.sp = 0xff
        self.a = 0
        self.x = 0
        self.y = 0
        self.flag_n = False
        self.flag_z = True
        self.flag_c = False
        self.mem = bytearray(self.MEM_SIZE)
        self.audio_samples: list[tuple[int, int]] = []

        # Put the 6502 code image of SAM into the memory.
        self.mem[0x2000:0x4651] = SAM_6502_CODE

    def reset_audio_samples(self):
        """Reset the audio samples to an empty list.

        Note that we do not clear() the list. This is because references to the list may exist
        outside the SamVirtualMachine instance.
        """
        self.audio_samples = []

    def process_audio_sample(self, sample: int) -> None:
        """Process an incoming DAC sample, at a given moment in time."""
        assert 0 <= sample <= 15
        self.audio_samples.append((self.clocks, sample))
        # print("## {:10d} {:3d}".format(clock - self.audio_samples[0][0], sample))

    def write_byte(self, address: int, value: int) -> None:
        """Write a single byte to SVM memory."""
        assert 0 <= value <= 255
        if address == 0xd201:
            assert 16 <= value <= 31
            self.process_audio_sample(value - 16)
        elif address in (0xd01f, 0xd20e, 0xd400, 0xd40e):
            pass
        else:
            # RAM write.
            assert address < self.MEM_SIZE
            self.mem[address] = value

    def read_byte(self, address: int) -> int:
        """Read a single byte from SVM memory."""
        if address == 0x14:  # RT-clock, LSB.
            # The least significant byte of the VBLANK clock
            # is used by SAM when making a noise to indicate
            # a phoneme parsing error. The code requires that
            # this value is increasing to return.
            return (self.clocks // 30000) % 256
        assert address < self.MEM_SIZE
        return self.mem[address]

    def read_word(self, address: int) -> int:
        """Read a two-byte word from SVM memory."""
        lo = self.read_byte(address)
        hi = self.read_byte(address + 1)
        return 0x100 * hi + lo

    def push_byte(self, value: int) -> None:
        """Push a single byte onto the 6502 stack."""
        assert 0 <= value <= 255
        assert 0 <= self.sp <= 255
        self.mem[0x100 + self.sp] = value
        self.sp = (self.sp - 1) & 0xff

    def pop_byte(self) -> int:
        """Push a single byte from the 6502 stack."""
        assert 0 <= self.sp <= 255
        self.sp = (self.sp + 1) & 0xff
        return self.mem[0x100 + self.sp]

    def push_word(self, value: int) -> None:
        """Push a two-byte word onto the 6502 stack."""
        assert 0 <= value <= 65535
        self.push_byte(value // 256)
        self.push_byte(value  % 256)

    def pop_word(self) -> int:
        """Pop a two-byte word from the 6502 stack."""
        lo = self.pop_byte()
        hi = self.pop_byte()
        return hi * 0x100 + lo

    def update_nz_flags(self, value: int) -> None:
        """Update the N and Z flag based on a value."""
        assert 0 <= value <= 255
        self.flag_z = (value == 0)
        self.flag_n = (value & 0x80) != 0

    @staticmethod
    def different_pages(u1: int, u2: int) -> bool:
        """Check if two addresses are on a different page."""
        assert 0 <= u1 <= 65535
        assert 0 <= u2 <= 65535
        return (u1 // 0x100) != (u2 // 0x100)

    def branch_if(self, condition: bool) -> None:
        """Execute a "branch on condition" instruction."""
        if condition:
            # branch taken.
            displacement = self.read_byte(self.pc + 1)
            target = self.pc + 2 + displacement - (0x100 if (displacement & 0x80) else 0)
            self.clocks += 4 if self.different_pages(target, self.pc) else 3
            self.pc = target
        else:
            # branch not taken.
            self.pc += 2
            self.clocks += 2

    def set_a_register(self, value: int) -> None:
        """Set the A register and update the Z/N flags."""
        assert 0 <= value <= 255
        self.a = value
        self.update_nz_flags(value)

    def set_x_register(self, value: int) -> None:
        """Set the X register and update the Z/N flags."""
        assert 0 <= value <= 255
        self.x = value
        self.update_nz_flags(value)

    def set_y_register(self, value: int) -> None:
        """Set the Y register and update the Z/N flags."""
        assert 0 <= value <= 255
        self.y = value
        self.update_nz_flags(value)

    def add_with_carry(self, value: int) -> None:
        """Add value to accumulator and update the Z/N/C flags."""
        assert 0 <= value <= 255
        temp = (self.a + value + self.flag_c)
        self.set_a_register(temp & 0xff)
        self.flag_c = (temp & 0x100) != 0

    def subtract_with_borrow(self, value: int) -> None:
        """Subtract value from accumulator and update the Z/N/C flags."""
        assert 0 <= value <= 255
        temp = self.a - value - (not self.flag_c)
        self.set_a_register(temp & 0xff)
        self.flag_c = (temp & 0x100) == 0  # carry = !borrow.

    def compare(self, register_value: int, operand: int) -> None:
        """Compare value to accumulator and update the Z/N/C flags."""
        difference = (register_value - operand) & 0xff
        self.flag_c = (register_value >= operand)
        self.update_nz_flags(difference)

    def execute_instruction(self) -> None:
        """Execute a single instruction at the current program counter location."""

        # pylint: disable=too-many-statements

        instruction = self.read_byte(self.pc)
        # print("@@ [{:16d}] PC {:04x} OPC {:02x} A {:02x} X {:02x} Y {:02x} Z {:d} N {:d} C {:d}".format(
        #   self.clocks, self.pc, instruction, self.a, self.x, self.y, self.flag_z, self.flag_n, self.flag_c))

        match instruction:
            case 0x06:  # asl zp
                zp_address = self.read_byte(self.pc + 1)
                value = self.read_byte(zp_address)
                shift_out = (value & 0x80) != 0
                value = (value << 1) & 0xff
                self.update_nz_flags(value)
                self.flag_c = shift_out
                self.write_byte(zp_address, value)
                self.pc += 2
                self.clocks += 5
            case 0x09:  # ora #imm
                operand = self.read_byte(self.pc + 1)
                self.set_a_register(self.a | operand)
                self.pc += 2
                self.clocks += 2
            case 0x0a:  # asl a
                self.flag_c = (self.a & 0x80) != 0
                self.set_a_register((self.a << 1) & 0xff)
                self.pc += 1
                self.clocks += 2
            case 0x10:  # bpl rel
                self.branch_if(not self.flag_n)
            case 0x18:  # clc
                self.flag_c = False
                self.pc += 1
                self.clocks += 2
            case 0x19:  # ora abs,y
                base_address = self.read_word(self.pc + 1)
                abs_address = base_address + self.y
                operand = self.read_byte(abs_address)
                self.set_a_register(self.a | operand)
                self.pc += 3
                self.clocks += 5 if self.different_pages(base_address, abs_address) else 4
            case 0x20:  # jsr absolute
                self.push_word(self.pc + 2)
                self.pc = self.read_word(self.pc + 1)
                self.clocks += 6
            case 0x24:  # bit zp
                zp_address = self.read_byte(self.pc + 1)
                operand = self.read_byte(zp_address)
                self.flag_n = (operand & 0x80) != 0
                self.flag_z = (operand & self.a) == 0
                self.pc += 2
                self.clocks += 3
            case 0x29:  # and #imm
                operand = self.read_byte(self.pc + 1)
                self.set_a_register(self.a & operand)
                self.pc += 2
                self.clocks += 2
            case 0x2a:  # rol a
                shift_out = (self.a & 0x80) != 0
                self.set_a_register(((self.a << 1) | self.flag_c) & 0xff)
                self.flag_c = shift_out
                self.pc += 1
                self.clocks += 2
            case 0x30:  # bmi rel
                self.branch_if(self.flag_n)
            case 0x38:  # sec
                self.flag_c = True
                self.pc += 1
                self.clocks += 2
            case 0x49:  # eor #imm
                operand = self.read_byte(self.pc + 1)
                self.set_a_register(self.a ^ operand)
                self.pc += 2
                self.clocks += 2
            case 0x4a:  # lsr a
                shift_out = bool(self.a & 0x01)
                self.set_a_register(self.a >> 1)
                self.flag_c = shift_out
                self.pc += 1
                self.clocks += 2
            case 0x4c:  # jmp absolute
                self.pc = self.read_word(self.pc + 1)
                self.clocks += 3
            case 0x60:  # rts
                self.pc = (self.pop_word() + 1) & 0xffff
                self.clocks += 6
            case 0x65:  # adc zp
                zp_address = self.read_byte(self.pc + 1)
                operand = self.read_byte(zp_address)
                self.add_with_carry(operand)
                self.pc += 2
                self.clocks += 3
            case 0x69:  # adc #imm
                operand = self.read_byte(self.pc + 1)
                self.add_with_carry(operand)
                self.pc += 2
                self.clocks += 2
            case 0x79:  # adc abs,y
                base_address = self.read_word(self.pc + 1)
                abs_address = base_address + self.y
                operand = self.read_byte(abs_address)
                self.add_with_carry(operand)
                self.pc += 3
                self.clocks += 5 if self.different_pages(base_address, abs_address) else 4
            case 0x7d:  # adc abs,x
                base_address = self.read_word(self.pc + 1)
                abs_address = base_address + self.x
                operand = self.read_byte(abs_address)
                self.add_with_carry(operand)
                self.pc += 3
                self.clocks += 5 if self.different_pages(base_address, abs_address) else 4
            case 0x84:  # sty zp
                zp_address = self.read_byte(self.pc + 1)
                self.write_byte(zp_address, self.y)
                self.pc += 2
                self.clocks += 3
            case 0x85:  # sta zp
                zp_address = self.read_byte(self.pc + 1)
                self.write_byte(zp_address, self.a)
                self.pc += 2
                self.clocks += 3
            case 0x86:  # stx zp
                zp_address = self.read_byte(self.pc + 1)
                self.write_byte(zp_address, self.x)
                self.pc += 2
                self.clocks += 3
            case 0x88:  # dey
                self.set_y_register((self.y - 1) & 0xff)
                self.pc += 1
                self.clocks += 2
            case 0x8a:  # txa
                self.set_a_register(self.x)
                self.pc += 1
                self.clocks += 2
            case 0x8d:  # sta abs
                abs_address = self.read_word(self.pc + 1)
                self.write_byte(abs_address, self.a)
                self.pc += 3
                self.clocks += 4
            case 0x8e:  # stx abs
                abs_address = self.read_word(self.pc + 1)
                self.write_byte(abs_address, self.x)
                self.pc += 3
                self.clocks += 4
            case 0x90:  # bcc rel
                self.branch_if(not self.flag_c)
            case 0x91:  # sta (zp),y
                zp_address = self.read_byte(self.pc + 1)
                assert zp_address != 0xff
                base_address = self.read_word(zp_address)
                abs_address = base_address + self.y
                self.write_byte(abs_address, self.a)
                self.pc += 2
                self.clocks += 6
            case 0x95:  # sta zp,x
                base_address = self.read_byte(self.pc + 1)
                zp_address = base_address + self.x
                self.write_byte(zp_address, self.a)
                self.pc += 2
                self.clocks += 4
            case 0x98:  # tya
                self.set_a_register(self.y)
                self.pc += 1
                self.clocks += 2
            case 0x99:  # sta abs,y
                base_address = self.read_word(self.pc + 1)
                abs_address = base_address + self.y
                self.write_byte(abs_address, self.a)
                self.pc += 3
                self.clocks += 6 if self.different_pages(base_address, abs_address) else 5  # To be confirmed.
            case 0x9d:  # sta abs,x
                base_address = self.read_word(self.pc + 1)
                abs_address = base_address + self.x
                self.write_byte(abs_address, self.a)
                self.pc += 3
                self.clocks += 6 if self.different_pages(base_address, abs_address) else 5  # To be confirmed.
            case 0xa0:  # ldy #imm
                operand = self.read_byte(self.pc + 1)
                self.set_y_register(operand)
                self.pc += 2
                self.clocks += 2
            case 0xa2:  # ldx #imm
                operand = self.read_byte(self.pc + 1)
                self.set_x_register(operand)
                self.pc += 2
                self.clocks += 2
            case 0xa4:  # ldy zp
                zp_address = self.read_byte(self.pc + 1)
                operand = self.read_byte(zp_address)
                self.set_y_register(operand)
                self.pc += 2
                self.clocks += 3
            case 0xa5:  # lda zp
                zp_address = self.read_byte(self.pc + 1)
                operand = self.read_byte(zp_address)
                self.set_a_register(operand)
                self.pc += 2
                self.clocks += 3
            case 0xa6:  # ldx zp
                zp_address = self.read_byte(self.pc + 1)
                operand = self.read_byte(zp_address)
                self.set_x_register(operand)
                self.pc += 2
                self.clocks += 3
            case 0xa8:  # tay
                self.set_y_register(self.a)
                self.pc += 1
                self.clocks += 2
            case 0xa9:  # lda #imm
                operand = self.read_byte(self.pc + 1)
                self.set_a_register(operand)
                self.pc += 2
                self.clocks += 2
            case 0xaa:  # tax
                self.set_x_register(self.a)
                self.pc += 1
                self.clocks += 2
            case 0xad:  # lda abs
                abs_address = self.read_word(self.pc + 1)
                operand = self.read_byte(abs_address)
                self.set_a_register(operand)
                self.pc += 3
                self.clocks += 4
            case 0xae:  # ldx abs
                abs_address = self.read_word(self.pc + 1)
                operand = self.read_byte(abs_address)
                self.set_x_register(operand)
                self.pc += 3
                self.clocks += 4
            case 0xb0:  # bcs rel
                self.branch_if(self.flag_c)
            case 0xb1:  # lda (zp),y
                zp_address = self.read_byte(self.pc + 1)
                assert zp_address != 0xff
                base_address = self.read_word(zp_address)
                abs_address = base_address + self.y
                operand = self.read_byte(abs_address)
                self.set_a_register(operand)
                self.pc += 2
                self.clocks += 6 if self.different_pages(base_address, abs_address) else 5
            case 0xb5:  # lda zp,x
                zp_base_address = self.read_byte(self.pc + 1)
                zp_address = zp_base_address + self.x
                operand = self.read_byte(zp_address)
                self.set_a_register(operand)
                self.pc += 2
                self.clocks += 4
            case 0xb9:  # lda abs,y
                base_address = self.read_word(self.pc + 1)
                abs_address = base_address + self.y
                operand = self.read_byte(abs_address)
                self.set_a_register(operand)
                self.pc += 3
                self.clocks += 5 if self.different_pages(base_address, abs_address) else 4
            case 0xbc:  # ldy abs,x
                base_address = self.read_word(self.pc + 1)
                abs_address = base_address + self.x
                operand = self.read_byte(abs_address)
                self.set_y_register(operand)
                self.pc += 3
                self.clocks += 5 if self.different_pages(base_address, abs_address) else 4
            case 0xbd:  # lda abs,x
                base_address = self.read_word(self.pc + 1)
                abs_address = base_address + self.x
                operand = self.read_byte(abs_address)
                self.set_a_register(operand)
                self.pc += 3
                self.clocks += 5 if self.different_pages(base_address, abs_address) else 4
            case 0xc5:  # cmp zp
                zp_address = self.read_byte(self.pc + 1)
                operand = self.read_byte(zp_address)
                self.compare(self.a, operand)
                self.pc += 2
                self.clocks += 3
            case 0xc6:  # dec zp
                zp_address = self.read_byte(self.pc + 1)
                value = (self.read_byte(zp_address) - 1) & 0xff
                self.write_byte(zp_address, value)
                self.update_nz_flags(value)
                self.pc += 2
                self.clocks += 5
            case 0xc8:  # iny
                self.set_y_register((self.y + 1) & 0xff)
                self.pc += 1
                self.clocks += 2
            case 0xc9:  # cmp #imm
                operand = self.read_byte(self.pc + 1)
                self.compare(self.a, operand)
                self.pc += 2
                self.clocks += 2
            case 0xc0:  # cpy #imm
                operand = self.read_byte(self.pc + 1)
                self.compare(self.y, operand)
                self.pc += 2
                self.clocks += 2
            case 0xca:  # dex
                self.set_x_register((self.x - 1) & 0xff)
                self.pc += 1
                self.clocks += 2
            case 0xd0:  # bne rel
                self.branch_if(not self.flag_z)
            case 0xd9:  # cmp abs,y
                base_address = self.read_word(self.pc + 1)
                abs_address = base_address + self.y
                operand = self.read_byte(abs_address)
                self.compare(self.a, operand)
                self.pc += 3
                self.clocks += 5 if self.different_pages(base_address, abs_address) else 4
            case 0xe4:  # cpx zp
                zp_address = self.read_byte(self.pc + 1)
                operand = self.read_byte(zp_address)
                self.compare(self.x, operand)
                self.pc += 2
                self.clocks += 3
            case 0xe5:  # sbc zp
                zp_address = self.read_byte(self.pc + 1)
                operand = self.read_byte(zp_address)
                self.subtract_with_borrow(operand)
                self.pc += 2
                self.clocks += 3
            case 0xe6:  # inc zp
                zp_address = self.read_byte(self.pc + 1)
                value = (self.read_byte(zp_address) + 1) & 0xff
                self.write_byte(zp_address, value)
                self.update_nz_flags(value)
                self.pc += 2
                self.clocks += 5
            case 0xe8:  # inx
                self.set_x_register((self.x + 1) & 0xff)
                self.pc += 1
                self.clocks += 2
            case 0xe9:  # sbc #imm
                operand = self.read_byte(self.pc + 1)
                self.subtract_with_borrow(operand)
                self.pc += 2
                self.clocks += 2
            case 0xea:  # nop
                self.pc += 1
                self.clocks += 2
            case 0xf0:  # beq rel
                self.branch_if(self.flag_z)
            case 0xf1:  # sbc (zp),y
                zp_address = self.read_byte(self.pc + 1)
                assert zp_address != 0xff
                base_address = self.read_word(zp_address)
                abs_address = base_address + self.y
                operand = self.read_byte(abs_address)
                self.subtract_with_borrow(operand)
                self.pc += 2
                self.clocks += 6 if self.different_pages(base_address, abs_address) else 5
            case _:
                raise RuntimeError(f"Unhandled instruction: 0x{instruction:02x}")


def resample(samples_in: list[tuple[int, int]], freq_in: float, freq_out: float) -> list[int]:
    """Resample samples with non-periodic times onto a periodic time grid."""
    output_samples: list[int] = []

    if len(samples_in) != 0:

        # There is at least one sample to process.

        input_clock_offset = None
        previous_sample = None

        for (clock, sample) in samples_in:

            # Clock samples are translated so that the first sample is at t=0.
            if input_clock_offset is None:
                input_clock_offset = clock
            clock -= input_clock_offset

            # Generate new output samples while we can.
            while True:
                # The time for which we want to generate the next output sample.
                t_wanted = len(output_samples) / freq_out

                if t_wanted > clock / freq_in:
                    break

                if t_wanted == clock / freq_in:
                    output_samples.append(sample)
                    continue

                assert previous_sample is not None
                output_samples.append(previous_sample)

            previous_sample = sample

        # All samples have been processed.
        # Check if we will emit a last output sample to represent the very last (clock, sample) pair.
        # We know that clock and sample have been set, because the samples_in list is not empty.
        #   pylint: disable=undefined-loop-variable

        # The time for which we want to generate the next output sample.
        t_wanted = len(output_samples) / freq_out

        # Only generate this last sample if it hasn't been generated before.
        if t_wanted > clock / freq_in:
            output_samples.append(sample)

    return output_samples


class SamPhonemeError(Exception):
    """This class represents a SAM Phoneme error."""


class SamEmulator:
    """The SamEmulator class encapsulates a Sam Virtual Machine and knows how to run SAM in it."""

    # The number of clock cycles that a PAL Atari 6502 runs per second.
    # The actual clock cycle behavior of the Atari 8-bit computer is complicated.
    # The cycles where the CPU is doing work are not fully periodic, even when DMA is disabled and no interrupts are generated;
    # this is due to memory refresh cycles during which the CPU is temporarily halted. In the end, it turns out that a full screen
    # cycle corresponds to precisely 32760 CPU cycles (when DMA is disabled), and measurement on a real Atari shows that screens
    # are generated at a rate of 49.860339 screens/s. Hence, the mean CPU rate comes out as 32760 * 49.860339 == 1.633425e6 CPU cycles
    # per second.
    DEFAULT_CPU_FREQUENCY = 1.633425e6

    # The default sample rate at which to render speech.
    DEFAULT_AUDIO_SAMPLE_FREQUENCY = 48000.0

    def __init__(self, sam_virtual_machine_clock_frequency: Optional[float] = None, audio_resample_rate: Optional[float] = None):

        if sam_virtual_machine_clock_frequency is None:
            sam_virtual_machine_clock_frequency = self.DEFAULT_CPU_FREQUENCY

        if audio_resample_rate is None:
            audio_resample_rate = self.DEFAULT_AUDIO_SAMPLE_FREQUENCY

        self.sam_virtual_machine_clock_frequency = sam_virtual_machine_clock_frequency
        self.audio_resample_rate = audio_resample_rate
        self.svm = SamVirtualMachine()

    def get_speed(self) -> int:
        """Get SAM voice speed. The default value is 70."""
        return self.svm.read_byte(0x2010)

    def set_speed(self, value: int) -> None:
        """Set SAM voice speed. The default value is 70."""
        self.svm.write_byte(0x2010, value)

    def get_pitch(self) -> int:
        """Get SAM voice pitch. The default value is 64."""
        return self.svm.read_byte(0x2011)

    def set_pitch(self, value: int):
        """Set SAM voice pitch. The default value is 70."""
        self.svm.write_byte(0x2011, value)

    def render_timestamped_dac_samples(self, phonemes: str) -> list[tuple[int, int]]:
        """Render English text into 8-bit sound by emulating a 6502 and running SAM."""

        phonemes_encoded = phonemes.encode('ascii')[:255] + b'\x9b'

        first = 0x2014
        last  = 0x2014 + len(phonemes_encoded)

        self.svm.mem[first:last] = phonemes_encoded

        # Perform a virtual JSR to the entry point of SAM, with return address zero.
        # When the SAM subroutine returns, the PC will thus be set to zero, which
        # we detect in the loop below.

        self.svm.push_word(0xffff)  # The final RTS will return to address 0.
        self.svm.pc = 0x2004        # SAM entry point.

        # Verify that the SVM does not currently hold any audio samples.
        assert len(self.svm.audio_samples) == 0  # Should be empty, here.

        # Run the SAM virtual machine until it returns to address PC = 0.
        while self.svm.pc != 0:
            self.svm.execute_instruction()

        sam_error = self.svm.read_byte(0x2013)

        if sam_error != 255:
            raise SamPhonemeError(f"Phoneme parsing failed at offset {sam_error}.")

        samples = self.svm.audio_samples
        self.svm.reset_audio_samples()

        return samples

    def render_audio_samples(self, phonemes: str) -> bytes:
        """Render phonemes as 8-bit audio samples."""

        timestamped_dac_samples = self.render_timestamped_dac_samples(phonemes)

        resampled_samples = resample(timestamped_dac_samples, self.sam_virtual_machine_clock_frequency, self.audio_resample_rate)

        # We multiply each of the 0..15 samples by 17, to scale them to 0, 17, 34, ..., 255.
        return bytes(sample * 17 for sample in resampled_samples)
