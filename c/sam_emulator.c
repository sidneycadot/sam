
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <inttypes.h>
#include <stdbool.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint64_t u64;

#define MEM_SIZE 0x4651

struct audio_state
{
    bool active;
    u64  clock_offset;
};

void audio_init(struct audio_state * audio)
{
    audio->active = false;
    audio->clock_offset = 0;
}

void audio_write_sample(struct audio_state * audio, u64 clock, u8 value)
{
    assert( (16 <= value) && (value <= 31) );

    if (!audio->active)
    {
        audio->active = true;
        audio->clock_offset = clock;
    }

    printf("## %10lu %3u\n", clock - audio->clock_offset, value);
}

struct sam_virtual_machine {
    struct audio_state * audio; // Audio output device for writes to 0xd201.
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


void svm_init(struct sam_virtual_machine * svm, struct audio_state * audio)
{
    svm->audio = audio;

    svm->clocks = 0;
    svm->pc = 0;
    svm->sp = 0xff;
    svm->a = 0;
    svm->x = 0;
    svm->y = 0;
    svm->flag_n = 0;
    svm->flag_z = 1;
    svm->flag_c = 0;

    memset(svm->mem, 0, MEM_SIZE);

    // Read Atari SAM 6502 image into memory.
    FILE * f = fopen("sam_2000_4650.bin", "rb");
    assert(f != NULL);
    fread(&svm->mem[0x2000], 1, 9809, f);
    fclose(f);
}

static void svm_write_byte(struct sam_virtual_machine * svm, u16 address, u8 value)
{
    switch (address)
    {
        case 0xd201: // Process writes to the audio output hardware.
        {
            audio_write_sample(svm->audio, svm->clocks, value);
            return;
        }
        case 0xd20e: // Ignore writes to hardware addresses.
        case 0xd400:
        case 0xd40e: return;
    }

    // RAM write.
    assert(address < MEM_SIZE);
    svm->mem[address] = value;
}

static u8 svm_read_byte(struct sam_virtual_machine * svm, u16 address)
{
    assert(address < MEM_SIZE);
    return svm->mem[address];
}


static u16 svm_read_word(struct sam_virtual_machine * svm, u16 address)
{
    u8 lo = svm_read_byte(svm, address);
    u8 hi = svm_read_byte(svm, address + 1);
    return 0x100 * hi + lo;
}

static void svm_push_byte(struct sam_virtual_machine * svm, u8 value)
{
    svm->mem[0x100 + svm->sp] = value;
    --svm->sp;
}

static uint8_t svm_pop_byte(struct sam_virtual_machine * svm)
{
    ++svm->sp;
    return svm->mem[0x100 + svm->sp];
}

static void svm_push_word(struct sam_virtual_machine * svm, u16 value)
{
    //printf("push word: 0x%04x\n", value);
    svm_push_byte(svm, value / 256); // high byte is pushed before low byte.
    svm_push_byte(svm, value % 256);
}

static uint16_t svm_pop_word(struct sam_virtual_machine * svm)
{
    uint8_t lo = svm_pop_byte(svm); // lo byte is popped before high byte.
    uint8_t hi = svm_pop_byte(svm);

    //printf("pop word: 0x%04x\n", hi * 0x100 + lo);

    return hi * 0x100 + lo;
}

static void svm_update_nz_flags(struct sam_virtual_machine * svm, u8 value)
{
    svm->flag_z = (value == 0);
    svm->flag_n = (value & 0x80) != 0;
}

static bool svm_different_pages(uint16_t u1, uint16_t u2)
{
    return (u1 / 0x100) != (u2 / 0x100);
}

static void svm_branch_if(struct sam_virtual_machine * svm, unsigned condition)
{
    if (condition)
    {
        // branch taken.
        const u8 displacement = svm_read_byte(svm, svm->pc + 1);
        const u16 target = svm->pc + 2 + displacement - (((displacement & 0x80) != 0) ? 0x0100 : 0);
        svm->clocks += svm_different_pages(target, svm->pc) ? 4 : 3;
        svm->pc = target;
    }
    else
    {
        // branch not taken.
        svm->pc += 2;
        svm->clocks += 2;
    }
}

static void svm_set_a_register(struct sam_virtual_machine * svm, const u8 value)
{
    svm->a = value;
    svm_update_nz_flags(svm, value);
}

static void svm_set_x_register(struct sam_virtual_machine * svm, const u8 value)
{
    svm->x = value;
    svm_update_nz_flags(svm, value);
}

static void svm_set_y_register(struct sam_virtual_machine * svm, const u8 value)
{
    svm->y = value;
    svm_update_nz_flags(svm, value);
}

static void svm_add_with_carry(struct sam_virtual_machine * svm, u8 value)
{
    const u16 temp = (u16)(svm->a) + (u16)(value) + (u16)(svm->flag_c);
    svm_set_a_register(svm, temp & 0xff);
    svm->flag_c = (temp & 0x100) != 0;
}

static void svm_subtract_with_borrow(struct sam_virtual_machine * svm, u8 value)
{
    const u16 temp = (u16)(svm->a) - (u16)(value) - (u16)(!svm->flag_c);
    svm_set_a_register(svm, temp & 0xff);
    svm->flag_c = (temp & 0x100) == 0; // carry = !borrow.
}

static void svm_compare(struct sam_virtual_machine * svm, u8 register_value, u8 operand)
{
    const u8 difference = register_value - operand;
    svm->flag_c = (register_value >= operand);
    svm_update_nz_flags(svm, difference);
}

static void svm_execute_instruction(struct sam_virtual_machine * svm)
{
    const u8 instruction = svm_read_byte(svm, svm->pc);
    //printf("[%016" PRIx64 "] 0x%04x instruction: 0x%02x\n", svm->clocks, svm->pc, instruction);

    printf("@@ [%16lu] PC %04x OPC %02x A %02x X %02x Y %02x Z %u N %u C %u\n",
           svm->clocks,
           svm->pc, instruction, svm->a, svm->x, svm->y, svm->flag_z, svm->flag_n, svm->flag_c);

    switch (instruction)
    {
        case 0x06: // asl zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            u8 value = svm_read_byte(svm, zp_address);
            const u8 shift_out = (value & 0x80) != 0;
            value = (value << 1);
            svm_update_nz_flags(svm, value);
            svm->flag_c = shift_out;
            svm_write_byte(svm, zp_address, value);
            svm->pc += 2;
            svm->clocks += 5;
            break;
        }
        case 0x09: // ora #imm
        {
            const u8 operand = svm_read_byte(svm, svm->pc + 1);
            svm_set_a_register(svm, svm->a | operand);
            svm->pc += 2;
            svm->clocks += 2;
            break;
        }
        case 0x0a: // asl a
        {
            svm->flag_c = (svm->a & 0x80) != 0;
            svm_set_a_register(svm, svm->a << 1);
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0x10: // bpl rel
        {
            svm_branch_if(svm, svm->flag_n == 0);
            break;
        }
        case 0x18: // clc
        {
            svm->flag_c = 0;
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0x19: // ora abs,y
        {
            const u16 base_address = svm_read_word(svm, svm->pc + 1);
            const u16 abs_address = base_address + svm->y;
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_set_a_register(svm, svm->a | operand);
            svm->pc += 3;
            svm->clocks += svm_different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0x20: // jsr absolute
        {
            svm_push_word(svm, svm->pc + 2);
            svm->pc = svm_read_word(svm, svm->pc + 1);
            svm->clocks += 6;
            break;
        }
        case 0x24: // bit zpage
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            const u8 operand = svm_read_byte(svm, zp_address);
            svm->flag_n = (operand & 0x80) != 0;
            svm->flag_z = (operand & svm->a) == 0;
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0x29: // and #imm
        {
            const u8 operand = svm_read_byte(svm, svm->pc + 1);
            svm_set_a_register(svm, svm->a & operand);
            svm->pc += 2;
            svm->clocks += 2;
            break;
        }
        case 0x2a: // rol a
        {
            const u8 shift_out = (svm->a & 0x80) != 0;
            svm_set_a_register(svm, (svm->a << 1) | svm->flag_c);
            svm->flag_c = shift_out;
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0x30: // bmi rel
        {
            svm_branch_if(svm, svm->flag_n != 0);
            break;
        }
        case 0x38: // sec
        {
            svm->flag_c = 1;
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0x49: // eor #imm
        {
            const u8 operand = svm_read_byte(svm, svm->pc + 1);
            svm_set_a_register(svm, svm->a ^ operand);
            svm->pc += 2;
            svm->clocks += 2;
            break;
        }
        case 0x4a: // lsr a
        {
            const u8 shift_out = svm->a & 0x01;
            svm_set_a_register(svm, svm->a >> 1);
            svm->flag_c = shift_out;
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0x4c: // jmp absolute
        {
            svm->pc = svm_read_word(svm, svm->pc + 1);
            svm->clocks += 3;
            break;
        }
        case 0x60: // rts
        {
            svm->pc = svm_pop_word(svm) + 1;
            svm->clocks += 6;
            break;
        }
        case 0x65: // adc zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            const u8 operand = svm_read_byte(svm, zp_address);
            svm_add_with_carry(svm, operand);
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0x69: // adc #imm
        {
            const u8 operand = svm_read_byte(svm, svm->pc + 1);
            svm_add_with_carry(svm, operand);
            svm->pc += 2;
            svm->clocks += 2;
            break;
        }
        case 0x79: // adc abs,y
        {
            const u16 base_address = svm_read_word(svm, svm->pc + 1);
            const u16 abs_address = base_address + svm->y;
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_add_with_carry(svm, operand);
            svm->pc += 3;
            svm->clocks += svm_different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0x7d: // adc abs,x
        {
            const u16 base_address = svm_read_word(svm, svm->pc + 1);
            const u16 abs_address = base_address + svm->x;
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_add_with_carry(svm, operand);
            svm->pc += 3;
            svm->clocks += svm_different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0x84: // sty zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            svm_write_byte(svm, zp_address, svm->y);
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0x85: // sta zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            svm_write_byte(svm, zp_address, svm->a);
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0x86: // stx zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            svm_write_byte(svm, zp_address, svm->x);
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0x88: // dey
        {
            svm_set_y_register(svm, svm->y - 1);
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0x8a: // txa
        {
            svm_set_a_register(svm, svm->x);
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0x8d: // sta abs
        {
            const u16 abs_address = svm_read_word(svm, svm->pc + 1);
            svm_write_byte(svm, abs_address, svm->a);
            svm->pc += 3;
            svm->clocks += 4;
            break;
        }
        case 0x8e: // stx abs
        {
            const u16 abs_address = svm_read_word(svm, svm->pc + 1);
            svm_write_byte(svm, abs_address, svm->x);
            svm->pc += 3;
            svm->clocks += 4;
            break;
        }
        case 0x90: // bcc rel
        {
            svm_branch_if(svm, svm->flag_c == 0);
            break;
        }
        case 0x91: // sta (zp),y
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            assert(zp_address != 0xff);
            const u16 base_address = svm_read_word(svm, zp_address);
            const u16 abs_address = base_address + svm->y;
            svm_write_byte(svm, abs_address, svm->a);
            svm->pc += 2;
            svm->clocks += 6;
            break;
        }
        case 0x95: // sta zp,x
        {
            const u8 base_address = svm_read_byte(svm, svm->pc + 1);
            const u8 zp_address = base_address + svm->x;
            svm_write_byte(svm, zp_address, svm->a);
            svm->pc += 2;
            svm->clocks += 4;
            break;
        }
        case 0x98: // tya
        {
            svm_set_a_register(svm, svm->y);
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0x99: // sta abs,y
        {
            const u16 base_address = svm_read_word(svm, svm->pc + 1);
            const u16 abs_address = base_address + svm->y;
            svm_write_byte(svm, abs_address, svm->a);
            svm->pc += 3;
            svm->clocks += 5; // sim65 is wrong here; the instruction does not take an extra cycle on a page boundary crossing.
            break;
        }
        case 0x9d: // sta abs,x
        {
            const u16 base_address = svm_read_word(svm, svm->pc + 1);
            const u16 abs_address = base_address + svm->x;
            svm_write_byte(svm, abs_address, svm->a);
            svm->pc += 3;
            svm->clocks += 5; // sim65 is wrong here; the instruction does not take an extra cycle on a page boundary crossing.
            break;
        }
        case 0xa0: // ldy #imm
        {
            const u8 operand = svm_read_byte(svm, svm->pc + 1);
            svm_set_y_register(svm, operand);
            svm->pc += 2;
            svm->clocks += 2;
            break;
        }
        case 0xa2: // ldx #imm
        {
            const u8 operand = svm_read_byte(svm, svm->pc + 1);
            svm_set_x_register(svm, operand);
            svm->pc += 2;
            svm->clocks += 2;
            break;
        }
        case 0xa4: // ldy zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            const u8 operand = svm_read_byte(svm, zp_address);
            svm_set_y_register(svm, operand);
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0xa5: // lda zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            const u8 operand = svm_read_byte(svm, zp_address);
            svm_set_a_register(svm, operand);
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0xa6: // ldx zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            const u8 operand = svm_read_byte(svm, zp_address);
            svm_set_x_register(svm, operand);
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0xa8: // tay
        {
            svm_set_y_register(svm, svm->a);
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0xa9: // lda #imm
        {
            const u8 operand = svm_read_byte(svm, svm->pc + 1);
            svm_set_a_register(svm, operand);
            svm->pc += 2;
            svm->clocks += 2;
            break;
        }
        case 0xaa: // tax
        {
            svm_set_x_register(svm, svm->a);
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0xad: // lda abs
        {
            const u16 abs_address = svm_read_word(svm, svm->pc + 1);
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_set_a_register(svm, operand);
            svm->pc += 3;
            svm->clocks += 4;
            break;
        }
        case 0xae: // ldx abs
        {
            const u16 abs_address = svm_read_word(svm, svm->pc + 1);
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_set_x_register(svm, operand);
            svm->pc += 3;
            svm->clocks += 4;
            break;
        }
        case 0xb0: // bcs rel
        {
            svm_branch_if(svm, svm->flag_c != 0);
            break;
        }
        case 0xb1: // lda (zp),y
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            assert(zp_address != 0xff);
            const u16 base_address = svm_read_word(svm, zp_address);
            const u16 abs_address = base_address + svm->y;
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_set_a_register(svm, operand);
            svm->pc += 2;
            svm->clocks += svm_different_pages(base_address, abs_address) ? 6 : 5;
            break;
        }
        case 0xb5: // lda zp,x
        {
            const u8 zp_base_address = svm_read_byte(svm, svm->pc + 1);
            const u8 zp_address = zp_base_address + svm->x;
            const u8 operand = svm_read_byte(svm, zp_address);
            svm_set_a_register(svm, operand);
            svm->pc += 2;
            svm->clocks += 4;
            break;
        }
        case 0xb9: // lda abs,y
        {
            const u16 base_address = svm_read_word(svm, svm->pc + 1);
            const u16 abs_address = base_address + svm->y;
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_set_a_register(svm, operand);
            svm->pc += 3;
            svm->clocks += svm_different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0xbc: // ldy abs,x
        {
            const u16 base_address = svm_read_word(svm, svm->pc + 1);
            const u16 abs_address = base_address + svm->x;
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_set_y_register(svm, operand);
            svm->pc += 3;
            svm->clocks += svm_different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0xbd: // lda abs,x
        {
            const u16 base_address = svm_read_word(svm, svm->pc + 1);
            const u16 abs_address = base_address + svm->x;
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_set_a_register(svm, operand);
            svm->pc += 3;
            svm->clocks += svm_different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0xc0: // cpy #imm
        {
            const u8 operand = svm_read_byte(svm, svm->pc + 1);
            svm_compare(svm, svm->y, operand);
            svm->pc += 2;
            svm->clocks += 2;
            break;
        }
        case 0xc5: // cmp zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            const u8 operand = svm_read_byte(svm, zp_address);
            svm_compare(svm, svm->a, operand);
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0xc6: // dec zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            const u8 value = svm_read_byte(svm, zp_address) - 1;
            svm_write_byte(svm, zp_address, value);
            svm_update_nz_flags(svm, value);
            svm->pc += 2;
            svm->clocks += 5;
            break;
        }
        case 0xc8: // iny
        {
            svm_set_y_register(svm, svm->y + 1);
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0xc9: // cmp #imm
        {
            const u8 operand = svm_read_byte(svm, svm->pc + 1);
            svm_compare(svm, svm->a, operand);
            svm->pc += 2;
            svm->clocks += 2;
            break;
        }
        case 0xca: // dex
        {
            svm_set_x_register(svm, svm->x - 1);
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0xd0: // bne rel
        {
            svm_branch_if(svm, svm->flag_z == 0);
            break;
        }
        case 0xd9: // cmp abs,y
        {
            const u16 base_address = svm_read_word(svm, svm->pc + 1);
            const u16 abs_address = base_address + svm->y;
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_compare(svm, svm->a, operand);
            svm->pc += 3;
            svm->clocks += svm_different_pages(base_address, abs_address) ? 5 : 4;
            break;
        }
        case 0xe4: // cpx zpage
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            const u8 operand = svm_read_byte(svm, zp_address);
            svm_compare(svm, svm->x, operand);
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0xe5: // sbc zpage
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            const u8 operand = svm_read_byte(svm, zp_address);
            svm_subtract_with_borrow(svm, operand);
            svm->pc += 2;
            svm->clocks += 3;
            break;
        }
        case 0xe6: // inc zp
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            const u8 value = svm_read_byte(svm, zp_address) + 1;
            svm_write_byte(svm, zp_address, value);
            svm_update_nz_flags(svm, value);
            svm->pc += 2;
            svm->clocks += 5;
            break;
        }
        case 0xe8: // inx
        {
            svm_set_x_register(svm, svm->x + 1);
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0xe9: // sbc #imm
        {
            const u8 operand = svm_read_byte(svm, svm->pc + 1);
            svm_subtract_with_borrow(svm, operand);
            svm->pc += 2;
            svm->clocks += 2;
            break;
        }
        case 0xea: // nop
        {
            svm->pc += 1;
            svm->clocks += 2;
            break;
        }
        case 0xf0: // beq rel
        {
            svm_branch_if(svm, svm->flag_z != 0);
            break;
        }
        case 0xf1: // sbc (zp),y
        {
            const u8 zp_address = svm_read_byte(svm, svm->pc + 1);
            assert(zp_address != 0xff);
            const u16 base_address = svm_read_word(svm, zp_address);
            const u16 abs_address = base_address + svm->y;
            const u8 operand = svm_read_byte(svm, abs_address);
            svm_subtract_with_borrow(svm, operand);
            svm->pc += 2;
            svm->clocks += svm_different_pages(base_address, abs_address) ? 6 : 5;
            break;
        }
        default:
        {
            assert(false); // Unhandled 6502 opcode.
        }
    }
}

void run_sam(void)
{
    struct audio_state audio;
    struct sam_virtual_machine svm;

    audio_init(&audio);
    svm_init(&svm, &audio);

    // Perform a virtual JSR to the entry point of SAM, with return address zero.
    svm_push_word(&svm, 0xffff); // The final RTS will return to address 0.
    svm.pc = 0x2004;// SAM entry point (change to 0x2004).

    // Run the SAM virtual machine until it returns to address PC = 0.
    while (svm.pc != 0)
    {
        svm_execute_instruction(&svm);
    }
    printf("** Returned from 6502 SAM.\n");
}

int main(void)
{
    run_sam();
    return 0;
}
