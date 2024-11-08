
#include <assert.h>
#include <stdio.h>
#include <inttypes.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint64_t u64;

#define MEM_SIZE 0x5000

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

void sam_write_byte(struct sam_machine * sam, u16 address, u8 value)
{
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

int sam_execute_instruction(struct sam_machine * sam)
{
    const u8 instruction = sam_read_byte(sam, sam->pc);
    printf("[%16lu] 0x%04x instruction: 0x%02x\n", sam->clocks, sam->pc, instruction);

    switch (instruction)
    {
        case 0x20: // jsr absolute
        {
            const u16 target = sam_read_word(sam, sam->pc + 1);
            // Push (PC + 1) onto the stack.
            sam_push_word(sam, sam->pc + 2);
            sam->pc = target;
            sam->clocks += 6;
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
        case 0x38: // sec
        {
            sam->flag_c = 1;
            sam->pc += 2;
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
            sam->flag_c = (sam->y >= value); // TODO: check.
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
            sam->flag_c = (sam->a >= value); // TODO: check.
            sam_update_nz_flags(sam, difference);
            sam->pc += 2;
            sam->clocks += 3;
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
            sam->flag_c = (sam->a >= value); // TODO: check.
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
            sam->flag_c = (sam->x >= value); // TODO: check.
            sam_update_nz_flags(sam, difference);
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
        case 0xf0: // beq rel
        {
            sam_branch_if(sam, sam->flag_z != 0);
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
    sam->pc = 0x2004;
    sam->flag_z = 0;
    sam->flag_n = 0;
    sam->flag_c = 0;

    for (;;)
    {
        int result = sam_execute_instruction(sam);
        if (result != 0)
        {
            break;
        }
    }
}

int main(void)
{
    struct sam_machine sam;
    sam_init(&sam);
    sam_run(&sam);
    return 0;
}
