#! /usr/bin/env python3

import sys
import time

S = 0xff
A = 0
X = 0
Y = 0
N = False
Z = True
C = False
PC = 0

mem = bytearray(0x10000)
filename="data/sam_2000_4650.bin"
with open(filename, "rb") as fi:
    mem[0x2000:0x4651] = fi.read()

first_clock = None

def different_pages(u1: int, u2: int) -> bool:
    """Check if two addresses are on a different page."""
    assert 0 <= u1 <= 65535
    assert 0 <= u2 <= 65535
    return (u1 // 0x100) != (u2 // 0x100)

def read_byte(address: int) -> int:

    ok = False

    if address == 0x10:
        ok = True

    if address == 0xcd:
        ok = True

    if 0x0e1 <= address <= 0xff:
        ok = True

    if address == 0x2013:
        ok = True

    if 0x2010 <= address <= 0x2012:
        ok = True

    if 0x2014 <= address <= 0x2113:
        ok = True

    if 0x2262 <= address <= 0x2361:
        ok = True

    if 0x2362 <= address <= 0x2461:
        ok = True

    if 0x2462 <= address <= 0x2561:
        ok = True

    if 0x2564 <= address <= 0x256a:
        ok = True

    if 0x256c <= address <= 0x25bc:
        ok = True

    if 0x25bd <= address <= 0x260d:
        ok = True

    if 0x260e <= address <= 0x26a9:
        ok = True

    if 0x2a50 <= address <= 0x2a6e:
        ok = True

    if 0x2b00 <= address <=  0x2bff:
        ok = True

    if 0x2c00 <= address <=  0x2cff:
        ok = True

    if 0x2d00 <= address <=  0x2dff:
        ok = True

    if 0x2e00 <= address <=  0x2eff:
        ok = True

    if 0x2f00 <= address <=  0x34ff:
        ok = True

    if 0x3500 <= address <= 0x39bf:
        ok = True

    #0x39C0 .. 0x3EBF
    if 0x39cf <= address <= 0x3ebf:
        ok = True

    if 0x3ec0 <= address <= 0x3efb:
        ok = True

    if 0x3efc <= address <= 0x3f37:
        ok = True

    if 0x3f38 <= address <= 0x3f73:
        ok = True

    # 0x3F74 .. 0x3F83 (Gain)
    if 0x3f74 <= address <= 0x3f83:
        ok = True

    # 0x3F84 .. 0x3F8E
    if 0x3f85 <= address <= 0x3f87:
        ok = True

    # 0x3F84 .. 0x3F8E
    if 0x3f88 <= address <= 0x3f8a:
        ok = True

    #0x4331 .. 0x4335
    if 0x4331 <= address <= 0x4334:
        ok = True

    if address == 0x43a9:
        ok = True

    if not ok:
        raise RuntimeError("Bad read address: 0x{:04x}".format(address))

    return mem[address]

def write_byte(address: int, value: int) -> None:
    global clocks, first_clock
    assert 0 <= address <= 0xffff
    assert 0 <= value <= 0xff

    if address in (0xd20e, 0xd400, 0xd40e):
        return

    if address == 0xd201:
        assert 0 <= value <= 31
        sample = value & 15
        if first_clock is None:
            first_clock = clocks
        print("## {:10d} {:3d}".format(clocks - first_clock, sample))
        return

    ok = False

    if address == 0xcd:
        ok = True

    if 0xe1 <= address <= address <= 0xff:
        ok = True

    if address == 0x2013:
        ok = True

    if 0x2a50 <= address <= 0x2a6e:
        ok = True

    if 0x2262 <= address <= 0x2361:
        ok = True

    if 0x2362 <= address <= 0x2461:
        ok = True

    if 0x2462 <= address <= 0x2561:
        ok = True

    if 0x2f00 <= address <=  0x2fff:
        ok = True

    if 0x2e00 <= address <=  0x2eff:
        ok = True

    if 0x3000 <= address <=  0x35ff:
        ok = True

    if 0x3ec0 <= address <= 0x3efb:
        ok = True

    if 0x3efc <= address <= 0x3f37:
        ok = True

    if 0x3f38 <= address <= 0x3f73:
        ok = True

    if address == 0x43a9:
        ok = True

    # Self-modyfying code addresses
    if address in (0x403f, 0x4210, 0x421f, 0x42b0, 0x42df):
        ok = True

    if not ok:
        raise RuntimeError("Bad write address: 0x{:04x}".format(address))

    mem[address] = value


def read_word(address: int) -> int:
    return read_byte(address) + read_byte(address + 1) * 0x100


def push_byte(value: int) -> None:
    """Push a single byte onto the 6502 stack."""
    global S
    assert 0 <= value <= 255
    assert 0 <= S <= 255
    mem[0x100 + S] = value
    S = (S - 1) & 0xff

def pop_byte() -> int:
    """Push a single byte from the 6502 stack."""
    global S
    assert 0 <= S <= 255
    S = (S + 1) & 0xff
    return mem[0x100 + S]

def push_word(value: int) -> None:
    """Push a two-byte word onto the 6502 stack."""
    assert 0 <= value <= 65535
    push_byte(value // 256)
    push_byte(value  % 256)

def pop_word() -> int:
    """Pop a two-byte word from the 6502 stack."""
    lo = pop_byte()
    hi = pop_byte()
    return hi * 0x100 + lo

def update_nz_flags(value: int):
    global N
    global Z
    assert 0 <= value <= 255
    N = value >= 0x80
    Z = (value == 0)

def set_a_register(value: int):
    global A
    assert 0 <= value <= 255
    A = value
    update_nz_flags(A)

def set_x_register(value: int):
    global X
    assert 0 <= value <= 255
    X = value
    update_nz_flags(X)

def set_y_register(value: int):
    global Y
    assert 0 <= value <= 255
    Y = value
    update_nz_flags(Y)

def compare(register_value: int, operand: int) -> None:
    """Compare value to accumulator and update the Z/N/C flags."""
    global C
    difference = (register_value - operand) & 0xff
    C = (register_value >= operand)
    update_nz_flags(difference)

def subtract_with_borrow(value: int) -> None:
    """Subtract value from accumulator and update the Z/N/C flags."""
    global A, C
    assert 0 <= value <= 255
    temp = A - value - (not C)
    set_a_register(temp & 0xff)
    C = (temp & 0x100) == 0  # carry = !borrow.

def add_with_carry(value: int) -> None:
    """Add value to accumulator and update the Z/N/C flags."""
    global A, C
    assert 0 <= value <= 255
    temp = (A + value + C)
    set_a_register(temp & 0xff)
    C = (temp & 0x100) != 0

def report_cpu_state():
    global A, X, Y, Z, N, C, S, PC, clocks
    print("@@ [{:16d}] PC {:04x} OPC {:02x} A {:02x} X {:02x} Y {:02x} Z {:d} N {:d} C {:d}".format(clocks, PC, mem[PC], A, X, Y, Z, N, C))

def sam():
    global A, X, Y, Z, N, C, S, PC, clocks
    A = 0
    X = 0
    Y = 0
    Z = True
    N = False
    C = False
    S = 0xff
    PC = 0x2004
    clocks = 0
    push_word(0xffff)

    while PC != 0:

        report_cpu_state()

        match PC:

            # ------------------------------ Machine language entry point.

            # 2004: 4C 1C 21    JMP $211C

            case 0x2004:
                PC = 0x211c
                clocks += 3

            # ------------------------------ RUN_SAM_FROM_MACHINE_LANGUAGE

            # 211C: 20 C0 3F    JSR $3FC0

            case 0x211c:

                push_word(PC + 2)
                PC = 0x3fc0
                clocks += 6

            # ------------------------------ SAM_SAY_PHONEMES

            case 0x211f:
                # 211F: A9 FF       LDA #$FF
                set_a_register(0xff)
                PC += 2
                clocks += 2

                report_cpu_state()

                # 2121: 8D 13 20    STA $2013
                write_byte(0x2013, A)
                PC += 3
                clocks += 4
            case 0x2124:
                # 2124: 20 EA 26    JSR $26EA
                push_word(PC + 2)
                PC = 0x26ea
                clocks += 6
            case 0x2127:
                # 2127: AD 13 20    LDA $2013
                operand = read_byte(0x2013)
                set_a_register(operand)
                PC += 3
                clocks += 4
            case 0x212a:
                # 212A: C9 FF       CMP #$FF
                compare(A, 0xff)
                PC += 2
                clocks += 2
            case 0x212c:
                # 212C: D0 7B       BNE $21A9
                if not Z:
                    PC = 0x21a9
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x212e:
                # 212E: 20 37 28    JSR $2837
                push_word(PC + 2)
                PC = 0x2837
                clocks += 6
            case 0x2131:
                # 2131: 20 1D 2A    JSR $2A1D
                push_word(PC + 2)
                PC = 0x2a1d
                clocks += 6
            case 0x2134:
                # 2134: 20 75 27    JSR $2775
                push_word(PC + 2)
                PC = 0x2775
                clocks += 6
            case 0x2137:
                # 2137: 20 F2 43    JSR $43F2
                push_word(PC + 2)
                PC = 0x43f2
                clocks += 6
            case 0x213a:
                # 213A: 20 9A 27    JSR $279A
                push_word(PC + 2)
                PC = 0x279a
                clocks += 6
            case 0x213d:
                # 213D: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x213f:
                # 213F: 8D 0E D4    STA $D40E
                write_byte(0xd40e, A)
                PC += 3
                clocks += 4
            case 0x2142:
                # 2142: 8D 0E D2    STA $D20E
                write_byte(0xd20e, A)
                PC += 3
                clocks += 4
            case 0x2145:
                # 2145: AD 12 20    LDA $2012
                operand = read_byte(0x2012)
                set_a_register(operand)
                PC += 3
                clocks += 4
            case 0x2148:
                # 2148: F0 1A       BEQ $2164
                if Z:
                    PC = 0x2164
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x214a:
                # 214A: A9 01       LDA #$01
                set_a_register(0x01)
                PC += 2
                clocks += 2
            case 0x214c:
                # 214C: 8D DF 42    STA $42DF
                write_byte(0x42df, A)
                PC += 3
                clocks += 4
            case 0x214f:
                # 214F: 8D 10 42    STA $4210
                write_byte(0x4210, A)
                PC += 3
                clocks += 4
            case 0x2152:
                # 2152: 8D B0 42    STA $42B0
                write_byte(0x42b0, A)
                PC += 3
                clocks += 4
            case 0x2155:
                # 2155: AD 0F 20    LDA $200F
                operand = read_byte(0x200f)
                set_a_register(operand)
                PC += 3
                clocks += 4
            case 0x2158:
                # 2158: 8D 3F 40    STA $403F
                write_byte(0x403f, A)
                PC += 3
                clocks += 4
            case 0x215b:
                # 215B: AD 0E 20    LDA $200E
                operand = read_byte(0x200e)
                set_a_register(operand)
                PC += 3
                clocks += 4
            case 0x215e:
                # 215E: 8D 1F 42    STA $421F
                write_byte(0x421f, A)
                PC += 3
                clocks += 4
            case 0x2161:
                # 2161: 4C 84 21    JMP $2184
                PC = 0x2184
                clocks += 3
            case 0x2164:
                # 2164: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x2166:
                # 2166: 8D 00 D4    STA $D400
                write_byte(0xd400, A)
                PC += 3
                clocks += 4
            case 0x2169:
                # 2169: A9 10       LDA #$10
                set_a_register(0x10)
                PC += 2
                clocks += 2
            case 0x216b:
                # 216B: 8D 10 42    STA $4210
                write_byte(0x4210, A)
                PC += 3
                clocks += 4
            case 0x216e:
                # 216E: A9 0D       LDA #$0D
                set_a_register(0x0d)
                PC += 2
                clocks += 2
            case 0x2170:
                # 2170: 8D B0 42    STA $42B0
                write_byte(0x42b0, A)
                PC += 3
                clocks += 4
            case 0x2173:
                # 2173: A9 0C       LDA #$0C
                set_a_register(0x0c)
                PC += 2
                clocks += 2
            case 0x2175:
                # 2175: 8D DF 42    STA $42DF
                write_byte(0x42df, A)
                PC += 3
                clocks += 4
            case 0x2178:
                # 2178: AD 11 20    LDA $2011
                operand = read_byte(0x2011)
                set_a_register(operand)
                PC += 3
                clocks += 4
            case 0x217b:
                # 217B: 8D 3F 40    STA $403F
                write_byte(0x403f, A)
                PC += 3
                clocks += 4
            case 0x217e:
                # 217E: AD 10 20    LDA $2010
                operand = read_byte(0x2010)
                set_a_register(operand)
                PC += 3
                clocks += 4
            case 0x2181:
                # 2181: 8D 1F 42    STA $421F
                write_byte(0x421f, A)
                PC += 3
                clocks += 4
            case 0x2184:
                # 2184: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2187:
                # 2187: C9 50       CMP #$50
                compare(A, 0x50)
                PC += 2
                clocks += 2
            case 0x2189:
                # 2189: B0 05       BCS $2190
                if C:
                    PC = 0x2190
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x218b:
                # 218B: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x218c:
                # 218C: D0 F6       BNE $2184
                if not Z:
                    PC = 0x2184
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x218e:
                # 218E: F0 05       BEQ $2195
                if Z:
                    PC = 0x2195
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2190:
                # 2190: A9 FF       LDA #$FF
                set_a_register(0xff)
                PC += 2
                clocks += 2
            case 0x2192:
                # 2192: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2195:
                # 2195: 20 36 43    JSR $4336
                push_word(PC + 2)
                PC = 0x4336
                clocks += 6
            case 0x2198:
                # 2198: A9 FF       LDA #$FF
                set_a_register(0xff)
                PC += 2
                clocks += 2
            case 0x219a:
                # 219A: 8D 60 23    STA $2360
                write_byte(0x2360, A)
                PC += 3
                clocks += 4
            case 0x219d:
                # 219D: 20 AA 43    JSR $43AA
                push_word(PC + 2)
                PC = 0x43aa
                clocks += 6
            case 0x21a0:
                # 21A0: A2 00       LDX #$00
                set_x_register(0x00)
                PC += 2
                clocks += 2
            case 0x21a2:
                # 21A2: E4 CD       CPX $CD
                operand = read_byte(0xcd)
                compare(X, operand)
                PC += 2
                clocks += 3
            case 0x21a4:
                # 21A4: 86 CD       STX $CD
                write_byte(0x00cd, X)
                PC += 2
                clocks += 3
            case 0x21a6:
                # 21A6: F0 01       BEQ $21A9
                if Z:
                    PC = 0x21a9
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x21a8:
                # 21A8: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x21a9:
                # 21A9: 20 CB 3F    JSR $3FCB
                push_word(PC + 2)
                PC = 0x3fcb
                clocks += 6
            case 0x21ac:
                # 21AC: A9 FF       LDA #$FF
                set_a_register(0xff)
                PC += 2
                clocks += 2
            case 0x21ae:
                # 21AE: 8D 0E D4    STA $D40E
                write_byte(0xd40e, A)
                PC += 3
                clocks += 4
            case 0x21b1:
                # 21B1: A5 10       LDA $10
                operand = read_byte(0x10)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x21b3:
                # 21B3: 8D 0E D2    STA $D20E
                write_byte(0xd20e, A)
                PC += 3
                clocks += 4
            case 0x21b6:
                # 21B6: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6

            # ------------------------------ SUB_SAVE_AXY

                # 26AA: 85 FC       STA $FC
                # 26AC: 86 FB       STX $FB
                # 26AE: 84 FA       STY $FA
                # 26B0: 0x60        RTS

            case 0x26aa:

                write_byte(0x00fc, A)
                PC += 2
                clocks += 3

                report_cpu_state()

                write_byte(0x00fb, X)
                PC += 2
                clocks += 3

                report_cpu_state()

                write_byte(0x00fa, Y)
                PC += 2
                clocks += 3

                report_cpu_state()

                PC = (pop_word() + 1) & 0xffff
                clocks += 6

            # ------------------------------ SUB_RESTORE_AXY

                # 26B1: A5 FC       LDA $FC
                # 26B3: A6 FB       LDX $FB
                # 26B5: A4 FA       LDY $FA
                # 26B7: 0x60        RTS

            case 0x26b1:
                operand = read_byte(0xfc)
                set_a_register(operand)
                PC += 2
                clocks += 3

                report_cpu_state()

                operand = read_byte(0xfb)
                set_x_register(operand)
                PC += 2
                clocks += 3

                report_cpu_state()

                operand = read_byte(0xfa)
                set_y_register(operand)
                PC += 2
                clocks += 3

                report_cpu_state()

                PC = (pop_word() + 1) & 0xffff
                clocks += 6

            # ------------------------------ INSERT_PHONEME

            case 0x26b8:
                # 26B8: 20 AA 26    JSR $26AA
                push_word(PC + 2)
                PC = 0x26aa
                clocks += 6
            case 0x26bb:
                # 26BB: A2 FF       LDX #$FF
                set_x_register(0xff)
                PC += 2
                clocks += 2
            case 0x26bd:
                # 26BD: A0 00       LDY #$00
                set_y_register(0x00)
                PC += 2
                clocks += 2
            case 0x26bf:
                # 26BF: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x26c0:
                # 26C0: 0x88        DEY
                set_y_register((Y - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x26c1:
                # 26C1: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x26c4:
                # 26C4: 99 62 22    STA $2262,y
                abs_address = 0x2262 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x26c7:
                # 26C7: BD 62 23    LDA $2362,x
                abs_address = 0x2362 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2362) else 4
            case 0x26ca:
                # 26CA: 99 62 23    STA $2362,y
                abs_address = 0x2362 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x26cd:
                # 26CD: BD 62 24    LDA $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x26d0:
                # 26D0: 99 62 24    STA $2462,y
                abs_address = 0x2462 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x26d3:
                # 26D3: E4 F6       CPX $F6
                operand = read_byte(0xf6)
                compare(X, operand)
                PC += 2
                clocks += 3
            case 0x26d5:
                # 26D5: D0 E8       BNE $26BF
                if not Z:
                    PC = 0x26bf
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x26d7:
                # 26D7: A5 F9       LDA $F9
                operand = read_byte(0xf9)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x26d9:
                # 26D9: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x26dc:
                # 26DC: A5 F8       LDA $F8
                operand = read_byte(0xf8)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x26de:
                # 26DE: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x26e1:
                # 26E1: A5 F7       LDA $F7
                operand = read_byte(0xf7)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x26e3:
                # 26E3: 9D 62 24    STA $2462,x
                abs_address = 0x2462 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x26e6:
                # 26E6: 20 B1 26    JSR $26B1
                push_word(PC + 2)
                PC = 0x26b1
                clocks += 6
            case 0x26e9:
                # 26E9: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6

            # ------------------------------ PREP_1_PARSE_ASCII_PHONEMES

            case 0x26ea:
                # 26EA: A2 00       LDX #$00
                set_x_register(0x00)
                PC += 2
                clocks += 2

                report_cpu_state()

                # 26EC: 0x8A        TXA
                set_a_register(X)
                PC += 1
                clocks += 2

                report_cpu_state()

                # 26ED: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2

                report_cpu_state()

                # 26EE: 85 FF       STA $FF
                write_byte(0x00ff, A)
                PC += 2
                clocks += 3

            case 0x26f0:

                # 26F0: 99 62 24    STA $2462,y
                abs_address = 0x2462 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.

                report_cpu_state()

                # 26F3: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2

                report_cpu_state()

                # 26F4: C0 FF       CPY #$FF
                compare(Y, 0xff)
                PC += 2
                clocks += 2

                report_cpu_state()

                # 26F6: D0 F8       BNE $26F0
                if not Z:
                    PC = 0x26f0
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2

            case 0x26f8:
                # 26F8: BD 14 20    LDA $2014,x
                abs_address = 0x2014 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2014) else 4
            case 0x26fb:
                # 26FB: C9 9B       CMP #$9B
                compare(A, 0x9b)
                PC += 2
                clocks += 2
            case 0x26fd:
                # 26FD: F0 6E       BEQ $276D
                if Z:
                    PC = 0x276d
                    clocks += 4
                else:
                    PC += 2
                    clocks += 2
            case 0x26ff:
                # 26FF: 85 FE       STA $FE
                write_byte(0x00fe, A)
                PC += 2
                clocks += 3
            case 0x2701:
                # 2701: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2702:
                # 2702: BD 14 20    LDA $2014,x
                abs_address = 0x2014 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2014) else 4
            case 0x2705:
                # 2705: 85 FD       STA $FD
                write_byte(0x00fd, A)
                PC += 2
                clocks += 3
            case 0x2707:
                # 2707: A0 00       LDY #$00
                set_y_register(0x00)
                PC += 2
                clocks += 2
            case 0x2709:
                # 2709: B9 6C 25    LDA $256C,y
                abs_address = 0x256c + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x256c) else 4
            case 0x270c:
                # 270C: C5 FE       CMP $FE
                operand = read_byte(0xfe)
                compare(A, operand)
                PC += 2
                clocks += 3
            case 0x270e:
                # 270E: D0 0B       BNE $271B
                if not Z:
                    PC = 0x271b
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2710:
                # 2710: B9 BD 25    LDA $25BD,y
                abs_address = 0x25bd + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x25bd) else 4
            case 0x2713:
                # 2713: C9 2A       CMP #$2A
                compare(A, 0x2a)
                PC += 2
                clocks += 2
            case 0x2715:
                # 2715: F0 04       BEQ $271B
                if Z:
                    PC = 0x271b
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2717:
                # 2717: C5 FD       CMP $FD
                operand = read_byte(0xfd)
                compare(A, operand)
                PC += 2
                clocks += 3
            case 0x2719:
                # 2719: F0 07       BEQ $2722
                if Z:
                    PC = 0x2722
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x271b:
                # 271B: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x271c:
                # 271C: C0 51       CPY #$51
                compare(Y, 0x51)
                PC += 2
                clocks += 2
            case 0x271e:
                # 271E: D0 E9       BNE $2709
                if not Z:
                    PC = 0x2709
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2720:
                # 2720: F0 0C       BEQ $272E
                if Z:
                    PC = 0x272e
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2722:
                # 2722: 0x98        TYA
                set_a_register(Y)
                PC += 1
                clocks += 2
            case 0x2723:
                # 2723: A4 FF       LDY $FF
                operand = read_byte(0xff)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x2725:
                # 2725: 99 62 22    STA $2262,y
                abs_address = 0x2262 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2728:
                # 2728: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x272a:
                # 272A: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x272b:
                # 272B: 4C F8 26    JMP $26F8
                PC = 0x26f8
                clocks += 3
            case 0x272e:
                # 272E: A0 00       LDY #$00
                set_y_register(0x00)
                PC += 2
                clocks += 2
            case 0x2730:
                # 2730: B9 BD 25    LDA $25BD,y
                abs_address = 0x25bd + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x25bd) else 4
            case 0x2733:
                # 2733: C9 2A       CMP #$2A
                compare(A, 0x2a)
                PC += 2
                clocks += 2
            case 0x2735:
                # 2735: D0 07       BNE $273E
                if not Z:
                    PC = 0x273e
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2737:
                # 2737: B9 6C 25    LDA $256C,y
                abs_address = 0x256c + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x256c) else 4
            case 0x273a:
                # 273A: C5 FE       CMP $FE
                operand = read_byte(0xfe)
                compare(A, operand)
                PC += 2
                clocks += 3
            case 0x273c:
                # 273C: F0 07       BEQ $2745
                if Z:
                    PC = 0x2745
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x273e:
                # 273E: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x273f:
                # 273F: C0 51       CPY #$51
                compare(Y, 0x51)
                PC += 2
                clocks += 2
            case 0x2741:
                # 2741: D0 ED       BNE $2730
                if not Z:
                    PC = 0x2730
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2743:
                # 2743: F0 0B       BEQ $2750
                if Z:
                    PC = 0x2750
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2745:
                # 2745: 0x98        TYA
                set_a_register(Y)
                PC += 1
                clocks += 2
            case 0x2746:
                # 2746: A4 FF       LDY $FF
                operand = read_byte(0xff)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x2748:
                # 2748: 99 62 22    STA $2262,y
                abs_address = 0x2262 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x274b:
                # 274B: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x274d:
                # 274D: 4C F8 26    JMP $26F8
                PC = 0x26f8
                clocks += 3
            case 0x2750:
                # 2750: A5 FE       LDA $FE
                operand = read_byte(0xfe)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x2752:
                # 2752: A0 08       LDY #$08
                set_y_register(0x08)
                PC += 2
                clocks += 2
            case 0x2754:
                # 2754: D9 62 25    CMP $2562,y
                abs_address = 0x2562 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                compare(A, operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2562) else 4
            case 0x2757:
                # 2757: F0 0A       BEQ $2763
                if Z:
                    PC = 0x2763
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2759:
                # 2759: 0x88        DEY
                set_y_register((Y - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x275a:
                # 275A: D0 F8       BNE $2754
                if not Z:
                    PC = 0x2754
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x275c:
                # 275C: 8E 13 20    STX $2013
                write_byte(0x2013, X)
                PC += 3
                clocks += 4
            case 0x275f:
                # 275F: 20 2D 45    JSR $452D
                push_word(PC + 2)
                PC = 0x452d
                clocks += 6
            case 0x2762:
                # 2762: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x2763:
                # 2763: 0x98        TYA
                set_a_register(Y)
                PC += 1
                clocks += 2
            case 0x2764:
                # 2764: A4 FF       LDY $FF
                operand = read_byte(0xff)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x2766:
                # 2766: 0x88        DEY
                set_y_register((Y - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2767:
                # 2767: 99 62 24    STA $2462,y
                abs_address = 0x2462 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x276a:
                # 276A: 4C F8 26    JMP $26F8
                PC = 0x26f8
                clocks += 3
            case 0x276d:
                # 276D: A9 FF       LDA #$FF
                set_a_register(0xff)
                PC += 2
                clocks += 2
            case 0x276f:
                # 276F: A4 FF       LDY $FF
                operand = read_byte(0xff)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x2771:
                # 2771: 99 62 22    STA $2262,y
                abs_address = 0x2262 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2774:
                # 2774: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x2775:
                # 2775: A0 00       LDY #$00
                set_y_register(0x00)
                PC += 2
                clocks += 2
            case 0x2777:
                # 2777: B9 62 22    LDA $2262,y
                abs_address = 0x2262 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x277a:
                # 277A: C9 FF       CMP #$FF
                compare(A, 0xff)
                PC += 2
                clocks += 2
            case 0x277c:
                # 277C: F0 1B       BEQ $2799
                if Z:
                    PC = 0x2799
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x277e:
                # 277E: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x277f:
                # 277F: B9 62 24    LDA $2462,y
                abs_address = 0x2462 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x2782:
                # 2782: F0 0B       BEQ $278F
                if Z:
                    PC = 0x278f
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2784:
                # 2784: 30 09       BMI $278F
                if N:
                    PC = 0x278f
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2786:
                # 2786: BD E0 37    LDA $37E0,x
                abs_address = 0x37e0 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x37e0) else 4
            case 0x2789:
                # 2789: 99 62 23    STA $2362,y
                abs_address = 0x2362 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x278c:
                # 278C: 4C 95 27    JMP $2795
                PC = 0x2795
                clocks += 3
            case 0x278f:
                # 278F: BD 30 38    LDA $3830,x
                abs_address = 0x3830 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3830) else 4
            case 0x2792:
                # 2792: 99 62 23    STA $2362,y
                abs_address = 0x2362 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2795:
                # 2795: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2796:
                # 2796: 4C 77 27    JMP $2777
                PC = 0x2777
                clocks += 3
            case 0x2799:
                # 2799: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x279a:
                # 279A: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x279c:
                # 279C: 85 FF       STA $FF
                write_byte(0x00ff, A)
                PC += 2
                clocks += 3
            case 0x279e:
                # 279E: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x27a0:
                # 27A0: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x27a3:
                # 27A3: C9 FF       CMP #$FF
                compare(A, 0xff)
                PC += 2
                clocks += 2
            case 0x27a5:
                # 27A5: D0 01       BNE $27A8
                if not Z:
                    PC = 0x27a8
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x27a7:
                # 27A7: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x27a8:
                # 27A8: 85 F9       STA $F9
                write_byte(0x00f9, A)
                PC += 2
                clocks += 3
            case 0x27aa:
                # 27AA: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x27ab:
                # 27AB: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x27ae:
                # 27AE: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x27af:
                # 27AF: 29 02       AND #$02
                set_a_register(A & 0x02)
                PC += 2
                clocks += 2
            case 0x27b1:
                # 27B1: D0 05       BNE $27B8
                if not Z:
                    PC = 0x27b8
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x27b3:
                # 27B3: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x27b5:
                # 27B5: 4C 9E 27    JMP $279E
                PC = 0x279e
                clocks += 3
            case 0x27b8:
                # 27B8: 0x98        TYA
                set_a_register(Y)
                PC += 1
                clocks += 2
            case 0x27b9:
                # 27B9: 29 01       AND #$01
                set_a_register(A & 0x01)
                PC += 2
                clocks += 2
            case 0x27bb:
                # 27BB: D0 2C       BNE $27E9
                if not Z:
                    PC = 0x27e9
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x27bd:
                # 27BD: E6 F9       INC $F9
                operand = read_byte(0xf9)
                value = (operand + 1) & 0xff
                write_byte(0xf9, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x27bf:
                # 27BF: A4 F9       LDY $F9
                operand = read_byte(0xf9)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x27c1:
                # 27C1: BD 62 24    LDA $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x27c4:
                # 27C4: 85 F7       STA $F7
                write_byte(0x00f7, A)
                PC += 2
                clocks += 3
            case 0x27c6:
                # 27C6: B9 30 38    LDA $3830,y
                abs_address = 0x3830 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3830) else 4
            case 0x27c9:
                # 27C9: 85 F8       STA $F8
                write_byte(0x00f8, A)
                PC += 2
                clocks += 3
            case 0x27cb:
                # 27CB: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x27cc:
                # 27CC: 86 F6       STX $F6
                write_byte(0x00f6, X)
                PC += 2
                clocks += 3
            case 0x27ce:
                # 27CE: 20 B8 26    JSR $26B8
                push_word(PC + 2)
                PC = 0x26b8
                clocks += 6
            case 0x27d1:
                # 27D1: E6 F9       INC $F9
                operand = read_byte(0xf9)
                value = (operand + 1) & 0xff
                write_byte(0xf9, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x27d3:
                # 27D3: A4 F9       LDY $F9
                operand = read_byte(0xf9)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x27d5:
                # 27D5: B9 30 38    LDA $3830,y
                abs_address = 0x3830 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3830) else 4
            case 0x27d8:
                # 27D8: 85 F8       STA $F8
                write_byte(0x00f8, A)
                PC += 2
                clocks += 3
            case 0x27da:
                # 27DA: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x27db:
                # 27DB: 86 F6       STX $F6
                write_byte(0x00f6, X)
                PC += 2
                clocks += 3
            case 0x27dd:
                # 27DD: 20 B8 26    JSR $26B8
                push_word(PC + 2)
                PC = 0x26b8
                clocks += 6
            case 0x27e0:
                # 27E0: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x27e2:
                # 27E2: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x27e4:
                # 27E4: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x27e6:
                # 27E6: 4C 9E 27    JMP $279E
                PC = 0x279e
                clocks += 3
            case 0x27e9:
                # 27E9: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x27ea:
                # 27EA: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x27ed:
                # 27ED: F0 FA       BEQ $27E9
                if Z:
                    PC = 0x27e9
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x27ef:
                # 27EF: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x27f1:
                # 27F1: C9 FF       CMP #$FF
                compare(A, 0xff)
                PC += 2
                clocks += 2
            case 0x27f3:
                # 27F3: D0 03       BNE $27F8
                if not Z:
                    PC = 0x27f8
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x27f5:
                # 27F5: 4C 0A 28    JMP $280A
                PC = 0x280a
                clocks += 3
            case 0x27f8:
                # 27F8: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x27f9:
                # 27F9: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x27fc:
                # 27FC: 29 08       AND #$08
                set_a_register(A & 0x08)
                PC += 2
                clocks += 2
            case 0x27fe:
                # 27FE: D0 32       BNE $2832
                if not Z:
                    PC = 0x2832
                    clocks += 4
                else:
                    PC += 2
                    clocks += 2
            case 0x2800:
                # 2800: A5 F5       LDA $F5
                operand = read_byte(0xf5)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x2802:
                # 2802: C9 24       CMP #$24
                compare(A, 0x24)
                PC += 2
                clocks += 2
            case 0x2804:
                # 2804: F0 2C       BEQ $2832
                if Z:
                    PC = 0x2832
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2806:
                # 2806: C9 25       CMP #$25
                compare(A, 0x25)
                PC += 2
                clocks += 2
            case 0x2808:
                # 2808: F0 28       BEQ $2832
                if Z:
                    PC = 0x2832
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x280a:
                # 280A: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x280c:
                # 280C: BD 62 24    LDA $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x280f:
                # 280F: 85 F7       STA $F7
                write_byte(0x00f7, A)
                PC += 2
                clocks += 3
            case 0x2811:
                # 2811: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2812:
                # 2812: 86 F6       STX $F6
                write_byte(0x00f6, X)
                PC += 2
                clocks += 3
            case 0x2814:
                # 2814: A6 F9       LDX $F9
                operand = read_byte(0xf9)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x2816:
                # 2816: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2817:
                # 2817: 86 F9       STX $F9
                write_byte(0x00f9, X)
                PC += 2
                clocks += 3
            case 0x2819:
                # 2819: BD 30 38    LDA $3830,x
                abs_address = 0x3830 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3830) else 4
            case 0x281c:
                # 281C: 85 F8       STA $F8
                write_byte(0x00f8, A)
                PC += 2
                clocks += 3
            case 0x281e:
                # 281E: 20 B8 26    JSR $26B8
                push_word(PC + 2)
                PC = 0x26b8
                clocks += 6
            case 0x2821:
                # 2821: E6 F6       INC $F6
                operand = read_byte(0xf6)
                value = (operand + 1) & 0xff
                write_byte(0xf6, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x2823:
                # 2823: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2824:
                # 2824: 86 F9       STX $F9
                write_byte(0x00f9, X)
                PC += 2
                clocks += 3
            case 0x2826:
                # 2826: BD 30 38    LDA $3830,x
                abs_address = 0x3830 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3830) else 4
            case 0x2829:
                # 2829: 85 F8       STA $F8
                write_byte(0x00f8, A)
                PC += 2
                clocks += 3
            case 0x282b:
                # 282B: 20 B8 26    JSR $26B8
                push_word(PC + 2)
                PC = 0x26b8
                clocks += 6
            case 0x282e:
                # 282E: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x2830:
                # 2830: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x2832:
                # 2832: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x2834:
                # 2834: 4C 9E 27    JMP $279E
                PC = 0x279e
                clocks += 3
            case 0x2837:
                # 2837: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x2839:
                # 2839: 85 FF       STA $FF
                write_byte(0x00ff, A)
                PC += 2
                clocks += 3
            case 0x283b:
                # 283B: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x283d:
                # 283D: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2840:
                # 2840: D0 05       BNE $2847
                if not Z:
                    PC = 0x2847
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2842:
                # 2842: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x2844:
                # 2844: 4C 3B 28    JMP $283B
                PC = 0x283b
                clocks += 3
            case 0x2847:
                # 2847: C9 FF       CMP #$FF
                compare(A, 0xff)
                PC += 2
                clocks += 2
            case 0x2849:
                # 2849: D0 01       BNE $284C
                if not Z:
                    PC = 0x284c
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x284b:
                # 284B: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x284c:
                # 284C: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x284d:
                # 284D: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x2850:
                # 2850: 29 10       AND #$10
                set_a_register(A & 0x10)
                PC += 2
                clocks += 2
            case 0x2852:
                # 2852: F0 1F       BEQ $2873
                if Z:
                    PC = 0x2873
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2854:
                # 2854: BD 62 24    LDA $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x2857:
                # 2857: 85 F7       STA $F7
                write_byte(0x00f7, A)
                PC += 2
                clocks += 3
            case 0x2859:
                # 2859: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x285a:
                # 285A: 86 F6       STX $F6
                write_byte(0x00f6, X)
                PC += 2
                clocks += 3
            case 0x285c:
                # 285C: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x285f:
                # 285F: 29 20       AND #$20
                set_a_register(A & 0x20)
                PC += 2
                clocks += 2
            case 0x2861:
                # 2861: F0 0C       BEQ $286F
                if Z:
                    PC = 0x286f
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2863:
                # 2863: A9 15       LDA #$15
                set_a_register(0x15)
                PC += 2
                clocks += 2
            case 0x2865:
                # 2865: 85 F9       STA $F9
                write_byte(0x00f9, A)
                PC += 2
                clocks += 3
            case 0x2867:
                # 2867: 20 B8 26    JSR $26B8
                push_word(PC + 2)
                PC = 0x26b8
                clocks += 6
            case 0x286a:
                # 286A: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x286c:
                # 286C: 4C 97 29    JMP $2997
                PC = 0x2997
                clocks += 3
            case 0x286f:
                # 286F: A9 14       LDA #$14
                set_a_register(0x14)
                PC += 2
                clocks += 2
            case 0x2871:
                # 2871: D0 F2       BNE $2865
                if not Z:
                    PC = 0x2865
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2873:
                # 2873: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2876:
                # 2876: C9 4E       CMP #$4E
                compare(A, 0x4e)
                PC += 2
                clocks += 2
            case 0x2878:
                # 2878: D0 17       BNE $2891
                if not Z:
                    PC = 0x2891
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x287a:
                # 287A: A9 18       LDA #$18
                set_a_register(0x18)
                PC += 2
                clocks += 2
            case 0x287c:
                # 287C: 85 F9       STA $F9
                write_byte(0x00f9, A)
                PC += 2
                clocks += 3
            case 0x287e:
                # 287E: BD 62 24    LDA $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x2881:
                # 2881: 85 F7       STA $F7
                write_byte(0x00f7, A)
                PC += 2
                clocks += 3
            case 0x2883:
                # 2883: A9 0D       LDA #$0D
                set_a_register(0x0d)
                PC += 2
                clocks += 2
            case 0x2885:
                # 2885: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2888:
                # 2888: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2889:
                # 2889: 86 F6       STX $F6
                write_byte(0x00f6, X)
                PC += 2
                clocks += 3
            case 0x288b:
                # 288B: 20 B8 26    JSR $26B8
                push_word(PC + 2)
                PC = 0x26b8
                clocks += 6
            case 0x288e:
                # 288E: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x2891:
                # 2891: C9 4F       CMP #$4F
                compare(A, 0x4f)
                PC += 2
                clocks += 2
            case 0x2893:
                # 2893: D0 04       BNE $2899
                if not Z:
                    PC = 0x2899
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2895:
                # 2895: A9 1B       LDA #$1B
                set_a_register(0x1b)
                PC += 2
                clocks += 2
            case 0x2897:
                # 2897: D0 E3       BNE $287C
                if not Z:
                    PC = 0x287c
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2899:
                # 2899: C9 50       CMP #$50
                compare(A, 0x50)
                PC += 2
                clocks += 2
            case 0x289b:
                # 289B: D0 04       BNE $28A1
                if not Z:
                    PC = 0x28a1
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x289d:
                # 289D: A9 1C       LDA #$1C
                set_a_register(0x1c)
                PC += 2
                clocks += 2
            case 0x289f:
                # 289F: D0 DB       BNE $287C
                if not Z:
                    PC = 0x287c
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x28a1:
                # 28A1: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x28a2:
                # 28A2: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x28a5:
                # 28A5: 29 80       AND #$80
                set_a_register(A & 0x80)
                PC += 2
                clocks += 2
            case 0x28a7:
                # 28A7: F0 2B       BEQ $28D4
                if Z:
                    PC = 0x28d4
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x28a9:
                # 28A9: BD 62 24    LDA $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x28ac:
                # 28AC: F0 26       BEQ $28D4
                if Z:
                    PC = 0x28d4
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x28ae:
                # 28AE: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x28af:
                # 28AF: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x28b2:
                # 28B2: D0 20       BNE $28D4
                if not Z:
                    PC = 0x28d4
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x28b4:
                # 28B4: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x28b5:
                # 28B5: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x28b8:
                # 28B8: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x28bb:
                # 28BB: 29 80       AND #$80
                set_a_register(A & 0x80)
                PC += 2
                clocks += 2
            case 0x28bd:
                # 28BD: F0 15       BEQ $28D4
                if Z:
                    PC = 0x28d4
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x28bf:
                # 28BF: BD 62 24    LDA $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x28c2:
                # 28C2: F0 10       BEQ $28D4
                if Z:
                    PC = 0x28d4
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x28c4:
                # 28C4: 86 F6       STX $F6
                write_byte(0x00f6, X)
                PC += 2
                clocks += 3
            case 0x28c6:
                # 28C6: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x28c8:
                # 28C8: 85 F7       STA $F7
                write_byte(0x00f7, A)
                PC += 2
                clocks += 3
            case 0x28ca:
                # 28CA: A9 1F       LDA #$1F
                set_a_register(0x1f)
                PC += 2
                clocks += 2
            case 0x28cc:
                # 28CC: 85 F9       STA $F9
                write_byte(0x00f9, A)
                PC += 2
                clocks += 3
            case 0x28ce:
                # 28CE: 20 B8 26    JSR $26B8
                push_word(PC + 2)
                PC = 0x26b8
                clocks += 6
            case 0x28d1:
                # 28D1: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x28d4:
                # 28D4: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x28d6:
                # 28D6: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x28d9:
                # 28D9: C9 17       CMP #$17
                compare(A, 0x17)
                PC += 2
                clocks += 2
            case 0x28db:
                # 28DB: D0 30       BNE $290D
                if not Z:
                    PC = 0x290d
                    clocks += 4
                else:
                    PC += 2
                    clocks += 2
            case 0x28dd:
                # 28DD: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x28de:
                # 28DE: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x28e1:
                # 28E1: C9 45       CMP #$45
                compare(A, 0x45)
                PC += 2
                clocks += 2
            case 0x28e3:
                # 28E3: D0 08       BNE $28ED
                if not Z:
                    PC = 0x28ed
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x28e5:
                # 28E5: A9 2A       LDA #$2A
                set_a_register(0x2a)
                PC += 2
                clocks += 2
            case 0x28e7:
                # 28E7: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x28ea:
                # 28EA: 4C B5 29    JMP $29B5
                PC = 0x29b5
                clocks += 3
            case 0x28ed:
                # 28ED: C9 39       CMP #$39
                compare(A, 0x39)
                PC += 2
                clocks += 2
            case 0x28ef:
                # 28EF: D0 08       BNE $28F9
                if not Z:
                    PC = 0x28f9
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x28f1:
                # 28F1: A9 2C       LDA #$2C
                set_a_register(0x2c)
                PC += 2
                clocks += 2
            case 0x28f3:
                # 28F3: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x28f6:
                # 28F6: 4C BE 29    JMP $29BE
                PC = 0x29be
                clocks += 3
            case 0x28f9:
                # 28F9: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x28fa:
                # 28FA: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x28fb:
                # 28FB: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x28fe:
                # 28FE: 29 80       AND #$80
                set_a_register(A & 0x80)
                PC += 2
                clocks += 2
            case 0x2900:
                # 2900: D0 03       BNE $2905
                if not Z:
                    PC = 0x2905
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2902:
                # 2902: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x2905:
                # 2905: A9 12       LDA #$12
                set_a_register(0x12)
                PC += 2
                clocks += 2
            case 0x2907:
                # 2907: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x290a:
                # 290A: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x290d:
                # 290D: C9 18       CMP #$18
                compare(A, 0x18)
                PC += 2
                clocks += 2
            case 0x290f:
                # 290F: D0 17       BNE $2928
                if not Z:
                    PC = 0x2928
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2911:
                # 2911: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2912:
                # 2912: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2915:
                # 2915: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2916:
                # 2916: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x2919:
                # 2919: 29 80       AND #$80
                set_a_register(A & 0x80)
                PC += 2
                clocks += 2
            case 0x291b:
                # 291B: D0 03       BNE $2920
                if not Z:
                    PC = 0x2920
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x291d:
                # 291D: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x2920:
                # 2920: A9 13       LDA #$13
                set_a_register(0x13)
                PC += 2
                clocks += 2
            case 0x2922:
                # 2922: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2925:
                # 2925: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x2928:
                # 2928: C9 20       CMP #$20
                compare(A, 0x20)
                PC += 2
                clocks += 2
            case 0x292a:
                # 292A: D0 14       BNE $2940
                if not Z:
                    PC = 0x2940
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x292c:
                # 292C: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x292d:
                # 292D: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2930:
                # 2930: C9 3C       CMP #$3C
                compare(A, 0x3c)
                PC += 2
                clocks += 2
            case 0x2932:
                # 2932: F0 03       BEQ $2937
                if Z:
                    PC = 0x2937
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2934:
                # 2934: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x2937:
                # 2937: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2938:
                # 2938: A9 26       LDA #$26
                set_a_register(0x26)
                PC += 2
                clocks += 2
            case 0x293a:
                # 293A: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x293d:
                # 293D: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x2940:
                # 2940: C9 48       CMP #$48
                compare(A, 0x48)
                PC += 2
                clocks += 2
            case 0x2942:
                # 2942: D0 17       BNE $295B
                if not Z:
                    PC = 0x295b
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2944:
                # 2944: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2945:
                # 2945: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2948:
                # 2948: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2949:
                # 2949: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x294c:
                # 294C: 29 20       AND #$20
                set_a_register(A & 0x20)
                PC += 2
                clocks += 2
            case 0x294e:
                # 294E: F0 03       BEQ $2953
                if Z:
                    PC = 0x2953
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2950:
                # 2950: 4C 76 29    JMP $2976
                PC = 0x2976
                clocks += 3
            case 0x2953:
                # 2953: A9 4B       LDA #$4B
                set_a_register(0x4b)
                PC += 2
                clocks += 2
            case 0x2955:
                # 2955: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2958:
                # 2958: 4C 76 29    JMP $2976
                PC = 0x2976
                clocks += 3
            case 0x295b:
                # 295B: C9 3C       CMP #$3C
                compare(A, 0x3c)
                PC += 2
                clocks += 2
            case 0x295d:
                # 295D: D0 17       BNE $2976
                if not Z:
                    PC = 0x2976
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x295f:
                # 295F: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2960:
                # 2960: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2963:
                # 2963: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2964:
                # 2964: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x2967:
                # 2967: 29 20       AND #$20
                set_a_register(A & 0x20)
                PC += 2
                clocks += 2
            case 0x2969:
                # 2969: F0 03       BEQ $296E
                if Z:
                    PC = 0x296e
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x296b:
                # 296B: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x296e:
                # 296E: A9 3F       LDA #$3F
                set_a_register(0x3f)
                PC += 2
                clocks += 2
            case 0x2970:
                # 2970: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2973:
                # 2973: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x2976:
                # 2976: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2979:
                # 2979: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x297c:
                # 297C: 29 01       AND #$01
                set_a_register(A & 0x01)
                PC += 2
                clocks += 2
            case 0x297e:
                # 297E: F0 17       BEQ $2997
                if Z:
                    PC = 0x2997
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2980:
                # 2980: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2981:
                # 2981: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2984:
                # 2984: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2985:
                # 2985: C9 20       CMP #$20
                compare(A, 0x20)
                PC += 2
                clocks += 2
            case 0x2987:
                # 2987: F0 04       BEQ $298D
                if Z:
                    PC = 0x298d
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2989:
                # 2989: 0x98        TYA
                set_a_register(Y)
                PC += 1
                clocks += 2
            case 0x298a:
                # 298A: 4C D6 29    JMP $29D6
                PC = 0x29d6
                clocks += 3
            case 0x298d:
                # 298D: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x298e:
                # 298E: 0x98        TYA
                set_a_register(Y)
                PC += 1
                clocks += 2
            case 0x298f:
                # 298F: E9 0C       SBC #$0C
                subtract_with_borrow(0x0c)
                PC += 2
                clocks += 2
            case 0x2991:
                # 2991: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2994:
                # 2994: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x2997:
                # 2997: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x299a:
                # 299A: C9 35       CMP #$35
                compare(A, 0x35)
                PC += 2
                clocks += 2
            case 0x299c:
                # 299C: D0 17       BNE $29B5
                if not Z:
                    PC = 0x29b5
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x299e:
                # 299E: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x299f:
                # 299F: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x29a2:
                # 29A2: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x29a3:
                # 29A3: B9 5C 26    LDA $265C,y
                abs_address = 0x265c + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x265c) else 4
            case 0x29a6:
                # 29A6: 29 04       AND #$04
                set_a_register(A & 0x04)
                PC += 2
                clocks += 2
            case 0x29a8:
                # 29A8: D0 03       BNE $29AD
                if not Z:
                    PC = 0x29ad
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x29aa:
                # 29AA: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x29ad:
                # 29AD: A9 10       LDA #$10
                set_a_register(0x10)
                PC += 2
                clocks += 2
            case 0x29af:
                # 29AF: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x29b2:
                # 29B2: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x29b5:
                # 29B5: C9 2A       CMP #$2A
                compare(A, 0x2a)
                PC += 2
                clocks += 2
            case 0x29b7:
                # 29B7: D0 05       BNE $29BE
                if not Z:
                    PC = 0x29be
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x29b9:
                # 29B9: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x29ba:
                # 29BA: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x29bb:
                # 29BB: 4C C5 29    JMP $29C5
                PC = 0x29c5
                clocks += 3
            case 0x29be:
                # 29BE: C9 2C       CMP #$2C
                compare(A, 0x2c)
                PC += 2
                clocks += 2
            case 0x29c0:
                # 29C0: F0 F7       BEQ $29B9
                if Z:
                    PC = 0x29b9
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x29c2:
                # 29C2: 4C D6 29    JMP $29D6
                PC = 0x29d6
                clocks += 3
            case 0x29c5:
                # 29C5: 84 F9       STY $F9
                write_byte(0x00f9, Y)
                PC += 2
                clocks += 3
            case 0x29c7:
                # 29C7: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x29c8:
                # 29C8: 86 F6       STX $F6
                write_byte(0x00f6, X)
                PC += 2
                clocks += 3
            case 0x29ca:
                # 29CA: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x29cb:
                # 29CB: BD 62 24    LDA $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x29ce:
                # 29CE: 85 F7       STA $F7
                write_byte(0x00f7, A)
                PC += 2
                clocks += 3
            case 0x29d0:
                # 29D0: 20 B8 26    JSR $26B8
                push_word(PC + 2)
                PC = 0x26b8
                clocks += 6
            case 0x29d3:
                # 29D3: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x29d6:
                # 29D6: C9 45       CMP #$45
                compare(A, 0x45)
                PC += 2
                clocks += 2
            case 0x29d8:
                # 29D8: D0 02       BNE $29DC
                if not Z:
                    PC = 0x29dc
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x29da:
                # 29DA: F0 07       BEQ $29E3
                if Z:
                    PC = 0x29e3
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x29dc:
                # 29DC: C9 39       CMP #$39
                compare(A, 0x39)
                PC += 2
                clocks += 2
            case 0x29de:
                # 29DE: F0 03       BEQ $29E3
                if Z:
                    PC = 0x29e3
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x29e0:
                # 29E0: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x29e3:
                # 29E3: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x29e4:
                # 29E4: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x29e7:
                # 29E7: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x29e8:
                # 29E8: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x29eb:
                # 29EB: 29 80       AND #$80
                set_a_register(A & 0x80)
                PC += 2
                clocks += 2
            case 0x29ed:
                # 29ED: F0 29       BEQ $2A18
                if Z:
                    PC = 0x2a18
                    clocks += 4
                else:
                    PC += 2
                    clocks += 2
            case 0x29ef:
                # 29EF: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x29f0:
                # 29F0: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x29f3:
                # 29F3: F0 17       BEQ $2A0C
                if Z:
                    PC = 0x2a0c
                    clocks += 4
                else:
                    PC += 2
                    clocks += 2
            case 0x29f5:
                # 29F5: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x29f6:
                # 29F6: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x29f9:
                # 29F9: 29 80       AND #$80
                set_a_register(A & 0x80)
                PC += 2
                clocks += 2
            case 0x29fb:
                # 29FB: F0 1B       BEQ $2A18
                if Z:
                    PC = 0x2a18
                    clocks += 4
                else:
                    PC += 2
                    clocks += 2
            case 0x29fd:
                # 29FD: BD 62 24    LDA $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x2a00:
                # 2A00: D0 16       BNE $2A18
                if not Z:
                    PC = 0x2a18
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2a02:
                # 2A02: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x2a04:
                # 2A04: A9 1E       LDA #$1E
                set_a_register(0x1e)
                PC += 2
                clocks += 2
            case 0x2a06:
                # 2A06: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2a09:
                # 2A09: 4C 18 2A    JMP $2A18
                PC = 0x2a18
                clocks += 3
            case 0x2a0c:
                # 2A0C: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2a0d:
                # 2A0D: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2a10:
                # 2A10: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x2a11:
                # 2A11: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x2a14:
                # 2A14: 29 80       AND #$80
                set_a_register(A & 0x80)
                PC += 2
                clocks += 2
            case 0x2a16:
                # 2A16: D0 EA       BNE $2A02
                if not Z:
                    PC = 0x2a02
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2a18:
                # 2A18: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x2a1a:
                # 2A1A: 4C 3B 28    JMP $283B
                PC = 0x283b
                clocks += 3
            case 0x2a1d:
                # 2A1D: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x2a1f:
                # 2A1F: 85 FF       STA $FF
                write_byte(0x00ff, A)
                PC += 2
                clocks += 3
            case 0x2a21:
                # 2A21: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x2a23:
                # 2A23: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2a26:
                # 2A26: C0 FF       CPY #$FF
                compare(Y, 0xff)
                PC += 2
                clocks += 2
            case 0x2a28:
                # 2A28: D0 01       BNE $2A2B
                if not Z:
                    PC = 0x2a2b
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2a2a:
                # 2A2A: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x2a2b:
                # 2A2B: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x2a2e:
                # 2A2E: 29 40       AND #$40
                set_a_register(A & 0x40)
                PC += 2
                clocks += 2
            case 0x2a30:
                # 2A30: F0 18       BEQ $2A4A
                if Z:
                    PC = 0x2a4a
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2a32:
                # 2A32: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2a33:
                # 2A33: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x2a36:
                # 2A36: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x2a39:
                # 2A39: 29 80       AND #$80
                set_a_register(A & 0x80)
                PC += 2
                clocks += 2
            case 0x2a3b:
                # 2A3B: F0 0D       BEQ $2A4A
                if Z:
                    PC = 0x2a4a
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2a3d:
                # 2A3D: BC 62 24    LDY $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x2a40:
                # 2A40: F0 08       BEQ $2A4A
                if Z:
                    PC = 0x2a4a
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2a42:
                # 2A42: 30 06       BMI $2A4A
                if N:
                    PC = 0x2a4a
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x2a44:
                # 2A44: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2a45:
                # 2A45: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x2a46:
                # 2A46: 0x98        TYA
                set_a_register(Y)
                PC += 1
                clocks += 2
            case 0x2a47:
                # 2A47: 9D 62 24    STA $2462,x
                abs_address = 0x2462 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x2a4a:
                # 2A4A: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x2a4c:
                # 2A4C: 4C 21 2A    JMP $2A21
                PC = 0x2a21
                clocks += 3
            case 0x3f8f:
                # 3F8F: A0 00       LDY #$00
                set_y_register(0x00)
                PC += 2
                clocks += 2
            case 0x3f91:
                # 3F91: 24 F2       BIT $F2
                operand = read_byte(0xf2)
                N = (operand & 0x80) != 0
                Z = (operand & A) == 0
                PC += 2
                clocks += 3
            case 0x3f93:
                # 3F93: 10 09       BPL $3F9E
                if not N:
                    PC = 0x3f9e
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x3f95:
                # 3F95: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x3f96:
                # 3F96: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x3f98:
                # 3F98: E5 F2       SBC $F2
                operand = read_byte(0xf2)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 3
            case 0x3f9a:
                # 3F9A: 85 F2       STA $F2
                write_byte(0x00f2, A)
                PC += 2
                clocks += 3
            case 0x3f9c:
                # 3F9C: A0 80       LDY #$80
                set_y_register(0x80)
                PC += 2
                clocks += 2
            case 0x3f9e:
                # 3F9E: 84 EF       STY $EF
                write_byte(0x00ef, Y)
                PC += 2
                clocks += 3
            case 0x3fa0:
                # 3FA0: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x3fa2:
                # 3FA2: A2 08       LDX #$08
                set_x_register(0x08)
                PC += 2
                clocks += 2
            case 0x3fa4:
                # 3FA4: 06 F2       ASL $F2
                operand = read_byte(0xf2)
                value = (operand << 1) & 0xff
                write_byte(0xf2, value)
                update_nz_flags(value)
                C = (operand & 0x80) != 0
                PC += 2
                clocks += 5
            case 0x3fa6:
                # 3FA6: 2A C5       ROL A
                shift_out = (A & 0x80) != 0
                set_a_register((A << 1) & 0xff | C)
                C = shift_out
                PC += 1
                clocks += 2
            case 0x3fa7:
                # 3FA7: C5 F1       CMP $F1
                operand = read_byte(0xf1)
                compare(A, operand)
                PC += 2
                clocks += 3
            case 0x3fa9:
                # 3FA9: 90 04       BCC $3FAF
                if not C:
                    PC = 0x3faf
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x3fab:
                # 3FAB: E5 F1       SBC $F1
                operand = read_byte(0xf1)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 3
            case 0x3fad:
                # 3FAD: E6 F2       INC $F2
                operand = read_byte(0xf2)
                value = (operand + 1) & 0xff
                write_byte(0xf2, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x3faf:
                # 3FAF: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x3fb0:
                # 3FB0: D0 F2       BNE $3FA4
                if not Z:
                    PC = 0x3fa4
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x3fb2:
                # 3FB2: 85 F0       STA $F0
                write_byte(0x00f0, A)
                PC += 2
                clocks += 3
            case 0x3fb4:
                # 3FB4: 24 EF       BIT $EF
                operand = read_byte(0xef)
                N = (operand & 0x80) != 0
                Z = (operand & A) == 0
                PC += 2
                clocks += 3
            case 0x3fb6:
                # 3FB6: 10 07       BPL $3FBF
                if not N:
                    PC = 0x3fbf
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x3fb8:
                # 3FB8: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x3fb9:
                # 3FB9: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x3fbb:
                # 3FBB: E5 F2       SBC $F2
                operand = read_byte(0xf2)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 3
            case 0x3fbd:
                # 3FBD: 85 F2       STA $F2
                write_byte(0x00f2, A)
                PC += 2
                clocks += 3
            case 0x3fbf:
                # 3FBF: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6

            # ------------------------------ SAM_SAVE_ZP_ADDRESSES

            case 0x3fc0:
                # 3FC0: A2 1F       LDX #$1F
                set_x_register(0x1f)
                PC += 2
                clocks += 2
            case 0x3fc2:
                # 3FC2: B5 E0       LDA $E0,x
                zp_address = 0xe0 + X
                assert zp_address <= 0xff
                operand = read_byte(zp_address)
                set_a_register(operand)
                PC += 2
                clocks += 4
            case 0x3fc4:
                # 3FC4: 9D 4F 2A    STA $2A4F,x
                abs_address = 0x2a4f + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x3fc7:
                # 3FC7: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x3fc8:
                # 3FC8: D0 F8       BNE $3FC2
                if not Z:
                    PC = 0x3fc2
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x3fca:
                # 3FCA: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6

            # ------------------------------ SAM_RESTORE_ZP_ADDRESSES

            case 0x3fcb:
                # 3FCB: A2 1F       LDX #$1F
                set_x_register(0x1f)
                PC += 2
                clocks += 2
            case 0x3fcd:
                # 3FCD: BD 4F 2A    LDA $2A4F,x
                abs_address = 0x2a4f + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2a4f) else 4
            case 0x3fd0:
                # 3FD0: 95 E0       STA $E0,x
                zp_address = 0xe0 + X
                assert zp_address <= 0xff
                write_byte(zp_address, A)
                PC += 2
                clocks += 4
            case 0x3fd2:
                # 3FD2: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x3fd3:
                # 3FD3: D0 F8       BNE $3FCD
                if not Z:
                    PC = 0x3fcd
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x3fd5:
                # 3FD5: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6

            # ------------------------------ PLAY_SAMPLES_REALTIME
            case 0x3fd6:
                # 3FD6: AD C0 3E    LDA $3EC0
                operand = read_byte(0x3ec0)
                set_a_register(operand)
                PC += 3
                clocks += 4
            case 0x3fd9:
                # 3FD9: C9 FF       CMP #$FF
                compare(A, 0xff)
                PC += 2
                clocks += 2
            case 0x3fdb:
                # 3FDB: D0 01       BNE $3FDE
                if not Z:
                    PC = 0x3fde
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x3fdd:
                # 3FDD: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x3fde:
                # 3FDE: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x3fe0:
                # 3FE0: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x3fe1:
                # 3FE1: 85 E9       STA $E9
                write_byte(0x00e9, A)
                PC += 2
                clocks += 3
            case 0x3fe3:
                # 3FE3: A4 E9       LDY $E9
                operand = read_byte(0xe9)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x3fe5:
                # 3FE5: B9 C0 3E    LDA $3EC0,y
                abs_address = 0x3ec0 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3ec0) else 4
            case 0x3fe8:
                # 3FE8: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x3fea:
                # 3FEA: C9 FF       CMP #$FF
                compare(A, 0xff)
                PC += 2
                clocks += 2
            case 0x3fec:
                # 3FEC: D0 03       BNE $3FF1
                if not Z:
                    PC = 0x3ff1
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x3fee:
                # 3FEE: 4C 4E 40    JMP $404E
                PC = 0x404e
                clocks += 3
            case 0x3ff1:
                # 3FF1: C9 01       CMP #$01
                compare(A, 0x01)
                PC += 2
                clocks += 2
            case 0x3ff3:
                # 3FF3: D0 03       BNE $3FF8
                if not Z:
                    PC = 0x3ff8
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x3ff5:
                # 3FF5: 4C F5 42    JMP $42F5
                PC = 0x42f5
                clocks += 3
            case 0x3ff8:
                # 3FF8: C9 02       CMP #$02
                compare(A, 0x02)
                PC += 2
                clocks += 2
            case 0x3ffa:
                # 3FFA: D0 03       BNE $3FFF
                if not Z:
                    PC = 0x3fff
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x3ffc:
                # 3FFC: 4C FB 42    JMP $42FB
                PC = 0x42fb
                clocks += 3
            case 0x3fff:
                # 3FFF: B9 FC 3E    LDA $3EFC,y
                abs_address = 0x3efc + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3efc) else 4
            case 0x4002:
                # 4002: 85 E8       STA $E8
                write_byte(0x00e8, A)
                PC += 2
                clocks += 3
            case 0x4004:
                # 4004: B9 38 3F    LDA $3F38,y
                abs_address = 0x3f38 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3f38) else 4
            case 0x4007:
                # 4007: 85 E7       STA $E7
                write_byte(0x00e7, A)
                PC += 2
                clocks += 3
            case 0x4009:
                # 4009: A4 E8       LDY $E8
                operand = read_byte(0xe8)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x400b:
                # 400B: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x400c:
                # 400C: B9 84 3F    LDA $3F84,y
                abs_address = 0x3f84 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3f84) else 4
            case 0x400f:
                # 400F: 85 E8       STA $E8
                write_byte(0x00e8, A)
                PC += 2
                clocks += 3
            case 0x4011:
                # 4011: A4 F5       LDY $F5
                operand = read_byte(0xf5)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x4013:
                # 4013: B9 00 36    LDA $3600,y
                abs_address = 0x3600 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3600) else 4
            case 0x4016:
                # 4016: 9D 00 2F    STA $2F00,x
                abs_address = 0x2f00 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4019:
                # 4019: B9 50 36    LDA $3650,y
                abs_address = 0x3650 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3650) else 4
            case 0x401c:
                # 401C: 9D 00 30    STA $3000,x
                abs_address = 0x3000 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x401f:
                # 401F: B9 A0 36    LDA $36A0,y
                abs_address = 0x36a0 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x36a0) else 4
            case 0x4022:
                # 4022: 9D 00 31    STA $3100,x
                abs_address = 0x3100 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4025:
                # 4025: B9 F0 36    LDA $36F0,y
                abs_address = 0x36f0 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x36f0) else 4
            case 0x4028:
                # 4028: 9D 00 32    STA $3200,x
                abs_address = 0x3200 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x402b:
                # 402B: B9 40 37    LDA $3740,y
                abs_address = 0x3740 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3740) else 4
            case 0x402e:
                # 402E: 9D 00 33    STA $3300,x
                abs_address = 0x3300 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4031:
                # 4031: B9 90 37    LDA $3790,y
                abs_address = 0x3790 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3790) else 4
            case 0x4034:
                # 4034: 9D 00 34    STA $3400,x
                abs_address = 0x3400 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4037:
                # 4037: B9 70 39    LDA $3970,y
                abs_address = 0x3970 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3970) else 4
            case 0x403a:
                # 403A: 9D 00 35    STA $3500,x
                abs_address = 0x3500 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x403d:
                # 403D: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x403e:
                # 403E: A9 40       LDA #$40
                set_a_register(0x40)
                PC += 2
                clocks += 2
            case 0x4040:
                # 4040: 65 E8       ADC $E8
                operand = read_byte(0xe8)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x4042:
                # 4042: 9D 00 2E    STA $2E00,x
                abs_address = 0x2e00 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4045:
                # 4045: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4046:
                # 4046: C6 E7       DEC $E7
                operand = read_byte(0xe7)
                value = (operand - 1) & 0xff
                write_byte(0xe7, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x4048:
                # 4048: D0 C9       BNE $4013
                if not Z:
                    PC = 0x4013
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x404a:
                # 404A: E6 E9       INC $E9
                operand = read_byte(0xe9)
                value = (operand + 1) & 0xff
                write_byte(0xe9, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x404c:
                # 404C: D0 95       BNE $3FE3
                if not Z:
                    PC = 0x3fe3
                    clocks += 4
                else:
                    PC += 2
                    clocks += 2
            case 0x404e:
                # 404E: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x4050:
                # 4050: 85 E9       STA $E9
                write_byte(0x00e9, A)
                PC += 2
                clocks += 3
            case 0x4052:
                # 4052: 85 EE       STA $EE
                write_byte(0x00ee, A)
                PC += 2
                clocks += 3
            case 0x4054:
                # 4054: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x4055:
                # 4055: BC C0 3E    LDY $3EC0,x
                abs_address = 0x3ec0 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3ec0) else 4
            case 0x4058:
                # 4058: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4059:
                # 4059: BD C0 3E    LDA $3EC0,x
                abs_address = 0x3ec0 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3ec0) else 4
            case 0x405c:
                # 405C: C9 FF       CMP #$FF
                compare(A, 0xff)
                PC += 2
                clocks += 2
            case 0x405e:
                # 405E: D0 03       BNE $4063
                if not Z:
                    PC = 0x4063
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4060:
                # 4060: 4C 62 41    JMP $4162
                PC = 0x4162
                clocks += 3
            case 0x4063:
                # 4063: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x4064:
                # 4064: BD 20 39    LDA $3920,x
                abs_address = 0x3920 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3920) else 4
            case 0x4067:
                # 4067: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x4069:
                # 4069: B9 20 39    LDA $3920,y
                abs_address = 0x3920 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3920) else 4
            case 0x406c:
                # 406C: C5 F5       CMP $F5
                operand = read_byte(0xf5)
                compare(A, operand)
                PC += 2
                clocks += 3
            case 0x406e:
                # 406E: F0 1C       BEQ $408C
                if Z:
                    PC = 0x408c
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4070:
                # 4070: 90 0D       BCC $407F
                if not C:
                    PC = 0x407f
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4072:
                # 4072: B9 80 38    LDA $3880,y
                abs_address = 0x3880 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3880) else 4
            case 0x4075:
                # 4075: 85 E8       STA $E8
                write_byte(0x00e8, A)
                PC += 2
                clocks += 3
            case 0x4077:
                # 4077: B9 D0 38    LDA $38D0,y
                abs_address = 0x38d0 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x38d0) else 4
            case 0x407a:
                # 407A: 85 E7       STA $E7
                write_byte(0x00e7, A)
                PC += 2
                clocks += 3
            case 0x407c:
                # 407C: 4C 96 40    JMP $4096
                PC = 0x4096
                clocks += 3
            case 0x407f:
                # 407F: BD D0 38    LDA $38D0,x
                abs_address = 0x38d0 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x38d0) else 4
            case 0x4082:
                # 4082: 85 E8       STA $E8
                write_byte(0x00e8, A)
                PC += 2
                clocks += 3
            case 0x4084:
                # 4084: BD 80 38    LDA $3880,x
                abs_address = 0x3880 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3880) else 4
            case 0x4087:
                # 4087: 85 E7       STA $E7
                write_byte(0x00e7, A)
                PC += 2
                clocks += 3
            case 0x4089:
                # 4089: 4C 96 40    JMP $4096
                PC = 0x4096
                clocks += 3
            case 0x408c:
                # 408C: B9 80 38    LDA $3880,y
                abs_address = 0x3880 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3880) else 4
            case 0x408f:
                # 408F: 85 E8       STA $E8
                write_byte(0x00e8, A)
                PC += 2
                clocks += 3
            case 0x4091:
                # 4091: BD 80 38    LDA $3880,x
                abs_address = 0x3880 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3880) else 4
            case 0x4094:
                # 4094: 85 E7       STA $E7
                write_byte(0x00e7, A)
                PC += 2
                clocks += 3
            case 0x4096:
                # 4096: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x4097:
                # 4097: A5 EE       LDA $EE
                operand = read_byte(0xee)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x4099:
                # 4099: A4 E9       LDY $E9
                operand = read_byte(0xe9)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x409b:
                # 409B: 79 38 3F    ADC $3F38,y
                abs_address = 0x3f38 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                add_with_carry(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3f38) else 4
            case 0x409e:
                # 409E: 85 EE       STA $EE
                write_byte(0x00ee, A)
                PC += 2
                clocks += 3
            case 0x40a0:
                # 40A0: 65 E7       ADC $E7
                operand = read_byte(0xe7)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x40a2:
                # 40A2: 85 EA       STA $EA
                write_byte(0x00ea, A)
                PC += 2
                clocks += 3
            case 0x40a4:
                # 40A4: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x40a6:
                # 40A6: 85 EB       STA $EB
                write_byte(0x00eb, A)
                PC += 2
                clocks += 3
            case 0x40a8:
                # 40A8: A9 2E       LDA #$2E
                set_a_register(0x2e)
                PC += 2
                clocks += 2
            case 0x40aa:
                # 40AA: 85 EC       STA $EC
                write_byte(0x00ec, A)
                PC += 2
                clocks += 3
            case 0x40ac:
                # 40AC: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x40ad:
                # 40AD: A5 EE       LDA $EE
                operand = read_byte(0xee)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x40af:
                # 40AF: E5 E8       SBC $E8
                operand = read_byte(0xe8)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 3
            case 0x40b1:
                # 40B1: 85 E6       STA $E6
                write_byte(0x00e6, A)
                PC += 2
                clocks += 3
            case 0x40b3:
                # 40B3: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x40b4:
                # 40B4: A5 E8       LDA $E8
                operand = read_byte(0xe8)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x40b6:
                # 40B6: 65 E7       ADC $E7
                operand = read_byte(0xe7)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x40b8:
                # 40B8: 85 E3       STA $E3
                write_byte(0x00e3, A)
                PC += 2
                clocks += 3
            case 0x40ba:
                # 40BA: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x40bb:
                # 40BB: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x40bc:
                # 40BC: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x40bd:
                # 40BD: 10 03       BPL $40C2
                if not N:
                    PC = 0x40c2
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x40bf:
                # 40BF: 4C 5B 41    JMP $415B
                PC = 0x415b
                clocks += 3
            case 0x40c2:
                # 40C2: A5 E3       LDA $E3
                operand = read_byte(0xe3)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x40c4:
                # 40C4: 85 E5       STA $E5
                write_byte(0x00e5, A)
                PC += 2
                clocks += 3
            case 0x40c6:
                # 40C6: A5 EC       LDA $EC
                operand = read_byte(0xec)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x40c8:
                # 40C8: C9 2E       CMP #$2E
                compare(A, 0x2e)
                PC += 2
                clocks += 2
            case 0x40ca:
                # 40CA: D0 3D       BNE $4109
                if not Z:
                    PC = 0x4109
                    clocks += 4
                else:
                    PC += 2
                    clocks += 2
            case 0x40cc:
                # 40CC: A4 E9       LDY $E9
                operand = read_byte(0xe9)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x40ce:
                # 40CE: B9 38 3F    LDA $3F38,y
                abs_address = 0x3f38 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3f38) else 4
            case 0x40d1:
                # 40D1: 4A 85       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x40d2:
                # 40D2: 85 E1       STA $E1
                write_byte(0x00e1, A)
                PC += 2
                clocks += 3
            case 0x40d4:
                # 40D4: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x40d5:
                # 40D5: B9 38 3F    LDA $3F38,y
                abs_address = 0x3f38 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3f38) else 4
            case 0x40d8:
                # 40D8: 4A 85       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x40d9:
                # 40D9: 85 E2       STA $E2
                write_byte(0x00e2, A)
                PC += 2
                clocks += 3
            case 0x40db:
                # 40DB: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x40dc:
                # 40DC: A5 E1       LDA $E1
                operand = read_byte(0xe1)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x40de:
                # 40DE: 65 E2       ADC $E2
                operand = read_byte(0xe2)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x40e0:
                # 40E0: 85 E5       STA $E5
                write_byte(0x00e5, A)
                PC += 2
                clocks += 3
            case 0x40e2:
                # 40E2: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x40e3:
                # 40E3: A5 EE       LDA $EE
                operand = read_byte(0xee)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x40e5:
                # 40E5: 65 E2       ADC $E2
                operand = read_byte(0xe2)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x40e7:
                # 40E7: 85 E2       STA $E2
                write_byte(0x00e2, A)
                PC += 2
                clocks += 3
            case 0x40e9:
                # 40E9: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x40ea:
                # 40EA: A5 EE       LDA $EE
                operand = read_byte(0xee)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x40ec:
                # 40EC: E5 E1       SBC $E1
                operand = read_byte(0xe1)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 3
            case 0x40ee:
                # 40EE: 85 E1       STA $E1
                write_byte(0x00e1, A)
                PC += 2
                clocks += 3
            case 0x40f0:
                # 40F0: A4 E2       LDY $E2
                operand = read_byte(0xe2)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x40f2:
                # 40F2: B1 EB       LDA ($EB),y
                assert 0x00eb < 0xff
                base_address = read_word(0x00eb)
                abs_address = base_address + Y
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 2
                clocks += 6 if different_pages(abs_address, base_address) else 5
            case 0x40f4:
                # 40F4: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x40f5:
                # 40F5: A4 E1       LDY $E1
                operand = read_byte(0xe1)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x40f7:
                # 40F7: F1 EB       SBC ($EB),y
                assert 0x00eb < 0xff
                base_address = read_word(0x00eb)
                abs_address = base_address + Y
                operand = read_byte(abs_address)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 6 if different_pages(abs_address, base_address) else 5
            case 0x40f9:
                # 40F9: 85 F2       STA $F2
                write_byte(0x00f2, A)
                PC += 2
                clocks += 3
            case 0x40fb:
                # 40FB: A5 E5       LDA $E5
                operand = read_byte(0xe5)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x40fd:
                # 40FD: 85 F1       STA $F1
                write_byte(0x00f1, A)
                PC += 2
                clocks += 3
            case 0x40ff:
                # 40FF: 20 8F 3F    JSR $3F8F
                push_word(PC + 2)
                PC = 0x3f8f
                clocks += 6
            case 0x4102:
                # 4102: A6 E5       LDX $E5
                operand = read_byte(0xe5)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x4104:
                # 4104: A4 E1       LDY $E1
                operand = read_byte(0xe1)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x4106:
                # 4106: 4C 1F 41    JMP $411F
                PC = 0x411f
                clocks += 3
            case 0x4109:
                # 4109: A4 EA       LDY $EA
                operand = read_byte(0xea)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x410b:
                # 410B: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x410c:
                # 410C: B1 EB       LDA ($EB),y
                assert 0x00eb < 0xff
                base_address = read_word(0x00eb)
                abs_address = base_address + Y
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 2
                clocks += 6 if different_pages(abs_address, base_address) else 5
            case 0x410e:
                # 410E: A4 E6       LDY $E6
                operand = read_byte(0xe6)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x4110:
                # 4110: F1 EB       SBC ($EB),y
                assert 0x00eb < 0xff
                base_address = read_word(0x00eb)
                abs_address = base_address + Y
                operand = read_byte(abs_address)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 6 if different_pages(abs_address, base_address) else 5
            case 0x4112:
                # 4112: 85 F2       STA $F2
                write_byte(0x00f2, A)
                PC += 2
                clocks += 3
            case 0x4114:
                # 4114: A5 E5       LDA $E5
                operand = read_byte(0xe5)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x4116:
                # 4116: 85 F1       STA $F1
                write_byte(0x00f1, A)
                PC += 2
                clocks += 3
            case 0x4118:
                # 4118: 20 8F 3F    JSR $3F8F
                push_word(PC + 2)
                PC = 0x3f8f
                clocks += 6
            case 0x411b:
                # 411B: A6 E5       LDX $E5
                operand = read_byte(0xe5)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x411d:
                # 411D: A4 E6       LDY $E6
                operand = read_byte(0xe6)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x411f:
                # 411F: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x4121:
                # 4121: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x4123:
                # 4123: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x4124:
                # 4124: B1 EB       LDA ($EB),y
                assert 0x00eb < 0xff
                base_address = read_word(0x00eb)
                abs_address = base_address + Y
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 2
                clocks += 6 if different_pages(abs_address, base_address) else 5
            case 0x4126:
                # 4126: 65 F2       ADC $F2
                operand = read_byte(0xf2)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x4128:
                # 4128: 85 ED       STA $ED
                write_byte(0x00ed, A)
                PC += 2
                clocks += 3
            case 0x412a:
                # 412A: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x412b:
                # 412B: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x412c:
                # 412C: F0 22       BEQ $4150
                if Z:
                    PC = 0x4150
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x412e:
                # 412E: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x412f:
                # 412F: A5 F5       LDA $F5
                operand = read_byte(0xf5)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x4131:
                # 4131: 65 F0       ADC $F0
                operand = read_byte(0xf0)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x4133:
                # 4133: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x4135:
                # 4135: C5 E5       CMP $E5
                operand = read_byte(0xe5)
                compare(A, operand)
                PC += 2
                clocks += 3
            case 0x4137:
                # 4137: 90 10       BCC $4149
                if not C:
                    PC = 0x4149
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4139:
                # 4139: A5 F5       LDA $F5
                operand = read_byte(0xf5)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x413b:
                # 413B: E5 E5       SBC $E5
                operand = read_byte(0xe5)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 3
            case 0x413d:
                # 413D: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x413f:
                # 413F: 24 EF       BIT $EF
                operand = read_byte(0xef)
                N = (operand & 0x80) != 0
                Z = (operand & A) == 0
                PC += 2
                clocks += 3
            case 0x4141:
                # 4141: 30 04       BMI $4147
                if N:
                    PC = 0x4147
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4143:
                # 4143: E6 ED       INC $ED
                operand = read_byte(0xed)
                value = (operand + 1) & 0xff
                write_byte(0xed, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x4145:
                # 4145: D0 02       BNE $4149
                if not Z:
                    PC = 0x4149
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4147:
                # 4147: C6 ED       DEC $ED
                operand = read_byte(0xed)
                value = (operand - 1) & 0xff
                write_byte(0xed, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x4149:
                # 4149: A5 ED       LDA $ED
                operand = read_byte(0xed)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x414b:
                # 414B: 91 EB       STA ($EB),y
                assert 0x00eb < 0xff
                base_address = read_word(0x00eb)
                abs_address = base_address + Y
                write_byte(abs_address, A)
                PC += 2
                clocks += 6
            case 0x414d:
                # 414D: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x414e:
                # 414E: 90 D4       BCC $4124
                if not C:
                    PC = 0x4124
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4150:
                # 4150: E6 EC       INC $EC
                operand = read_byte(0xec)
                value = (operand + 1) & 0xff
                write_byte(0xec, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x4152:
                # 4152: A5 EC       LDA $EC
                operand = read_byte(0xec)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x4154:
                # 4154: C9 35       CMP #$35
                compare(A, 0x35)
                PC += 2
                clocks += 2
            case 0x4156:
                # 4156: F0 03       BEQ $415B
                if Z:
                    PC = 0x415b
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4158:
                # 4158: 4C C2 40    JMP $40C2
                PC = 0x40c2
                clocks += 3
            case 0x415b:
                # 415B: E6 E9       INC $E9
                operand = read_byte(0xe9)
                value = (operand + 1) & 0xff
                write_byte(0xe9, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x415d:
                # 415D: A6 E9       LDX $E9
                operand = read_byte(0xe9)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x415f:
                # 415F: 4C 55 40    JMP $4055
                PC = 0x4055
                clocks += 3
            case 0x4162:
                # 4162: A5 EE       LDA $EE
                operand = read_byte(0xee)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x4164:
                # 4164: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x4165:
                # 4165: A4 E9       LDY $E9
                operand = read_byte(0xe9)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x4167:
                # 4167: 79 38 3F    ADC $3F38,y
                abs_address = 0x3f38 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                add_with_carry(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3f38) else 4
            case 0x416a:
                # 416A: 85 ED       STA $ED
                write_byte(0x00ed, A)
                PC += 2
                clocks += 3
            case 0x416c:
                # 416C: A2 00       LDX #$00
                set_x_register(0x00)
                PC += 2
                clocks += 2
            case 0x416e:
                # 416E: BD 00 2F    LDA $2F00,x
                abs_address = 0x2f00 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2f00) else 4
            case 0x4171:
                # 4171: 4A 85       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4172:
                # 4172: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x4174:
                # 4174: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x4175:
                # 4175: BD 00 2E    LDA $2E00,x
                abs_address = 0x2e00 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2e00) else 4
            case 0x4178:
                # 4178: E5 F5       SBC $F5
                operand = read_byte(0xf5)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 3
            case 0x417a:
                # 417A: 9D 00 2E    STA $2E00,x
                abs_address = 0x2e00 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x417d:
                # 417D: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x417e:
                # 417E: D0 EE       BNE $416E
                if not Z:
                    PC = 0x416e
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4180:
                # 4180: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x4182:
                # 4182: 85 E8       STA $E8
                write_byte(0x00e8, A)
                PC += 2
                clocks += 3
            case 0x4184:
                # 4184: 85 E7       STA $E7
                write_byte(0x00e7, A)
                PC += 2
                clocks += 3
            case 0x4186:
                # 4186: 85 E6       STA $E6
                write_byte(0x00e6, A)
                PC += 2
                clocks += 3
            case 0x4188:
                # 4188: 85 EE       STA $EE
                write_byte(0x00ee, A)
                PC += 2
                clocks += 3
            case 0x418a:
                # 418A: A9 48       LDA #$48
                set_a_register(0x48)
                PC += 2
                clocks += 2
            case 0x418c:
                # 418C: 85 EA       STA $EA
                write_byte(0x00ea, A)
                PC += 2
                clocks += 3
            case 0x418e:
                # 418E: A9 03       LDA #$03
                set_a_register(0x03)
                PC += 2
                clocks += 2
            case 0x4190:
                # 4190: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x4192:
                # 4192: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x4194:
                # 4194: 85 EB       STA $EB
                write_byte(0x00eb, A)
                PC += 2
                clocks += 3
            case 0x4196:
                # 4196: A9 32       LDA #$32
                set_a_register(0x32)
                PC += 2
                clocks += 2
            case 0x4198:
                # 4198: 85 EC       STA $EC
                write_byte(0x00ec, A)
                PC += 2
                clocks += 3
            case 0x419a:
                # 419A: A0 00       LDY #$00
                set_y_register(0x00)
                PC += 2
                clocks += 2
            case 0x419c:
                # 419C: B1 EB       LDA ($EB),y
                assert 0x00eb < 0xff
                base_address = read_word(0x00eb)
                abs_address = base_address + Y
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 2
                clocks += 6 if different_pages(abs_address, base_address) else 5
            case 0x419e:
                # 419E: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x419f:
                # 419F: BD 74 3F    LDA $3F74,x
                abs_address = 0x3f74 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3f74) else 4
            case 0x41a2:
                # 41A2: 91 EB       STA ($EB),y
                assert 0x00eb < 0xff
                base_address = read_word(0x00eb)
                abs_address = base_address + Y
                write_byte(abs_address, A)
                PC += 2
                clocks += 6
            case 0x41a4:
                # 41A4: 0x88        DEY
                set_y_register((Y - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x41a5:
                # 41A5: D0 F5       BNE $419C
                if not Z:
                    PC = 0x419c
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x41a7:
                # 41A7: E6 EC       INC $EC
                operand = read_byte(0xec)
                value = (operand + 1) & 0xff
                write_byte(0xec, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x41a9:
                # 41A9: C6 F5       DEC $F5
                operand = read_byte(0xf5)
                value = (operand - 1) & 0xff
                write_byte(0xf5, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x41ab:
                # 41AB: D0 ED       BNE $419A
                if not Z:
                    PC = 0x419a
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x41ad:
                # 41AD: A0 00       LDY #$00
                set_y_register(0x00)
                PC += 2
                clocks += 2
            case 0x41af:
                # 41AF: B9 00 2E    LDA $2E00,y
                abs_address = 0x2e00 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2e00) else 4
            case 0x41b2:
                # 41B2: 85 E9       STA $E9
                write_byte(0x00e9, A)
                PC += 2
                clocks += 3
            case 0x41b4:
                # 41B4: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x41b5:
                # 41B5: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x41b6:
                # 41B6: 4A 85       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x41b7:
                # 41B7: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x41b9:
                # 41B9: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x41ba:
                # 41BA: 0x8A        TXA
                set_a_register(X)
                PC += 1
                clocks += 2
            case 0x41bb:
                # 41BB: E5 F5       SBC $F5
                operand = read_byte(0xf5)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 3
            case 0x41bd:
                # 41BD: 85 E3       STA $E3
                write_byte(0x00e3, A)
                PC += 2
                clocks += 3
            case 0x41bf:
                # 41BF: 4C CE 41    JMP $41CE
                PC = 0x41ce
                clocks += 3
            case 0x41c2:
                # 41C2: 20 6A 42    JSR $426A
                push_word(PC + 2)
                PC = 0x426a
                clocks += 6
            case 0x41c5:
                # 41C5: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x41c6:
                # 41C6: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x41c7:
                # 41C7: C6 ED       DEC $ED
                operand = read_byte(0xed)
                value = (operand - 1) & 0xff
                write_byte(0xed, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x41c9:
                # 41C9: C6 ED       DEC $ED
                operand = read_byte(0xed)
                value = (operand - 1) & 0xff
                write_byte(0xed, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x41cb:
                # 41CB: 4C 1B 42    JMP $421B
                PC = 0x421b
                clocks += 3
            case 0x41ce:
                # 41CE: B9 00 35    LDA $3500,y
                abs_address = 0x3500 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3500) else 4
            case 0x41d1:
                # 41D1: 85 E4       STA $E4
                write_byte(0x00e4, A)
                PC += 2
                clocks += 3
            case 0x41d3:
                # 41D3: 29 F8       AND #$F8
                set_a_register(A & 0xf8)
                PC += 2
                clocks += 2
            case 0x41d5:
                # 41D5: D0 EB       BNE $41C2
                if not Z:
                    PC = 0x41c2
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x41d7:
                # 41D7: A6 E8       LDX $E8
                operand = read_byte(0xe8)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x41d9:
                # 41D9: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x41da:
                # 41DA: BD 00 2B    LDA $2B00,x
                abs_address = 0x2b00 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2b00) else 4
            case 0x41dd:
                # 41DD: 19 00 32    ORA $3200,y
                abs_address = 0x3200 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(A | operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3200) else 4
            case 0x41e0:
                # 41E0: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x41e1:
                # 41E1: BD 00 2D    LDA $2D00,x
                abs_address = 0x2d00 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2d00) else 4
            case 0x41e4:
                # 41E4: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x41e6:
                # 41E6: A6 E7       LDX $E7
                operand = read_byte(0xe7)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x41e8:
                # 41E8: BD 00 2B    LDA $2B00,x
                abs_address = 0x2b00 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2b00) else 4
            case 0x41eb:
                # 41EB: 19 00 33    ORA $3300,y
                abs_address = 0x3300 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(A | operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3300) else 4
            case 0x41ee:
                # 41EE: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x41ef:
                # 41EF: BD 00 2D    LDA $2D00,x
                abs_address = 0x2d00 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2d00) else 4
            case 0x41f2:
                # 41F2: 65 F5       ADC $F5
                operand = read_byte(0xf5)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x41f4:
                # 41F4: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x41f6:
                # 41F6: A6 E6       LDX $E6
                operand = read_byte(0xe6)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x41f8:
                # 41F8: BD 00 2C    LDA $2C00,x
                abs_address = 0x2c00 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2c00) else 4
            case 0x41fb:
                # 41FB: 19 00 34    ORA $3400,y
                abs_address = 0x3400 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(A | operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3400) else 4
            case 0x41fe:
                # 41FE: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x41ff:
                # 41FF: BD 00 2D    LDA $2D00,x
                abs_address = 0x2d00 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2d00) else 4
            case 0x4202:
                # 4202: 65 F5       ADC $F5
                operand = read_byte(0xf5)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x4204:
                # 4204: 69 88       ADC #$88
                add_with_carry(0x88)
                PC += 2
                clocks += 2
            case 0x4206:
                # 4206: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4207:
                # 4207: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4208:
                # 4208: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4209:
                # 4209: 4A 09       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x420a:
                # 420A: 09 10       ORA #$10
                set_a_register(A | 0x10)
                PC += 2
                clocks += 2
            case 0x420c:
                # 420C: 8D 01 D2    STA $D201
                write_byte(0xd201, A)
                PC += 3
                clocks += 4
            case 0x420f:
                # 420F: A2 10       LDX #$10
                set_x_register(0x10)
                PC += 2
                clocks += 2
            case 0x4211:
                # 4211: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4212:
                # 4212: D0 FD       BNE $4211
                if not Z:
                    PC = 0x4211
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4214:
                # 4214: C6 EA       DEC $EA
                operand = read_byte(0xea)
                value = (operand - 1) & 0xff
                write_byte(0xea, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x4216:
                # 4216: D0 0A       BNE $4222
                if not Z:
                    PC = 0x4222
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4218:
                # 4218: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4219:
                # 4219: C6 ED       DEC $ED
                operand = read_byte(0xed)
                value = (operand - 1) & 0xff
                write_byte(0xed, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x421b:
                # 421B: D0 01       BNE $421E
                if not Z:
                    PC = 0x421e
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x421d:
                # 421D: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x421e:
                # 421E: A9 46       LDA #$46
                set_a_register(0x46)
                PC += 2
                clocks += 2
            case 0x4220:
                # 4220: 85 EA       STA $EA
                write_byte(0x00ea, A)
                PC += 2
                clocks += 3
            case 0x4222:
                # 4222: C6 E9       DEC $E9
                operand = read_byte(0xe9)
                value = (operand - 1) & 0xff
                write_byte(0xe9, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x4224:
                # 4224: D0 1B       BNE $4241
                if not Z:
                    PC = 0x4241
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4226:
                # 4226: B9 00 2E    LDA $2E00,y
                abs_address = 0x2e00 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2e00) else 4
            case 0x4229:
                # 4229: 85 E9       STA $E9
                write_byte(0x00e9, A)
                PC += 2
                clocks += 3
            case 0x422b:
                # 422B: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x422c:
                # 422C: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x422d:
                # 422D: 4A 85       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x422e:
                # 422E: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x4230:
                # 4230: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x4231:
                # 4231: 0x8A        TXA
                set_a_register(X)
                PC += 1
                clocks += 2
            case 0x4232:
                # 4232: E5 F5       SBC $F5
                operand = read_byte(0xf5)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 3
            case 0x4234:
                # 4234: 85 E3       STA $E3
                write_byte(0x00e3, A)
                PC += 2
                clocks += 3
            case 0x4236:
                # 4236: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x4238:
                # 4238: 85 E8       STA $E8
                write_byte(0x00e8, A)
                PC += 2
                clocks += 3
            case 0x423a:
                # 423A: 85 E7       STA $E7
                write_byte(0x00e7, A)
                PC += 2
                clocks += 3
            case 0x423c:
                # 423C: 85 E6       STA $E6
                write_byte(0x00e6, A)
                PC += 2
                clocks += 3
            case 0x423e:
                # 423E: 4C CE 41    JMP $41CE
                PC = 0x41ce
                clocks += 3
            case 0x4241:
                # 4241: C6 E3       DEC $E3
                operand = read_byte(0xe3)
                value = (operand - 1) & 0xff
                write_byte(0xe3, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x4243:
                # 4243: D0 0A       BNE $424F
                if not Z:
                    PC = 0x424f
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4245:
                # 4245: A5 E4       LDA $E4
                operand = read_byte(0xe4)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x4247:
                # 4247: F0 06       BEQ $424F
                if Z:
                    PC = 0x424f
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4249:
                # 4249: 20 6A 42    JSR $426A
                push_word(PC + 2)
                PC = 0x426a
                clocks += 6
            case 0x424c:
                # 424C: 4C 26 42    JMP $4226
                PC = 0x4226
                clocks += 3
            case 0x424f:
                # 424F: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x4250:
                # 4250: A5 E8       LDA $E8
                operand = read_byte(0xe8)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x4252:
                # 4252: 79 00 2F    ADC $2F00,y
                abs_address = 0x2f00 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                add_with_carry(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2f00) else 4
            case 0x4255:
                # 4255: 85 E8       STA $E8
                write_byte(0x00e8, A)
                PC += 2
                clocks += 3
            case 0x4257:
                # 4257: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x4258:
                # 4258: A5 E7       LDA $E7
                operand = read_byte(0xe7)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x425a:
                # 425A: 79 00 30    ADC $3000,y
                abs_address = 0x3000 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                add_with_carry(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3000) else 4
            case 0x425d:
                # 425D: 85 E7       STA $E7
                write_byte(0x00e7, A)
                PC += 2
                clocks += 3
            case 0x425f:
                # 425F: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x4260:
                # 4260: A5 E6       LDA $E6
                operand = read_byte(0xe6)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x4262:
                # 4262: 79 00 31    ADC $3100,y
                abs_address = 0x3100 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                add_with_carry(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x3100) else 4
            case 0x4265:
                # 4265: 85 E6       STA $E6
                write_byte(0x00e6, A)
                PC += 2
                clocks += 3
            case 0x4267:
                # 4267: 4C CE 41    JMP $41CE
                PC = 0x41ce
                clocks += 3
            case 0x426a:
                # 426A: 84 EE       STY $EE
                write_byte(0x00ee, Y)
                PC += 2
                clocks += 3
            case 0x426c:
                # 426C: A5 E4       LDA $E4
                operand = read_byte(0xe4)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x426e:
                # 426E: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x426f:
                # 426F: 29 07       AND #$07
                set_a_register(A & 0x07)
                PC += 2
                clocks += 2
            case 0x4271:
                # 4271: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x4272:
                # 4272: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4273:
                # 4273: 86 F5       STX $F5
                write_byte(0x00f5, X)
                PC += 2
                clocks += 3
            case 0x4275:
                # 4275: BD 31 43    LDA $4331,x
                abs_address = 0x4331 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x4331) else 4
            case 0x4278:
                # 4278: 85 F2       STA $F2
                write_byte(0x00f2, A)
                PC += 2
                clocks += 3
            case 0x427a:
                # 427A: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x427b:
                # 427B: A9 39       LDA #$39
                set_a_register(0x39)
                PC += 2
                clocks += 2
            case 0x427d:
                # 427D: 65 F5       ADC $F5
                operand = read_byte(0xf5)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x427f:
                # 427F: 85 EC       STA $EC
                write_byte(0x00ec, A)
                PC += 2
                clocks += 3
            case 0x4281:
                # 4281: A9 C0       LDA #$C0
                set_a_register(0xc0)
                PC += 2
                clocks += 2
            case 0x4283:
                # 4283: 85 EB       STA $EB
                write_byte(0x00eb, A)
                PC += 2
                clocks += 3
            case 0x4285:
                # 4285: 0x98        TYA
                set_a_register(Y)
                PC += 1
                clocks += 2
            case 0x4286:
                # 4286: 29 F8       AND #$F8
                set_a_register(A & 0xf8)
                PC += 2
                clocks += 2
            case 0x4288:
                # 4288: D0 0C       BNE $4296
                if not Z:
                    PC = 0x4296
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x428a:
                # 428A: A4 EE       LDY $EE
                operand = read_byte(0xee)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x428c:
                # 428C: B9 00 2E    LDA $2E00,y
                abs_address = 0x2e00 + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2e00) else 4
            case 0x428f:
                # 428F: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4290:
                # 4290: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4291:
                # 4291: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4292:
                # 4292: 4A 4C       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4293:
                # 4293: 4C C2 42    JMP $42C2
                PC = 0x42c2
                clocks += 3
            case 0x4296:
                # 4296: 49 FF       EOR #$FF
                set_a_register(A ^ 0xff)
                PC += 2
                clocks += 2
            case 0x4298:
                # 4298: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x4299:
                # 4299: A9 08       LDA #$08
                set_a_register(0x08)
                PC += 2
                clocks += 2
            case 0x429b:
                # 429B: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x429d:
                # 429D: B1 EB       LDA ($EB),y
                assert 0x00eb < 0xff
                base_address = read_word(0x00eb)
                abs_address = base_address + Y
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 2
                clocks += 6 if different_pages(abs_address, base_address) else 5
            case 0x429f:
                # 429F: 0A 90       ASL A
                shift_out = (A & 0x80) != 0
                set_a_register((A << 1) & 0xff)
                C = shift_out
                PC += 1
                clocks += 2
            case 0x42a0:
                # 42A0: 90 07       BCC $42A9
                if not C:
                    PC = 0x42a9
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42a2:
                # 42A2: A6 F2       LDX $F2
                operand = read_byte(0xf2)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x42a4:
                # 42A4: 8E 01 D2    STX $D201
                write_byte(0xd201, X)
                PC += 3
                clocks += 4
            case 0x42a7:
                # 42A7: D0 06       BNE $42AF
                if not Z:
                    PC = 0x42af
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42a9:
                # 42A9: A2 15       LDX #$15
                set_x_register(0x15)
                PC += 2
                clocks += 2
            case 0x42ab:
                # 42AB: 8E 01 D2    STX $D201
                write_byte(0xd201, X)
                PC += 3
                clocks += 4
            case 0x42ae:
                # 42AE: 0xEA        NOP
                PC += 1
                clocks += 2
            case 0x42af:
                # 42AF: A2 0D       LDX #$0D
                set_x_register(0x0d)
                PC += 2
                clocks += 2
            case 0x42b1:
                # 42B1: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x42b2:
                # 42B2: D0 FD       BNE $42B1
                if not Z:
                    PC = 0x42b1
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42b4:
                # 42B4: C6 F5       DEC $F5
                operand = read_byte(0xf5)
                value = (operand - 1) & 0xff
                write_byte(0xf5, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x42b6:
                # 42B6: D0 E7       BNE $429F
                if not Z:
                    PC = 0x429f
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42b8:
                # 42B8: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x42b9:
                # 42B9: D0 DE       BNE $4299
                if not Z:
                    PC = 0x4299
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42bb:
                # 42BB: A9 01       LDA #$01
                set_a_register(0x01)
                PC += 2
                clocks += 2
            case 0x42bd:
                # 42BD: 85 E9       STA $E9
                write_byte(0x00e9, A)
                PC += 2
                clocks += 3
            case 0x42bf:
                # 42BF: A4 EE       LDY $EE
                operand = read_byte(0xee)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x42c1:
                # 42C1: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x42c2:
                # 42C2: 49 FF       EOR #$FF
                set_a_register(A ^ 0xff)
                PC += 2
                clocks += 2
            case 0x42c4:
                # 42C4: 85 E8       STA $E8
                write_byte(0x00e8, A)
                PC += 2
                clocks += 3
            case 0x42c6:
                # 42C6: A4 FF       LDY $FF
                operand = read_byte(0xff)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x42c8:
                # 42C8: A9 08       LDA #$08
                set_a_register(0x08)
                PC += 2
                clocks += 2
            case 0x42ca:
                # 42CA: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x42cc:
                # 42CC: B1 EB       LDA ($EB),y
                assert 0x00eb < 0xff
                base_address = read_word(0x00eb)
                abs_address = base_address + Y
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 2
                clocks += 6 if different_pages(abs_address, base_address) else 5
            case 0x42ce:
                # 42CE: 0A 90       ASL A
                shift_out = (A & 0x80) != 0
                set_a_register((A << 1) & 0xff)
                C = shift_out
                PC += 1
                clocks += 2
            case 0x42cf:
                # 42CF: 90 07       BCC $42D8
                if not C:
                    PC = 0x42d8
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42d1:
                # 42D1: A2 1A       LDX #$1A
                set_x_register(0x1a)
                PC += 2
                clocks += 2
            case 0x42d3:
                # 42D3: 8E 01 D2    STX $D201
                write_byte(0xd201, X)
                PC += 3
                clocks += 4
            case 0x42d6:
                # 42D6: D0 06       BNE $42DE
                if not Z:
                    PC = 0x42de
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42d8:
                # 42D8: A2 16       LDX #$16
                set_x_register(0x16)
                PC += 2
                clocks += 2
            case 0x42da:
                # 42DA: 8E 01 D2    STX $D201
                write_byte(0xd201, X)
                PC += 3
                clocks += 4
            case 0x42dd:
                # 42DD: 0xEA        NOP
                PC += 1
                clocks += 2
            case 0x42de:
                # 42DE: A2 0C       LDX #$0C
                set_x_register(0x0c)
                PC += 2
                clocks += 2
            case 0x42e0:
                # 42E0: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x42e1:
                # 42E1: D0 FD       BNE $42E0
                if not Z:
                    PC = 0x42e0
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42e3:
                # 42E3: C6 F5       DEC $F5
                operand = read_byte(0xf5)
                value = (operand - 1) & 0xff
                write_byte(0xf5, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x42e5:
                # 42E5: D0 E7       BNE $42CE
                if not Z:
                    PC = 0x42ce
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42e7:
                # 42E7: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x42e8:
                # 42E8: E6 E8       INC $E8
                operand = read_byte(0xe8)
                value = (operand + 1) & 0xff
                write_byte(0xe8, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x42ea:
                # 42EA: D0 DC       BNE $42C8
                if not Z:
                    PC = 0x42c8
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42ec:
                # 42EC: A9 01       LDA #$01
                set_a_register(0x01)
                PC += 2
                clocks += 2
            case 0x42ee:
                # 42EE: 85 E9       STA $E9
                write_byte(0x00e9, A)
                PC += 2
                clocks += 3
            case 0x42f0:
                # 42F0: 84 FF       STY $FF
                write_byte(0x00ff, Y)
                PC += 2
                clocks += 3
            case 0x42f2:
                # 42F2: A4 EE       LDY $EE
                operand = read_byte(0xee)
                set_y_register(operand)
                PC += 2
                clocks += 3
            case 0x42f4:
                # 42F4: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x42f5:
                # 42F5: A9 01       LDA #$01
                set_a_register(0x01)
                PC += 2
                clocks += 2
            case 0x42f7:
                # 42F7: 85 ED       STA $ED
                write_byte(0x00ed, A)
                PC += 2
                clocks += 3
            case 0x42f9:
                # 42F9: D0 04       BNE $42FF
                if not Z:
                    PC = 0x42ff
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x42fb:
                # 42FB: A9 FF       LDA #$FF
                set_a_register(0xff)
                PC += 2
                clocks += 2
            case 0x42fd:
                # 42FD: 85 ED       STA $ED
                write_byte(0x00ed, A)
                PC += 2
                clocks += 3
            case 0x42ff:
                # 42FF: 86 EE       STX $EE
                write_byte(0x00ee, X)
                PC += 2
                clocks += 3
            case 0x4301:
                # 4301: 0x8A        TXA
                set_a_register(X)
                PC += 1
                clocks += 2
            case 0x4302:
                # 4302: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x4303:
                # 4303: E9 1E       SBC #$1E
                subtract_with_borrow(0x1e)
                PC += 2
                clocks += 2
            case 0x4305:
                # 4305: B0 02       BCS $4309
                if C:
                    PC = 0x4309
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4307:
                # 4307: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x4309:
                # 4309: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x430a:
                # 430A: BD 00 2E    LDA $2E00,x
                abs_address = 0x2e00 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2e00) else 4
            case 0x430d:
                # 430D: C9 7F       CMP #$7F
                compare(A, 0x7f)
                PC += 2
                clocks += 2
            case 0x430f:
                # 430F: D0 04       BNE $4315
                if not Z:
                    PC = 0x4315
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4311:
                # 4311: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4312:
                # 4312: 4C 0A 43    JMP $430A
                PC = 0x430a
                clocks += 3
            case 0x4315:
                # 4315: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x4316:
                # 4316: 65 ED       ADC $ED
                operand = read_byte(0xed)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x4318:
                # 4318: 85 E8       STA $E8
                write_byte(0x00e8, A)
                PC += 2
                clocks += 3
            case 0x431a:
                # 431A: 9D 00 2E    STA $2E00,x
                abs_address = 0x2e00 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x431d:
                # 431D: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x431e:
                # 431E: E4 EE       CPX $EE
                operand = read_byte(0xee)
                compare(X, operand)
                PC += 2
                clocks += 3
            case 0x4320:
                # 4320: F0 0C       BEQ $432E
                if Z:
                    PC = 0x432e
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4322:
                # 4322: BD 00 2E    LDA $2E00,x
                abs_address = 0x2e00 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2e00) else 4
            case 0x4325:
                # 4325: C9 FF       CMP #$FF
                compare(A, 0xff)
                PC += 2
                clocks += 2
            case 0x4327:
                # 4327: F0 F4       BEQ $431D
                if Z:
                    PC = 0x431d
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4329:
                # 4329: A5 E8       LDA $E8
                operand = read_byte(0xe8)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x432b:
                # 432B: 4C 15 43    JMP $4315
                PC = 0x4315
                clocks += 3
            case 0x432e:
                # 432E: 4C FF 3F    JMP $3FFF
                PC = 0x3fff
                clocks += 3
            case 0x4336:
                # 4336: A2 FF       LDX #$FF
                set_x_register(0xff)
                PC += 2
                clocks += 2
            case 0x4338:
                # 4338: 86 F3       STX $F3
                write_byte(0x00f3, X)
                PC += 2
                clocks += 3
            case 0x433a:
                # 433A: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x433b:
                # 433B: 86 F4       STX $F4
                write_byte(0x00f4, X)
                PC += 2
                clocks += 3
            case 0x433d:
                # 433D: 86 FF       STX $FF
                write_byte(0x00ff, X)
                PC += 2
                clocks += 3
            case 0x433f:
                # 433F: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x4341:
                # 4341: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x4344:
                # 4344: C0 FF       CPY #$FF
                compare(Y, 0xff)
                PC += 2
                clocks += 2
            case 0x4346:
                # 4346: D0 01       BNE $4349
                if not Z:
                    PC = 0x4349
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4348:
                # 4348: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x4349:
                # 4349: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x434a:
                # 434A: A5 F4       LDA $F4
                operand = read_byte(0xf4)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x434c:
                # 434C: 7D 62 23    ADC $2362,x
                abs_address = 0x2362 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                add_with_carry(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2362) else 4
            case 0x434f:
                # 434F: 85 F4       STA $F4
                write_byte(0x00f4, A)
                PC += 2
                clocks += 3
            case 0x4351:
                # 4351: C9 E8       CMP #$E8
                compare(A, 0xe8)
                PC += 2
                clocks += 2
            case 0x4353:
                # 4353: 90 03       BCC $4358
                if not C:
                    PC = 0x4358
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4355:
                # 4355: 4C 81 43    JMP $4381
                PC = 0x4381
                clocks += 3
            case 0x4358:
                # 4358: B9 5C 26    LDA $265C,y
                abs_address = 0x265c + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x265c) else 4
            case 0x435b:
                # 435B: 29 01       AND #$01
                set_a_register(A & 0x01)
                PC += 2
                clocks += 2
            case 0x435d:
                # 435D: F0 17       BEQ $4376
                if Z:
                    PC = 0x4376
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x435f:
                # 435F: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4360:
                # 4360: 86 F6       STX $F6
                write_byte(0x00f6, X)
                PC += 2
                clocks += 3
            case 0x4362:
                # 4362: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x4364:
                # 4364: 85 F4       STA $F4
                write_byte(0x00f4, A)
                PC += 2
                clocks += 3
            case 0x4366:
                # 4366: 85 F7       STA $F7
                write_byte(0x00f7, A)
                PC += 2
                clocks += 3
            case 0x4368:
                # 4368: A9 FE       LDA #$FE
                set_a_register(0xfe)
                PC += 2
                clocks += 2
            case 0x436a:
                # 436A: 85 F9       STA $F9
                write_byte(0x00f9, A)
                PC += 2
                clocks += 3
            case 0x436c:
                # 436C: 20 B8 26    JSR $26B8
                push_word(PC + 2)
                PC = 0x26b8
                clocks += 6
            case 0x436f:
                # 436F: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x4371:
                # 4371: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x4373:
                # 4373: 4C 3F 43    JMP $433F
                PC = 0x433f
                clocks += 3
            case 0x4376:
                # 4376: C0 00       CPY #$00
                compare(Y, 0x00)
                PC += 2
                clocks += 2
            case 0x4378:
                # 4378: D0 02       BNE $437C
                if not Z:
                    PC = 0x437c
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x437a:
                # 437A: 86 F3       STX $F3
                write_byte(0x00f3, X)
                PC += 2
                clocks += 3
            case 0x437c:
                # 437C: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x437e:
                # 437E: 4C 3F 43    JMP $433F
                PC = 0x433f
                clocks += 3
            case 0x4381:
                # 4381: A6 F3       LDX $F3
                operand = read_byte(0xf3)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x4383:
                # 4383: A9 1F       LDA #$1F
                set_a_register(0x1f)
                PC += 2
                clocks += 2
            case 0x4385:
                # 4385: 9D 62 22    STA $2262,x
                abs_address = 0x2262 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4388:
                # 4388: A9 04       LDA #$04
                set_a_register(0x04)
                PC += 2
                clocks += 2
            case 0x438a:
                # 438A: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x438d:
                # 438D: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x438f:
                # 438F: 9D 62 24    STA $2462,x
                abs_address = 0x2462 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4392:
                # 4392: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4393:
                # 4393: 86 F6       STX $F6
                write_byte(0x00f6, X)
                PC += 2
                clocks += 3
            case 0x4395:
                # 4395: A9 FE       LDA #$FE
                set_a_register(0xfe)
                PC += 2
                clocks += 2
            case 0x4397:
                # 4397: 85 F9       STA $F9
                write_byte(0x00f9, A)
                PC += 2
                clocks += 3
            case 0x4399:
                # 4399: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x439b:
                # 439B: 85 F4       STA $F4
                write_byte(0x00f4, A)
                PC += 2
                clocks += 3
            case 0x439d:
                # 439D: 85 F7       STA $F7
                write_byte(0x00f7, A)
                PC += 2
                clocks += 3
            case 0x439f:
                # 439F: 20 B8 26    JSR $26B8
                push_word(PC + 2)
                PC = 0x26b8
                clocks += 6
            case 0x43a2:
                # 43A2: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x43a3:
                # 43A3: 86 FF       STX $FF
                write_byte(0x00ff, X)
                PC += 2
                clocks += 3
            case 0x43a5:
                # 43A5: 4C 3F 43    JMP $433F
                PC = 0x433f
                clocks += 3
            case 0x43aa:
                # 43AA: A9 00       LDA #$00
                set_a_register(0x00)
                PC += 2
                clocks += 2
            case 0x43ac:
                # 43AC: 0xAA        TAX
                set_x_register(A)
                PC += 1
                clocks += 2
            case 0x43ad:
                # 43AD: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x43ae:
                # 43AE: BD 62 22    LDA $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x43b1:
                # 43B1: C9 FF       CMP #$FF
                compare(A, 0xff)
                PC += 2
                clocks += 2
            case 0x43b3:
                # 43B3: D0 09       BNE $43BE
                if not Z:
                    PC = 0x43be
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x43b5:
                # 43B5: A9 FF       LDA #$FF
                set_a_register(0xff)
                PC += 2
                clocks += 2
            case 0x43b7:
                # 43B7: 99 C0 3E    STA $3EC0,y
                abs_address = 0x3ec0 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x43ba:
                # 43BA: 20 D6 3F    JSR $3FD6
                push_word(PC + 2)
                PC = 0x3fd6
                clocks += 6
            case 0x43bd:
                # 43BD: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x43be:
                # 43BE: C9 FE       CMP #$FE
                compare(A, 0xfe)
                PC += 2
                clocks += 2
            case 0x43c0:
                # 43C0: D0 14       BNE $43D6
                if not Z:
                    PC = 0x43d6
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x43c2:
                # 43C2: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x43c3:
                # 43C3: 8E A9 43    STX $43A9
                write_byte(0x43a9, X)
                PC += 3
                clocks += 4
            case 0x43c6:
                # 43C6: A9 FF       LDA #$FF
                set_a_register(0xff)
                PC += 2
                clocks += 2
            case 0x43c8:
                # 43C8: 99 C0 3E    STA $3EC0,y
                abs_address = 0x3ec0 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x43cb:
                # 43CB: 20 D6 3F    JSR $3FD6
                push_word(PC + 2)
                PC = 0x3fd6
                clocks += 6
            case 0x43ce:
                # 43CE: AE A9 43    LDX $43A9
                operand = read_byte(0x43a9)
                set_x_register(operand)
                PC += 3
                clocks += 4
            case 0x43d1:
                # 43D1: A0 00       LDY #$00
                set_y_register(0x00)
                PC += 2
                clocks += 2
            case 0x43d3:
                # 43D3: 4C AE 43    JMP $43AE
                PC = 0x43ae
                clocks += 3
            case 0x43d6:
                # 43D6: C9 00       CMP #$00
                compare(A, 0x00)
                PC += 2
                clocks += 2
            case 0x43d8:
                # 43D8: D0 04       BNE $43DE
                if not Z:
                    PC = 0x43de
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x43da:
                # 43DA: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x43db:
                # 43DB: 4C AE 43    JMP $43AE
                PC = 0x43ae
                clocks += 3
            case 0x43de:
                # 43DE: 99 C0 3E    STA $3EC0,y
                abs_address = 0x3ec0 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x43e1:
                # 43E1: BD 62 23    LDA $2362,x
                abs_address = 0x2362 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2362) else 4
            case 0x43e4:
                # 43E4: 99 38 3F    STA $3F38,y
                abs_address = 0x3f38 + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x43e7:
                # 43E7: BD 62 24    LDA $2462,x
                abs_address = 0x2462 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2462) else 4
            case 0x43ea:
                # 43EA: 99 FC 3E    STA $3EFC,y
                abs_address = 0x3efc + Y
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x43ed:
                # 43ED: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x43ee:
                # 43EE: 0xC8        INY
                set_y_register((Y + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x43ef:
                # 43EF: 4C AE 43    JMP $43AE
                PC = 0x43ae
                clocks += 3
            case 0x43f2:
                # 43F2: A2 00       LDX #$00
                set_x_register(0x00)
                PC += 2
                clocks += 2
            case 0x43f4:
                # 43F4: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x43f7:
                # 43F7: C0 FF       CPY #$FF
                compare(Y, 0xff)
                PC += 2
                clocks += 2
            case 0x43f9:
                # 43F9: D0 03       BNE $43FE
                if not Z:
                    PC = 0x43fe
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x43fb:
                # 43FB: 4C 40 44    JMP $4440
                PC = 0x4440
                clocks += 3
            case 0x43fe:
                # 43FE: B9 5C 26    LDA $265C,y
                abs_address = 0x265c + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x265c) else 4
            case 0x4401:
                # 4401: 29 01       AND #$01
                set_a_register(A & 0x01)
                PC += 2
                clocks += 2
            case 0x4403:
                # 4403: D0 04       BNE $4409
                if not Z:
                    PC = 0x4409
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4405:
                # 4405: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4406:
                # 4406: 4C F4 43    JMP $43F4
                PC = 0x43f4
                clocks += 3
            case 0x4409:
                # 4409: 86 FF       STX $FF
                write_byte(0x00ff, X)
                PC += 2
                clocks += 3
            case 0x440b:
                # 440B: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x440c:
                # 440C: F0 ED       BEQ $43FB
                if Z:
                    PC = 0x43fb
                    clocks += 4
                else:
                    PC += 2
                    clocks += 2
            case 0x440e:
                # 440E: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x4411:
                # 4411: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x4414:
                # 4414: 29 80       AND #$80
                set_a_register(A & 0x80)
                PC += 2
                clocks += 2
            case 0x4416:
                # 4416: F0 F3       BEQ $440B
                if Z:
                    PC = 0x440b
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4418:
                # 4418: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x441b:
                # 441B: B9 5C 26    LDA $265C,y
                abs_address = 0x265c + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x265c) else 4
            case 0x441e:
                # 441E: 29 20       AND #$20
                set_a_register(A & 0x20)
                PC += 2
                clocks += 2
            case 0x4420:
                # 4420: F0 07       BEQ $4429
                if Z:
                    PC = 0x4429
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4422:
                # 4422: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x4425:
                # 4425: 29 04       AND #$04
                set_a_register(A & 0x04)
                PC += 2
                clocks += 2
            case 0x4427:
                # 4427: F0 0E       BEQ $4437
                if Z:
                    PC = 0x4437
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4429:
                # 4429: BD 62 23    LDA $2362,x
                abs_address = 0x2362 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2362) else 4
            case 0x442c:
                # 442C: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x442e:
                # 442E: 4A 18       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x442f:
                # 442F: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x4430:
                # 4430: 65 F5       ADC $F5
                operand = read_byte(0xf5)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x4432:
                # 4432: 69 01       ADC #$01
                add_with_carry(0x01)
                PC += 2
                clocks += 2
            case 0x4434:
                # 4434: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4437:
                # 4437: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4438:
                # 4438: E4 FF       CPX $FF
                operand = read_byte(0xff)
                compare(X, operand)
                PC += 2
                clocks += 3
            case 0x443a:
                # 443A: D0 DC       BNE $4418
                if not Z:
                    PC = 0x4418
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x443c:
                # 443C: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x443d:
                # 443D: 4C F4 43    JMP $43F4
                PC = 0x43f4
                clocks += 3
            case 0x4440:
                # 4440: A2 00       LDX #$00
                set_x_register(0x00)
                PC += 2
                clocks += 2
            case 0x4442:
                # 4442: 86 FF       STX $FF
                write_byte(0x00ff, X)
                PC += 2
                clocks += 3
            case 0x4444:
                # 4444: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x4446:
                # 4446: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x4449:
                # 4449: C0 FF       CPY #$FF
                compare(Y, 0xff)
                PC += 2
                clocks += 2
            case 0x444b:
                # 444B: D0 01       BNE $444E
                if not Z:
                    PC = 0x444e
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x444d:
                # 444D: 0x60        RTS
                PC = (pop_word() + 1) & 0xffff
                clocks += 6
            case 0x444e:
                # 444E: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x4451:
                # 4451: 29 80       AND #$80
                set_a_register(A & 0x80)
                PC += 2
                clocks += 2
            case 0x4453:
                # 4453: D0 03       BNE $4458
                if not Z:
                    PC = 0x4458
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4455:
                # 4455: 4C BC 44    JMP $44BC
                PC = 0x44bc
                clocks += 3
            case 0x4458:
                # 4458: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4459:
                # 4459: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x445c:
                # 445C: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x445f:
                # 445F: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x4461:
                # 4461: 29 40       AND #$40
                set_a_register(A & 0x40)
                PC += 2
                clocks += 2
            case 0x4463:
                # 4463: F0 33       BEQ $4498
                if Z:
                    PC = 0x4498
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4465:
                # 4465: A5 F5       LDA $F5
                operand = read_byte(0xf5)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x4467:
                # 4467: 29 04       AND #$04
                set_a_register(A & 0x04)
                PC += 2
                clocks += 2
            case 0x4469:
                # 4469: F0 13       BEQ $447E
                if Z:
                    PC = 0x447e
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x446b:
                # 446B: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x446c:
                # 446C: BD 62 23    LDA $2362,x
                abs_address = 0x2362 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2362) else 4
            case 0x446f:
                # 446F: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x4471:
                # 4471: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4472:
                # 4472: 4A 18       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4473:
                # 4473: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x4474:
                # 4474: 65 F5       ADC $F5
                operand = read_byte(0xf5)
                add_with_carry(operand)
                PC += 2
                clocks += 3
            case 0x4476:
                # 4476: 69 01       ADC #$01
                add_with_carry(0x01)
                PC += 2
                clocks += 2
            case 0x4478:
                # 4478: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x447b:
                # 447B: 4C 28 45    JMP $4528
                PC = 0x4528
                clocks += 3
            case 0x447e:
                # 447E: A5 F5       LDA $F5
                operand = read_byte(0xf5)
                set_a_register(operand)
                PC += 2
                clocks += 3
            case 0x4480:
                # 4480: 29 01       AND #$01
                set_a_register(A & 0x01)
                PC += 2
                clocks += 2
            case 0x4482:
                # 4482: F0 F7       BEQ $447B
                if Z:
                    PC = 0x447b
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4484:
                # 4484: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4485:
                # 4485: BD 62 23    LDA $2362,x
                abs_address = 0x2362 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2362) else 4
            case 0x4488:
                # 4488: 0xA8        TAY
                set_y_register(A)
                PC += 1
                clocks += 2
            case 0x4489:
                # 4489: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x448a:
                # 448A: 4A 4A       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x448b:
                # 448B: 4A 85       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x448c:
                # 448C: 85 F5       STA $F5
                write_byte(0x00f5, A)
                PC += 2
                clocks += 3
            case 0x448e:
                # 448E: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x448f:
                # 448F: 0x98        TYA
                set_a_register(Y)
                PC += 1
                clocks += 2
            case 0x4490:
                # 4490: E5 F5       SBC $F5
                operand = read_byte(0xf5)
                subtract_with_borrow(operand)
                PC += 2
                clocks += 3
            case 0x4492:
                # 4492: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4495:
                # 4495: 4C 28 45    JMP $4528
                PC = 0x4528
                clocks += 3
            case 0x4498:
                # 4498: C0 12       CPY #$12
                compare(Y, 0x12)
                PC += 2
                clocks += 2
            case 0x449a:
                # 449A: F0 07       BEQ $44A3
                if Z:
                    PC = 0x44a3
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x449c:
                # 449C: C0 13       CPY #$13
                compare(Y, 0x13)
                PC += 2
                clocks += 2
            case 0x449e:
                # 449E: F0 03       BEQ $44A3
                if Z:
                    PC = 0x44a3
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x44a0:
                # 44A0: 4C 28 45    JMP $4528
                PC = 0x4528
                clocks += 3
            case 0x44a3:
                # 44A3: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x44a4:
                # 44A4: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x44a7:
                # 44A7: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x44aa:
                # 44AA: 29 40       AND #$40
                set_a_register(A & 0x40)
                PC += 2
                clocks += 2
            case 0x44ac:
                # 44AC: F0 F2       BEQ $44A0
                if Z:
                    PC = 0x44a0
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x44ae:
                # 44AE: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x44b0:
                # 44B0: BD 62 23    LDA $2362,x
                abs_address = 0x2362 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2362) else 4
            case 0x44b3:
                # 44B3: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x44b4:
                # 44B4: E9 01       SBC #$01
                subtract_with_borrow(0x01)
                PC += 2
                clocks += 2
            case 0x44b6:
                # 44B6: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x44b9:
                # 44B9: 4C 28 45    JMP $4528
                PC = 0x4528
                clocks += 3
            case 0x44bc:
                # 44BC: B9 5C 26    LDA $265C,y
                abs_address = 0x265c + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x265c) else 4
            case 0x44bf:
                # 44BF: 29 08       AND #$08
                set_a_register(A & 0x08)
                PC += 2
                clocks += 2
            case 0x44c1:
                # 44C1: F0 1C       BEQ $44DF
                if Z:
                    PC = 0x44df
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x44c3:
                # 44C3: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x44c4:
                # 44C4: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x44c7:
                # 44C7: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x44ca:
                # 44CA: 29 02       AND #$02
                set_a_register(A & 0x02)
                PC += 2
                clocks += 2
            case 0x44cc:
                # 44CC: D0 03       BNE $44D1
                if not Z:
                    PC = 0x44d1
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x44ce:
                # 44CE: 4C 28 45    JMP $4528
                PC = 0x4528
                clocks += 3
            case 0x44d1:
                # 44D1: A9 06       LDA #$06
                set_a_register(0x06)
                PC += 2
                clocks += 2
            case 0x44d3:
                # 44D3: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x44d6:
                # 44D6: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x44d7:
                # 44D7: A9 05       LDA #$05
                set_a_register(0x05)
                PC += 2
                clocks += 2
            case 0x44d9:
                # 44D9: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x44dc:
                # 44DC: 4C 28 45    JMP $4528
                PC = 0x4528
                clocks += 3
            case 0x44df:
                # 44DF: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x44e2:
                # 44E2: 29 02       AND #$02
                set_a_register(A & 0x02)
                PC += 2
                clocks += 2
            case 0x44e4:
                # 44E4: F0 26       BEQ $450C
                if Z:
                    PC = 0x450c
                    clocks += 4
                else:
                    PC += 2
                    clocks += 2
            case 0x44e6:
                # 44E6: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x44e7:
                # 44E7: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x44ea:
                # 44EA: F0 FA       BEQ $44E6
                if Z:
                    PC = 0x44e6
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x44ec:
                # 44EC: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x44ef:
                # 44EF: 29 02       AND #$02
                set_a_register(A & 0x02)
                PC += 2
                clocks += 2
            case 0x44f1:
                # 44F1: F0 DB       BEQ $44CE
                if Z:
                    PC = 0x44ce
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x44f3:
                # 44F3: BD 62 23    LDA $2362,x
                abs_address = 0x2362 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2362) else 4
            case 0x44f6:
                # 44F6: 4A 18       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x44f7:
                # 44F7: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x44f8:
                # 44F8: 69 01       ADC #$01
                add_with_carry(0x01)
                PC += 2
                clocks += 2
            case 0x44fa:
                # 44FA: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x44fd:
                # 44FD: A6 FF       LDX $FF
                operand = read_byte(0xff)
                set_x_register(operand)
                PC += 2
                clocks += 3
            case 0x44ff:
                # 44FF: BD 62 23    LDA $2362,x
                abs_address = 0x2362 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2362) else 4
            case 0x4502:
                # 4502: 4A 18       LSR A
                C = (A & 0x01) != 0
                set_a_register((A >> 1))
                PC += 1
                clocks += 2
            case 0x4503:
                # 4503: 0x18        CLC
                C = False
                PC += 1
                clocks += 2
            case 0x4504:
                # 4504: 69 01       ADC #$01
                add_with_carry(0x01)
                PC += 2
                clocks += 2
            case 0x4506:
                # 4506: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4509:
                # 4509: 4C 28 45    JMP $4528
                PC = 0x4528
                clocks += 3
            case 0x450c:
                # 450C: B9 5C 26    LDA $265C,y
                abs_address = 0x265c + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x265c) else 4
            case 0x450f:
                # 450F: 29 10       AND #$10
                set_a_register(A & 0x10)
                PC += 2
                clocks += 2
            case 0x4511:
                # 4511: F0 F6       BEQ $4509
                if Z:
                    PC = 0x4509
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x4513:
                # 4513: 0xCA        DEX
                set_x_register((X - 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x4514:
                # 4514: BC 62 22    LDY $2262,x
                abs_address = 0x2262 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_y_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2262) else 4
            case 0x4517:
                # 4517: B9 0E 26    LDA $260E,y
                abs_address = 0x260e + Y
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x260e) else 4
            case 0x451a:
                # 451A: 29 02       AND #$02
                set_a_register(A & 0x02)
                PC += 2
                clocks += 2
            case 0x451c:
                # 451C: F0 EB       BEQ $4509
                if Z:
                    PC = 0x4509
                    clocks += 3
                else:
                    PC += 2
                    clocks += 2
            case 0x451e:
                # 451E: 0xE8        INX
                set_x_register((X + 1) & 0xff)
                PC += 1
                clocks += 2
            case 0x451f:
                # 451F: BD 62 23    LDA $2362,x
                abs_address = 0x2362 + X
                assert abs_address <= 0xffff
                operand = read_byte(abs_address)
                set_a_register(operand)
                PC += 3
                clocks += 5 if different_pages(abs_address, 0x2362) else 4
            case 0x4522:
                # 4522: 0x38        SEC
                C = True
                PC += 1
                clocks += 2
            case 0x4523:
                # 4523: E9 02       SBC #$02
                subtract_with_borrow(0x02)
                PC += 2
                clocks += 2
            case 0x4525:
                # 4525: 9D 62 23    STA $2362,x
                abs_address = 0x2362 + X
                write_byte(abs_address, A)
                PC += 3
                clocks += 5  # sim65 is incorrect here. No extra cycle should be added when crossing a page boundary.
            case 0x4528:
                # 4528: E6 FF       INC $FF
                operand = read_byte(0xff)
                value = (operand + 1) & 0xff
                write_byte(0xff, value)
                update_nz_flags(value)
                PC += 2
                clocks += 5
            case 0x452a:
                # 452A: 4C 44 44    JMP $4444
                PC = 0x4444
                clocks += 3

            # ------------------------------ SAM_ERROR_SOUND.

            case 0x452d:

                raise RuntimeError("SAM_ERROR_SOUND")

            # ------------------------------
            case _:
                raise RuntimeError("Bad address.")

def main():
    t1 = time.time()
    sam()
    t2 = time.time()
    print("total clocks:", clocks, file=sys.stderr)
    print("runtime:", t2 - t1, file=sys.stderr)

if __name__ == "__main__":
    main()
