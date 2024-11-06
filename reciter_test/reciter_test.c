
// Test program for the SAM Reciter.

// The SAM Reciter has a subtle bug where it reads beyond the end of its input buffer,
// making its output depend on whatever happens to be in the the input buffer beyond
// the end of the input. Yikes!
//
// To show this, start a pristine copy of recite_test and enter "THE"
//
// ./recite_test --no-clear
// THE
// {THE} -> { DHAX}
//
// Here, "THE" is translated to " DHAX".
//
// Now, re-run and enter "THAW" followed by "THE":
//
// ./recite_test --no-clear
// THAW
// {THAW} -> { THAO5}
// THE
// {THE} -> { DHIY}
//
// Here, "THE" is translated to " DWIY" (!!!)
//
// To prevent this from happening, the 'reciter_test' program clears the SAM_BUFFER
// before reading a string to translate.
//
// This behavior can be overridden by giving the "--no-clear" flag to the 'reciter_test'
// program, so we can still demonstrate the faulty behavior.

#include <stdio.h>
#include <string.h>
#include <stdbool.h>

char SAM_BUFFER[256];

void RECITER_VIA_SAM_FROM_MACHINE_LANGUAGE(void); // Implemented in machine code.

static void fix_first_occurrence(char *s, char from, char to)
{
    while (*s != from)
    {
        ++s;
    }
    *s = to;
}

int main(int argc, char ** argv)
{
    int zero_flag = true;
    int i;

    for (i = 1; i < argc; ++i)
    {
        if (strcmp(argv[i], "--no-clear") == 0)
        {
            zero_flag = false;
        }
    }

    for (;;)
    {
        if (zero_flag)
        {
            // Zero the SAM_BUFFER to prevent dependency on whatever data
            // is present beyond the end-of-line marker.
            bzero(SAM_BUFFER, 256);
        }

        if (gets(SAM_BUFFER) == NULL)
        {
            // End-of-file encountered; stop.
            break;
        }

        // Print input.

        printf("{%s}", SAM_BUFFER);

        // Execute the SAM Reciter.

        fix_first_occurrence(SAM_BUFFER, 0x00, 0x9b); // Change ASCII NUL to Atari End-Of-Line
        RECITER_VIA_SAM_FROM_MACHINE_LANGUAGE();
        fix_first_occurrence(SAM_BUFFER, 0x9b, 0x00); // Change Atari End-Of-Line to ASCII NUL.

        // Print output for the SAM Reciter.

        printf(" -> {%s}\n", SAM_BUFFER);

    }
    return 0;
}
