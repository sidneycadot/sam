
; List of Atari addresses used in the Atari version of SAM.

; First half of page zero (0x00..0x7F): Operating System zero page addresses

        .exportzp WARMST := $08           ; WARMSTART flag.
        .exportzp POKMSK := $10           ; IRQEN shadow register.
        .exportzp RTCLOK := $12           ; VBLANK clock (50/60 Hz).

; Second half of page zero (0x80..0xFF): BASIC zero page addresses

        .exportzp VNTP   := $82           ; BASIC variable name table.
        .exportzp VNTD   := $84           ; BASIC variable name table end.
        .exportzp VVTP   := $86           ; BASIC variable value table.
        .exportzp STARP  := $8C           ; BASIC string and array table.

; Pages two to five (0x200..0x5FF): operating system variables

        .export RUNAD  := $2E0          ; DOS run address.
        .export INITAD := $2E2          ; DOS initialization address.
        .export MEMLO  := $2E7          ; OS memory-low-boundary pointer.

; CARTRIDGE A (0xA000..0xBFFF): Atari BASIC

        .export BASIC  := $A000          ; BASIC entry point.

; CTIA / GTIA (0xD000 .. 0xD01F)

        .export CONSOL := $D01F         ; Speaker click.

; POKEY (0xD200..0xD20F)

        .export AUDC1 := $D201          ; Audio Channel #1 control.
        .export IRQEN := $D20E          ; IRQ enabled mask.

; ANTIC (0xD400..0xD40F)

        .export DMACTL := $D400         ; DMA enabled mask.
        .export NMIEN  := $D40E         ; NMI enabled mask.
