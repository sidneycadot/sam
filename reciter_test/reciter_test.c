
// Test program for the SAM reciter.

#include <stdio.h>

char SAM_BUFFER[256];

void RECITER_VIA_SAM_FROM_MACHINE_CODE(void); // Implemented in machine code.

static void fix_first_occurrence(char *s, char from, char to)
{
    while (*s != from)
    {
        ++s;
    }
    *s = to;
}

int main(void)
{
    while (gets(SAM_BUFFER) != NULL)
    {
        printf("{%s}", SAM_BUFFER);

        // Execute the RECITER.

        fix_first_occurrence(SAM_BUFFER, 0x00, 0x9b); // Change ASCII NUL to Atari End-Of-Line
        RECITER_VIA_SAM_FROM_MACHINE_CODE();
        fix_first_occurrence(SAM_BUFFER, 0x9b, 0x00); // Change Atari End-Of-Line to ASCII NUL.

        printf(" -> {%s}\n", SAM_BUFFER);
    }
    return 0;
}
