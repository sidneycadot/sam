"""SAM speech synthesizer in Python.

The SAM speech synthesizer was written in 6502 assembly.

It processes SAM-style phonemes (represented as ASCII text) and renders those as sound,
by writing data to the 4-bit DAC of the first audio channel of the Atari.

A significant complication is that the code does not write the DAC samples periodically at all,
which is the expectation for modern hardware.

The number of samples written to the DAC differs per phoneme, and even within a phoneme the time
intervals between successive samples are not constant.

To cope with this, we run the SAM 6502 code in emulation and keep a precise clock count of the
6502 instructions emulated. When samples are written to the DAC (the low four bits of address
0xd201, on the Atari), we know precisely the time at which this happens, expressed in clock cycles
since the start of the program.

Thus, the process of rendering SAM phones yields a list of (clock, sample) tuples. In post-processing,
we re-sample these to a constant-frequency sample grid, so we end up with a list of samples at regular
intervals. Those samples can be then sent to a modern sound playback device.
"""

from sam_6502_code import SAM_6502_CODE

class AudioOutputDevice:

    def __init__(self):
        self.clock_offset = None
        self.samples = []
    def write_sample(self, clock: int, sample: int) -> None:
        assert 16 <= sample <= 31
        if self.clock_offset is None:
            self.clock_offset = clock
        #print("## {:10d} {:3d}".format(clock - self.clock_offset, sample))
        self.samples.append((clock - self.clock_offset, sample & 15))

class SamVirtualMachine:

    MEM_SIZE = 0x4651  # Last address of RAM, plus 1.

    def __init__(self, audio: AudioOutputDevice):
        self.audio = audio
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

        # Put the 6502 code image of SAM into the memory.
        self.mem[0x2000:0x4651] = SAM_6502_CODE

    def write_byte(self, address: int, value: int) -> None:
        assert 0 <= value <= 255
        if address == 0xd201:
            self.audio.write_sample(self.clocks, value)
        elif address in (0xd01f, 0xd20e, 0xd400, 0xd40e):
            pass
        else:
            # RAM write.
            assert address < self.MEM_SIZE
            self.mem[address] = value

    def read_byte(self, address: int) -> int:
        if address == 0x14:  # RT-clock.
            return (self.clocks // 1000) % 256
        assert address < self.MEM_SIZE
        return self.mem[address]

    def read_word(self, address: int) -> int:
        lo = self.read_byte(address)
        hi = self.read_byte(address + 1)
        return 0x100 * hi + lo

    def push_byte(self, value: int) -> None:
        assert 0 <= value <= 255
        assert 0 <= self.sp <= 255
        self.mem[0x100 + self.sp] = value
        self.sp = (self.sp - 1) & 0xff

    def pop_byte(self) -> None:
        assert 0 <= self.sp <= 255
        self.sp = (self.sp + 1) & 0xff
        return self.mem[0x100 + self.sp]

    def push_word(self, value: int) -> None:
        assert 0 <= value <= 65535
        # high byte is pushed before low byte.
        self.push_byte(value // 256) 
        self.push_byte(value  % 256)

    def pop_word(self) -> None:
        # lo byte is popped before high byte.
        lo = self.pop_byte()
        hi = self.pop_byte()
        return hi * 0x100 + lo

    def update_nz_flags(self, value: int) -> None:
        assert 0 <= value <= 255
        self.flag_z = (value == 0)
        self.flag_n = (value & 0x80) != 0

    @staticmethod
    def different_pages(u1: int, u2: int) -> bool:
        assert 0 <= u1 <= 65535
        assert 0 <= u2 <= 65535
        return (u1 // 0x100) != (u2 // 0x100)

    def branch_if(self, condition: bool) -> None:
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
        assert 0 <= value <= 255
        self.a = value
        self.update_nz_flags(value)

    def set_x_register(self, value: int) -> None:
        assert 0 <= value <= 255
        self.x = value
        self.update_nz_flags(value)

    def set_y_register(self, value: int) -> None:
        assert 0 <= value <= 255
        self.y = value
        self.update_nz_flags(value)

    def add_with_carry(self, value: int) -> None:
        assert 0 <= value <= 255
        temp = (self.a + value + self.flag_c)
        self.set_a_register(temp & 0xff)
        self.flag_c = (temp & 0x100) != 0

    def subtract_with_borrow(self, value: int) -> None:
        assert 0 <= value <= 255
        temp = self.a - value - (not self.flag_c)
        self.set_a_register(temp & 0xff)
        self.flag_c = (temp & 0x100) == 0  # carry = !borrow.

    def compare(self, register_value: int, operand: int) -> None:
        difference = (register_value - operand) & 0xff
        self.flag_c = (register_value >= operand)
        self.update_nz_flags(difference)

    def execute_instruction(self) -> None:

        instruction = self.read_byte(self.pc)
        #print("@@ [{:16d}] PC {:04x} OPC {:02x} A {:02x} X {:02x} Y {:02x} Z {:d} N {:d} C {:d}".format(
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
            case 0x24:  # bit zpage
                zp_address = self.read_byte(self.pc + 1)
                operand = self.read_byte(zp_address)
                self.flag_n = (operand & 0x80) != 0
                self.flag_z = (operand & self.a) == 0
                self.pc += 2
                self.clocks += 3
            case 0x29: #  and #imm
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
            case 0xe4:  # cpx zpage
                zp_address = self.read_byte(self.pc + 1)
                operand = self.read_byte(zp_address)
                self.compare(self.x, operand)
                self.pc += 2
                self.clocks += 3
            case 0xe5:  # sbc zpage
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

    input_clock_offset = None
    output_samples = []

    previous_clock = None
    previous_sample = None

    for (clock, sample) in samples_in:

        # take care of the input clock (make it zero-based).
        if input_clock_offset is None:
            input_clock_offset = clock
        clock -= input_clock_offset
        assert 0 <= sample <= 15

        while True:
            t_wanted = len(output_samples) / freq_out

            if t_wanted > clock / freq_in:
                break

            if t_wanted == clock / freq_in:
                output_samples.append(sample)
                continue

            assert previous_sample is not None
            output_samples.append(previous_sample)

        previous_sample = sample

    t_wanted = len(output_samples) / freq_out
    if t_wanted > clock / freq_in:
        output_samples.append(sample)

    return output_samples


def emulate_sam(phonemes: str, sam_virtual_machine_clock_frequency: float, audio_resample_rate: float) -> bytes:
    """Render English text into 8-bit sound."""

    audio = AudioOutputDevice()
    svm = SamVirtualMachine(audio)

    phonemes_encoded = phonemes.encode('ascii')[:255] + b'\x9b'

    a = 0x2014
    b = 0x2014 + len(phonemes_encoded)

    svm.mem[a:b] = phonemes_encoded

    # Perform a virtual JSR to the entry point of SAM, with return address zero.

    svm.write_byte(0x2010, 70) # speed
    svm.write_byte(0x2011, 64) # pitch

    print("** speed:", svm.read_byte(0x2010))  # default: 70
    print("** pitch:", svm.read_byte(0x2011))  # default: 64

    svm.push_word(0xffff)  # The final RTS will return to address 0.
    svm.pc = 0x2004        # SAM entry point.

    # Run the SAM virtual machine until it returns to address PC = 0.
    while svm.pc != 0:
        svm.execute_instruction()

    sam_error = svm.read_byte(0x2013)

    if sam_error != 255:
        raise ValueError("Phoneme parsing failed at offset {}.".format(sam_error))

    samples = resample(audio.samples, sam_virtual_machine_clock_frequency, audio_resample_rate)
    samples = bytes(sample * 17 for sample in samples)

    return samples
