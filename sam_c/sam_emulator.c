
#include <assert.h>
#include <stdio.h>
#include <inttypes.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint64_t u64;

#define MEM_SIZE 0x4651

struct sam_machine {
    u64 clocks;
    u16 pc;
    u8 sp;
    u8 a;
    u8 x;
    u8 y;
    u8 flag_n;
    u8 flag_z;
    u8 flag_c;
    u8 mem[MEM_SIZE];
};

void sam_init(struct sam_machine * sam)
{
    for (unsigned k = 0; k < MEM_SIZE; ++k)
    {
        sam->mem[k] = 0;
    }

    FILE * f = fopen("sam_2000_4650.bin", "rb");
    fread(&sam->mem[0x2000], 1, 9809, f);
    fclose(f);

    sam->clocks = 0;
    sam->pc = 0;
    sam->a = 0;
    sam->x = 0;
    sam->y = 0;
    sam->sp = 0xff;
    sam->flag_n = 0;
    sam->flag_z = 0;
    sam->flag_c = 0;
}

u8 sam_read_byte(struct sam_machine * sam, u16 address)
{
    assert(address < MEM_SIZE);
    return sam->mem[address];
}

void emit_audio_sample(u64 time, u8 sample)
{
    (void)time;
    (void)sample;
}

void sam_write_byte(struct sam_machine * sam, u16 address, u8 value)
{
    switch (address)
    {
        case 0xd201:
        {
            assert( (16 <= value) && (value <= 31) );
            emit_audio_sample(sam->clocks, value);
        }
        case 0xd20e: // Ignore writes to hardware addresses.
        case 0xd400:
        case 0xd40e: return;
    }
    printf("0x%04x\n", address);
    assert(address < MEM_SIZE);
    sam->mem[address] = value;
}

u16 sam_read_word(struct sam_machine * sam, u16 address)
{
    u8 lo = sam_read_byte(sam, address);
    u8 hi = sam_read_byte(sam, address + 1);
    return 0x100 * hi + lo;
}

void sam_push_byte(struct sam_machine * sam, u8 value)
{
    sam->mem[0x100 + sam->sp] = value;
    --sam->sp;
}

uint8_t sam_pop_byte(struct sam_machine * sam)
{
    ++sam->sp;
    return sam->mem[0x100 + sam->sp];
}

void sam_push_word(struct sam_machine * sam, u16 value)
{
    printf("push word: 0x%04x\n", value);
    sam_push_byte(sam, value / 256); // high byte is pushed before low byte.
    sam_push_byte(sam, value % 256);
}

uint16_t sam_pop_word(struct sam_machine * sam)
{
    uint8_t lo = sam_pop_byte(sam); // lo byte is popped before hugh byte.
    uint8_t hi = sam_pop_byte(sam);

    printf("pop word: 0x%04x\n", hi * 0x100 + lo);

    return hi * 0x100 + lo;
}

void sam_update_nz_flags(struct sam_machine * sam, u8 value)
{
    sam->flag_z = (value == 0);
    sam->flag_n = (value & 0x80) != 0;
}

unsigned different_pages(uint16_t u1, uint16_t u2)
{
    return (u1 / 0x100) != (u2 / 0x100);
}

void sam_branch_if(struct sam_machine * sam, unsigned condition)
{
    if (condition)
    {
        // branch taken.
        const u8 displacement = sam_read_byte(sam, sam->pc + 1);
        const u16 target = sam->pc + 2 + displacement - (((displacement & 0x80) != 0) ? 0x0100 : 0);
        sam->clocks += different_pages(target, sam->pc) ? 4 : 3;
        sam->pc = target;
    }
    else
    {
        // branch not taken.
        sam->pc += 2;
        sam->clocks += 2;
    }
}

void sam_add_with_carry(struct sam_machine * sam, u8 value)
{
    const u16 temp = (u16)(sam->a) + (u16)(value) + (u16)(sam->flag_c);
    sam->flag_c = (temp & 0x100) != 0;
    sam->a = temp & 0xff;
    sam_update_nz_flags(sam, sam->a);
}

void sam_subtract_with_borrow(struct sam_machine * sam, u8 value)
{
    const u16 temp = (u16)(sam->a) - (u16)(value) - (u16)(!sam->flag_c);
    sam->flag_c = (temp & 0x100) != 0;
    sam->a = temp & 0xff;
    sam_update_nz_flags(sam, sam->a);
}

int sam_execute_instruction(struct sam_machine * sam)
{
    const u8 instruction = sam_read_byte(sam, sam->pc);
    printf("[%16llu] 0x%04x instruction: 0x%02x\n", sam->clocks, sam->pc, instruction);

    switch (instruction)
    {
        case 0x06: // asl zp
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            u8 value = sam_read_byte(sam, zp_address);
            const u8 shift_out = (value & 0x80) != 0;
            value = (value << 1) | sam->flag_c;
            sam_update_nz_flags(sam, value);
            sam->flag_c = shift_out;
            sam_write_byte(sam, zp_address, value);
            sam->pc += 2;
            sam->clocks += 5;
            break;
        }
        case 0x09: // ora #imm
        {
            const u8 value = sam_read_byte(sam, sam->pc + 1);
            sam->a |= value;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 2;
            sam->clocks += 2;
            break;
        }
        case 0x0a: // asl a
        {
            sam->flag_c = (sam->a & 0x80) != 0;
            sam->a <<= 1;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0x10: // bpl rel
        {
            sam_branch_if(sam, sam->flag_n == 0);
            break;
        }
        case 0x18: // clc
        {
            sam->flag_c = 0;
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0x19: // ora abs,y
        {
            const u16 base_address = sam_read_word(sam, sam->pc + 1);
            const u16 abs_address = base_address + sam->y;
            const u8 value = sam_read_byte(sam, abs_address);
            sam->a |= value;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 3;
            sam->clocks += different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0x20: // jsr absolute
        {
            const u16 target = sam_read_word(sam, sam->pc + 1);
            // Push (PC + 2) onto the stack.
            sam_push_word(sam, sam->pc + 2);
            sam->pc = target;
            sam->clocks += 6;
            break;
        }
        case 0x24: // bit zpage
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address);
            sam_update_nz_flags(sam, value);
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0x29: // and #imm
        {
            const u8 value = sam_read_byte(sam, sam->pc + 1);
            sam->a &= value;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 2;
            sam->clocks += 2;
            break;
        }
        case 0x2a: // rol a
        {
            u8 shift_out = (sam->a & 0x80) != 0;
            sam->a = (sam->a << 1) | sam->flag_c;
            sam->flag_c = shift_out;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0x30: // bmi rel
        {
            sam_branch_if(sam, sam->flag_n != 0);
            break;
        }
        case 0x38: // sec
        {
            sam->flag_c = 1;
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0x49: // eor #imm
        {
            const u8 value = sam_read_byte(sam, sam->pc + 1);
            sam->a ^= value;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 2;
            sam->clocks += 2;
            break;
        }
        case 0x4a: // lsr a
        {
            sam->flag_c = sam->a & 0x01;
            sam->a >>= 1;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0x4c: // jmp absolute
        {
            const u16 target = sam_read_word(sam, sam->pc + 1);
            sam->pc = target;
            sam->clocks += 3;
            break;
        }
        case 0x60: // rts
        {
            const u16 target = sam_pop_word(sam) + 1;
            sam->pc = target;
            sam->clocks += 6;
            break;
        }
        case 0x65: // adc zp
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address);
            const u16 temp = (u16)(sam->a) + (u16)(value) + (u16)(sam->flag_c);
            sam->flag_c = (temp & 0x100) != 0;
            sam->a = temp & 0xff;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0x69: // adc #imm
        {
            const u8 value = sam_read_byte(sam, sam->pc + 1);
            const u16 temp = (u16)(sam->a) + (u16)(value) + (u16)(sam->flag_c);
            sam->flag_c = (temp & 0x100) != 0;
            sam->a = temp & 0xff;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 2;
            sam->clocks += 2;
            break;
        }
        case 0x79: // adc abs,y
        {
            const u16 base_address = sam_read_word(sam, sam->pc + 1);
            const u16 abs_address = base_address + sam->y;
            const u8 value = sam_read_byte(sam, abs_address);
            sam_add_with_carry(sam, value);
            sam->pc += 3;
            sam->clocks += different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0x7d: // adc abs,x
        {
            const u16 base_address = sam_read_word(sam, sam->pc + 1);
            const u16 abs_address = base_address + sam->x;
            const u8 value = sam_read_byte(sam, abs_address);
            sam_add_with_carry(sam, value);
            sam->pc += 3;
            sam->clocks += different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0x84: // sty zp
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            sam_write_byte(sam, zp_address, sam->y);
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0x85: // sta zp
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            sam_write_byte(sam, zp_address, sam->a);
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0x86: // stx zp
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            sam_write_byte(sam, zp_address, sam->x);
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0x88: // dey
        {
            --sam->y;
            sam_update_nz_flags(sam, sam->y);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0x8a: // txa
        {
            sam->a = sam->x;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0x8d: // sta abs
        {
            const u16 abs_address = sam_read_word(sam, sam->pc + 1);
            sam_write_byte(sam, abs_address, sam->a);
            sam->pc += 3;
            sam->clocks += 4;
            break;
        }
        case 0x8e: // stx abs
        {
            const u16 abs_address = sam_read_word(sam, sam->pc + 1);
            sam_write_byte(sam, abs_address, sam->x);
            sam->pc += 3;
            sam->clocks += 4;
            break;
        }
        case 0x90: // bcc rel
        {
            sam_branch_if(sam, sam->flag_c == 0);
            break;
        }
        case 0x91: // sta (zp),y
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u16 base_address = sam_read_word(sam, zp_address);
            const u16 abs_address = base_address + sam->y;
            sam_write_byte(sam, abs_address, sam->a);
            sam->pc += 2;
            sam->clocks += 4;
            break;
        }
        case 0x95: // sta zp,x
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1) + sam->x;
            sam_write_byte(sam, zp_address, sam->a);
            sam->pc += 2;
            sam->clocks += 4;
            break;
        }
        case 0x98: // tya
        {
            sam->a = sam->y;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0x99: // sta abs,y
        {
            const u16 abs_address = sam_read_word(sam, sam->pc + 1) + sam->y;
            sam_write_byte(sam, abs_address, sam->a);
            sam->pc += 3;
            sam->clocks += 5;
            break;
        }
        case 0x9d: // sta abs,x
        {
            const u16 abs_address = sam_read_word(sam, sam->pc + 1) + sam->x;
            sam_write_byte(sam, abs_address, sam->a);
            sam->pc += 3;
            sam->clocks += 5;
            break;
        }
        case 0xa0: // ldy #imm
        {
            const u8 value = sam_read_byte(sam, sam->pc + 1);
            sam->y = value;
            sam_update_nz_flags(sam, value);
            sam->pc += 2;
            sam->clocks += 2;
            break;
        }
        case 0xa2: // ldx #imm
        {
            const u8 value = sam_read_byte(sam, sam->pc + 1);
            sam->x = value;
            sam_update_nz_flags(sam, value);
            sam->pc += 2;
            sam->clocks += 2;
            break;
        }
        case 0xa4: // ldy zp
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address);
            sam_update_nz_flags(sam, value);
            sam->y = value;
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0xa5: // lda zp
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address);
            sam_update_nz_flags(sam, value);
            sam->a = value;
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0xa6: // ldx zp
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address);
            sam_update_nz_flags(sam, value);
            sam->x = value;
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0xa8: // tay
        {
            sam->y = sam->a;
            sam_update_nz_flags(sam, sam->y);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0xa9: // lda #imm
        {
            const u8 value = sam_read_byte(sam, sam->pc + 1);
            sam->a = value;
            sam_update_nz_flags(sam, value);
            sam->pc += 2;
            sam->clocks += 2;
            break;
        }
        case 0xaa: // tax
        {
            sam->x = sam->a;
            sam_update_nz_flags(sam, sam->x);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0xad: // lda abs
        {
            const u16 abs_address = sam_read_word(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, abs_address);
            sam_update_nz_flags(sam, value);
            sam->a = value;
            sam->pc += 3;
            sam->clocks += 4;
            break;
        }
        case 0xae: // ldx abs
        {
            const u16 abs_address = sam_read_word(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, abs_address);
            sam_update_nz_flags(sam, value);
            sam->x = value;
            sam->pc += 3;
            sam->clocks += 4;
            break;
        }
        case 0xb0: // bcs rel
        {
            sam_branch_if(sam, sam->flag_c != 0);
            break;
        }
        case 0xb1: // lda (zp),y
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u16 base_address = sam_read_word(sam, zp_address);
            const u16 abs_address = base_address + sam->y;
            const u8 value = sam_read_byte(sam, abs_address);
            sam_update_nz_flags(sam, value);
            sam->a = value;
            sam->pc += 2;
            sam->clocks += different_pages(base_address, abs_address) ? 6 : 5;
            break;
        }
        case 0xb5: // lda zp,x
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1) + sam->x;
            const u8 value = sam_read_byte(sam, zp_address);
            sam_update_nz_flags(sam, value);
            sam->a = value;
            sam->pc += 2;
            sam->clocks += 4;
            break;
        }
        case 0xb9: // lda abs,y
        {
            const u16 base_address = sam_read_word(sam, sam->pc + 1);
            const u16 abs_address = base_address + sam->y;
            const u8 value = sam_read_byte(sam, abs_address);
            sam_update_nz_flags(sam, value);
            sam->a = value;
            sam->pc += 3;
            sam->clocks += different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0xbc: // ldy abs,x
        {
            const u16 base_address = sam_read_word(sam, sam->pc + 1);
            const u16 abs_address = base_address + sam->x;
            const u8 value = sam_read_byte(sam, abs_address);
            sam_update_nz_flags(sam, value);
            sam->y = value;
            sam->pc += 3;
            sam->clocks += different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0xbd: // lda abs,x
        {
            const u16 base_address = sam_read_word(sam, sam->pc + 1);
            const u16 abs_address = base_address + sam->x;
            const u8 value = sam_read_byte(sam, abs_address);
            sam_update_nz_flags(sam, value);
            sam->a = value;
            sam->pc += 3;
            sam->clocks += different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0xc0: // cpy #imm
        {
            const u8 value = sam_read_byte(sam, sam->pc + 1);

            const u8 difference = sam->y - value;
            sam->flag_c = (sam->y >= value);
            sam_update_nz_flags(sam, difference);
            sam->pc += 2;
            sam->clocks += 2;
            break;
        }
        case 0xc5: // cmp zpage
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address);

            const u8 difference = sam->a - value;
            sam->flag_c = (sam->a >= value);
            sam_update_nz_flags(sam, difference);
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0xc6: // dec zp
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address) - 1;
            sam_update_nz_flags(sam, value);
            sam_write_byte(sam, zp_address, value);
            sam->pc += 2;
            sam->clocks += 5;
            break;
        }
        case 0xc8: // iny
        {
            ++sam->y;
            sam_update_nz_flags(sam, sam->y);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0xc9: // cmp #imm
        {
            const u8 value = sam_read_byte(sam, sam->pc + 1);

            const u8 difference = sam->a - value;
            sam->flag_c = (sam->a >= value);
            sam_update_nz_flags(sam, difference);
            sam->pc += 2;
            sam->clocks += 2;
            break;
        }
        case 0xca: // dex
        {
            --sam->x;
            sam_update_nz_flags(sam, sam->x);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0xd0: // bne rel
        {
            sam_branch_if(sam, sam->flag_z == 0);
            break;
        }
        case 0xd9: // cmp abs,y
        {
            const u16 base_address = sam_read_word(sam, sam->pc + 1);
            const u16 abs_address = base_address + sam->y;
            const u8 value = sam_read_byte(sam, abs_address);

            const u8 difference = sam->a - value;
            sam->flag_c = (sam->a >= value); // TODO: check.
            sam_update_nz_flags(sam, difference);
            sam->pc += 3;
            sam->clocks += different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0xe4: // cpx zpage
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address);

            const u8 difference = sam->x - value;
            sam->flag_c = (sam->x >= value);
            sam_update_nz_flags(sam, difference);
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0xe5: // sbc zpage
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address);

            sam_subtract_with_borrow(sam, value);
            sam->pc += 2;
            sam->clocks += 3;
            break;
        }
        case 0xe6: // inc zp
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address) + 1;
            sam_update_nz_flags(sam, value);
            sam_write_byte(sam, zp_address, value);
            sam->pc += 2;
            sam->clocks += 5;
            break;
        }
        case 0xe8: // inx
        {
            ++sam->x;
            sam_update_nz_flags(sam, sam->x);
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0xe9: // sbc #imm
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u8 value = sam_read_byte(sam, zp_address) + 1;
            const u16 temp = (u16)(sam->a) - (u16)(value) - (u16)(!sam->flag_c);
            sam->flag_c = (temp & 0x100) != 0;
            sam->a = temp & 0xff;
            sam_update_nz_flags(sam, sam->a);
            sam->pc += 2;
            sam->clocks += 4;
            break;
        }
        case 0xea: // nop
        {
            sam->pc += 1;
            sam->clocks += 2;
            break;
        }
        case 0xf0: // beq rel
        {
            sam_branch_if(sam, sam->flag_z != 0);
            break;
        }
        case 0xf1: // sbc (zp),y
        {
            const u8 zp_address = sam_read_byte(sam, sam->pc + 1);
            const u16 base_address = sam_read_word(sam, zp_address);
            const u16 abs_address = base_address + sam->y;
            const u8 value = sam_read_byte(sam, abs_address);
            sam_subtract_with_borrow(sam, value);
            sam_update_nz_flags(sam, value);
            sam->a = value;
            sam->pc += 2;
            sam->clocks += different_pages(base_address, abs_address) ? 6 : 5;
            break;
        }
        default:
        {
            return -1; // Unhandled 6502 opcode.
        }
    }
    return 0;
}

void sam_run(struct sam_machine * sam)
{
    sam->clocks = 0;
    sam->sp = 0xff;
    sam_push_word(sam, 0xffff); // The last RTS will return to address 0.
    sam->pc = 0x2004;
    sam->flag_z = 0;
    sam->flag_n = 0;
    sam->flag_c = 0;

    while (sam->pc != 0)
    {
        int result = sam_execute_instruction(sam);
        if (result != 0)
        {
            break;
        }
    }
    printf("done!\n");
}

int main(void)
{
    struct sam_machine sam;
    sam_init(&sam);
    sam_run(&sam);
    return 0;
}
