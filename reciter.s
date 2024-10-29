
; Source code for the SAM reciter.
;
; The "reciter" program performs English-to-SAM phoneme translation.
;
; It is designed to be called through entry points in the SAM program.

; ----------------------------------------------------------------------------

        .setcpu "6502"

; ----------------------------------------------------------------------------

        .import __RECITER_BLOCK1_LOAD__, __RECITER_BLOCK1_SIZE__
        .import __RECITER_BLOCK2_LOAD__, __RECITER_BLOCK2_SIZE__

; ----------------------------------------------------------------------------

        .import SAM_BUFFER                      ; 256-byte buffer where SAM receives its phoneme representation to be rendered as sound.
        .import SAM_SAY_PHONEMES                ; Play the phonemes in SAM_BUFFER as sound.
        .import SAM_COPY_BASIC_SAM_STRING       ; Routine to find and copy SAM$ into the SAM_BUFFER.
        .import SAM_SAVE_ZP_ADDRESSES           ; Save zero-page addresses used by SAM.
        .import SAM_ERROR_SOUND                 ; Routine to signal error using a distinctive error sound.

; ----------------------------------------------------------------------------

        .export RECITER_VIA_SAM_FROM_BASIC
        .export RECITER_VIA_SAM_FROM_MACHINE_CODE

; ----------------------------------------------------------------------------

        .segment "RECITER_BLOCK1_HEADER"

        ; This is the Atari executable header for the first block, containing the reciter code and data.

        .word   $ffff
        .word   __RECITER_BLOCK1_LOAD__
        .word   __RECITER_BLOCK1_LOAD__ + __RECITER_BLOCK1_SIZE__ - 1

        .segment "RECITER_BLOCK1"

RECITER_BUFFER: .res 256, 0

        .byte "COPYRIGHT 1982 DON'T ASK"

        ; Properties of the 96 characters we support.

CHARACTER_PROPERTY:

        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$02,$02,$02,$02,$02,$02,$82
        .byte   $00,$00,$02,$02,$02,$02,$02,$02
        .byte   $03,$03,$03,$03,$03,$03,$03,$03
        .byte   $03,$03,$02,$02,$02,$02,$02,$02
        .byte   $02,$C0,$A8,$B0,$AC,$C0,$A0,$B8
        .byte   $A0,$C0,$BC,$A0,$AC,$A8,$AC,$C0
        .byte   $A0,$A0,$AC,$B4,$A4,$C0,$A8,$A8
        .byte   $B0,$C0,$BC,$00,$00,$00,$02,$00

; ----------------------------------------------------------------------------

RECITER_VIA_SAM_FROM_BASIC:

        ; Reciter when entered from BASIC, through a call to the USR(8200) function.
        ; When entering here, the number of arguments is already popped from the 6502 stack.

        jsr     SAM_COPY_BASIC_SAM_STRING       ; Find and copy SAM$.

RECITER_VIA_SAM_FROM_MACHINE_CODE:

        ; Reciter when entered from machine code.
        ; When entering, the string to be translated should be in the SAM_BUFFER.

        jsr     SAM_SAVE_ZP_ADDRESSES           ; Save ZP registers.

        ; Copy content of SAM buffer to RECITER buffer, with some character remapping.

        ; The translation performed maps the 32 highest ASCII characters (which include the lowercase letters)
        ; down by 32.
        ;
        ; Consequences:
        ;
        ; `   (backtick)            maps to @ sign.
        ; a-z (lowercase letters)   map  to A-Z.
        ; {   (curly bracket open)  maps to '[' (angle bracket open).
        ; |   (pipe)                maps to '\' (backslash).
        ; }   (curly bracket close) maps to ']' (angle bracket close).
        ; ~   (tilde)               maps to '^' (caret).
        ; DEL (0x7f)                maps to '_' (underscore).
        ;
        ; What remains are 96 characters that need to be handled:
        ;
        ; * 32 ASCII control characters 0x00 .. 0x1f
        ; * 16 characters ' ' (space), '!', '"', '#', '$', '%', '&', single-quote, '(', ')', '*', '+', ',', '-', '.', '/'
        ; * 10 characters '0' .. '9'.
        ; *  7 characters ':', ';', '<', '=', '>', '?', '@'
        ; * 26 characters 'A' .. 'Z'
        ; *  5 characters '[', '\', ']', '^', '_'

        lda     #' '                            ; Put a space character at the start of the RECITER buffer.
        sta     RECITER_BUFFER                  ;
        ldx     #1                              ; Prepare character copy loop.
        ldy     #0                              ;
@loop:  lda     SAM_BUFFER,y                    ; Start of character copy loop; load character.

        and     #$7F                            ; Set most significant bit of character to zero.
        cmp     #$70                            ;
        bcc     @1                              ;
        and     #$5F                            ; Characters $70..$7F: zero bit #5.
        jmp     @2                              ;
@1:     cmp     #$60                            ;
        bcc     @2                              ;
        and     #$4F                            ; Characters $60..$6F: zero bits #4 and #5.

@2:     sta     RECITER_BUFFER,x                ; Store sanitized character and proceed to the next one.
        inx                                     ;
        iny                                     ;
        cpy     #$FF                            ;
        bne     @loop                           ; End of character copy loop.

        ldx     #$FF                            ;
        lda     #$1B                            ; Store escape character at the end of the RECITER buffer.
        sta     RECITER_BUFFER,x                ;

        jsr     SUB_ENGLISH_TO_PHONEMES         ;

; ----------------------------------------------------------------------------

SUB_473E_SAY_PHONEMES:

        jsr     SAM_SAY_PHONEMES                ; Call subroutine in SAM.
        rts                                     ; Done.

; ----------------------------------------------------------------------------

SUB_ENGLISH_TO_PHONEMES:

        ; Translate English text in the RECITER_BUFFER to phonemes in the SAM_BUFFER.

        lda     #$FF                            ;
        sta     $FA                             ;
L4746:  lda     #$FF                            ;
        sta     $F5                             ;

L474A:  inc     $FA                             ;
        ldx     $FA                             ;
        lda     RECITER_BUFFER,x                ;
        sta     $FD                             ;
        cmp     #$1B                            ; Compare to the escape character.
        bne     @1                              ;
        inc     $F5                             ;
        ldx     $F5                             ;
        lda     #$9B                            ; Store end-of-line character to SAM buffer.
        sta     SAM_BUFFER,x                    ;
        rts                                     ;

@1:     cmp     #'.'                            ;
        bne     @2                              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        tay                                     ;
        lda     CHARACTER_PROPERTY,y            ;
        and     #$01                            ;
        bne     @2                              ;
        inc     $F5                             ;
        ldx     $F5                             ;
        lda     #'.'                            ; Store period character to SAM buffer.
        sta     SAM_BUFFER,x                    ;
        jmp     L474A                           ;

@2:     lda     $FD                             ;
        tay                                     ;
        lda     CHARACTER_PROPERTY,y            ;
        sta     $F6                             ;
        and     #$02                            ;
        beq     @3                              ;
        lda     #<PTAB_MISC                     ; Try to match miscellaneous pronunciation rules.
        sta     $FB                             ;
        lda     #>PTAB_MISC                     ;
        sta     $FC                             ;
        jmp     MATCH_NEXT                      ;

@3:     lda     $F6                             ;
        bne     L47C3                           ;
        lda     #$20                            ;
        sta     RECITER_BUFFER,x                ;
        inc     $F5                             ;
        ldx     $F5                             ;
        cpx     #$78                            ;
        bcs     L47AC                           ;
        sta     SAM_BUFFER,x                    ;
        jmp     L474A                           ;

; ----------------------------------------------------------------------------

SAVE_FA: .byte 0                                ; Temporary storage for $FA.

L47AC:  lda     #$9B                            ;
        sta     SAM_BUFFER,x                    ;
        lda     $FA                             ;
        sta     SAVE_FA                         ;
        sta     $CD                             ;
        jsr     SUB_473E_SAY_PHONEMES           ;
        lda     SAVE_FA                         ;
        sta     $FA                             ;
        jmp     L4746                           ;

; ----------------------------------------------------------------------------

L47C3:  lda     $F6                             ; Verify that $F6 contains a value with its most significant bit set.
        and     #$80                            ;
        bne     @1                              ;
        brk                                     ; Abort.

@1:     lda     $FD                             ; Load the character to be processed from $FD.
        sec                                     ; Set ($FB, $FC) pointer to the table entry corresponding to the letter.
        sbc     #'A'                            ;
        tax                                     ;
        lda     PTAB_INDEX_LO,x                 ;
        sta     $FB                             ;
        lda     PTAB_INDEX_HI,x                 ;
        sta     $FC                             ;

        ; Pattern matching loop.

MATCH_NEXT:

        ldy     #0                              ; Set Y=0 for accessing ($FB, $FC) later on.

@1:     clc                                     ; Increment the ($FB, $FC) pointer by one.
        lda     $FB                             ;
        adc     #<1                             ;
        sta     $FB                             ;
        lda     $FC                             ;
        adc     #>1                             ;
        sta     $FC                             ;
        lda     ($FB),y                         ; Load byte at address pointed to by ($FB, $FC).
        bpl     @1                              ; Repeat increment until we find a value with its most significant bit set.

        iny                                     ;
@2:     lda     ($FB),y                         ; Find parenthesis-open character.
        cmp     #'('                            ; Is $(FB),Y a parenthesis-open character?
        beq     L47F8                           ; Yes -- goto L47F8.
        iny                                     ; No -- increment Y, then retry.
        jmp     @2

; ----------------------------------------------------------------------------

        ; A parenthesis-open was found.

L47F8:  sty     $FF                             ;
@1:     iny                                     ;
        lda     ($FB),y                         ;
        cmp     #')'                            ;
        bne     @1                              ;
        sty     $FE                             ;
@2:     iny                                     ;
        lda     ($FB),y                         ;
        and     #$7F                            ;
        cmp     #'='                            ;
        bne     @2                              ;
        sty     $FD                             ;
        ldx     $FA                             ;
        stx     $F9                             ;
        ldy     $FF                             ;
        iny                                     ;
@3:     lda     RECITER_BUFFER,x                ;
        sta     $F6                             ;
        lda     ($FB),y                         ;
        cmp     $F6                             ;
        beq     @4                              ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

@4:     iny                                     ;
        cpy     $FE                             ;
        bne     @5                              ;
        jmp     @6                              ;

; ----------------------------------------------------------------------------

@5:     inx                                     ;
        stx     $F9                             ;
        jmp     @3                              ;

; ----------------------------------------------------------------------------

@6:     lda     $FA                             ;
        sta     $F8                             ;
L4835:  ldy     $FF                             ;
        dey                                     ;
        sty     $FF                             ;
        lda     ($FB),y                         ;
        sta     $F6                             ;
        bpl     L4843                           ;
        jmp     L49BA                           ;

; ----------------------------------------------------------------------------

L4843:  and     #$7F                            ;
        tax                                     ;
        lda     CHARACTER_PROPERTY,x            ;
        and     #$80                            ;
        beq     SW1_485F                        ;
        ldx     $F8                             ;
        dex                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     $F6                             ;
        beq     @1                              ;
        jmp     MATCH_NEXT                      ;

@1:     stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

SW1_485F:

        lda     $F6                             ; Switch on content of $F6.
        cmp     #' '                            ; Handle ' ' character.
        bne     @1                              ;
        jmp     SW1_SPACE                       ;
@1:     cmp     #'#'                            ; Handle '#' character.
        bne     @2                              ;
        jmp     SW1_HASH                        ;
@2:     cmp     #'.'                            ; Handle '.' character.
        bne     @3                              ;
        jmp     SW1_PERIOD                      ;
@3:     cmp     #'&'                            ; Handle '&' character.
        bne     @4                              ;
        jmp     SW1_AMPERSAND                   ;
@4:     cmp     #'@'                            ; Handle '@' character.
        bne     @5                              ;
        jmp     SW1_AT_SIGN                     ;
@5:     cmp     #'^'                            ; Handle '^' character.
        bne     @6                              ;
        jmp     SW1_CARET                       ;
@6:     cmp     #'+'                            ; Handle '+' character.
        bne     @7                              ;
        jmp     SW1_PLUS                        ;
@7:     cmp     #':'                            ; Handle ':' character.
        bne     @8                              ;
        jmp     SW1_COLON                       ;
@8:     jsr     SAM_ERROR_SOUND                 ; Any other character: signal error.
        brk                                     ; Abort.

; ----------------------------------------------------------------------------

SW1_SPACE:

        jsr     SUB_493D                        ;
        and     #$80                            ;
        beq     L48A7                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

L48A7:  stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

SW1_HASH:

        jsr     SUB_493D                        ;
        and     #$40                            ;
        bne     L48A7                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

SW1_PERIOD:

        jsr     SUB_493D                        ;
        and     #$08                            ;
        bne     L48C0                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

L48C0:  stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

SW1_AMPERSAND:

        jsr     SUB_493D                        ;
        and     #$10                            ;
        bne     L48C0                           ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     L48D6                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

L48D6:  dex                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'C'                            ;
        beq     L48C0                           ;
        cmp     #'S'                            ;
        beq     L48C0                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

SW1_AT_SIGN:

        jsr     SUB_493D                        ;
        and     #$04                            ;
        bne     L48C0                           ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     MATCH_NEXT                      ;

@1:     cmp     #'T'                            ;
        beq     @2                              ;
        cmp     #'C'                            ;
        beq     @2                              ;
        cmp     #'S'                            ;
        beq     @2                              ;
        jmp     MATCH_NEXT                      ;

@2:     stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

SW1_CARET:

        jsr     SUB_493D                        ;
        and     #$20                            ;
        bne     L4914                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

L4914:  stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

SW1_PLUS:

        ldx     $F8                             ;
        dex                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'E'                            ;
        beq     L4914                           ;
        cmp     #'I'                            ;
        beq     L4914                           ;
        cmp     #'Y'                            ;
        beq     L4914                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

SW1_COLON:

        jsr     SUB_493D                        ;
        and     #$20                            ;
        bne     @1                              ;
        jmp     L4835                           ;

@1:     stx     $F8                             ;
        jmp     SW1_COLON                       ;

; ----------------------------------------------------------------------------

SUB_493D:

        ldx     $F8                             ;
        dex                                     ;
        lda     RECITER_BUFFER,x                ;
        tay                                     ;
        lda     CHARACTER_PROPERTY,y            ;
        rts                                     ;

; ----------------------------------------------------------------------------

SUB_4948:

        ldx     $F7                             ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        tay                                     ;
        lda     CHARACTER_PROPERTY,y            ;
        rts                                     ;

; ----------------------------------------------------------------------------

SW2_PERCENT:

        ldx     $F7                             ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'E'                            ;
        bne     L49A3                           ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        tay                                     ;
        dex                                     ;
        lda     CHARACTER_PROPERTY,y            ;
        and     #$80                            ;
        beq     L4972                           ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'R'                            ;
        bne     L4977                           ;

L4972:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

L4977:  cmp     #'S'                            ;
        beq     L4972                           ;
        cmp     #'D'                            ;
        beq     L4972                           ;
        cmp     #'L'                            ;
        bne     L498D                           ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'Y'                            ;
        bne     L49B7                           ;
        beq     L4972                           ;
L498D:  cmp     #'F'                            ;
        bne     L49B7                           ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'U'                            ;
        bne     L49B7                           ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'L'                            ;
        beq     L4972                           ;
        bne     L49B7                           ;
L49A3:  cmp     #'I'                            ;
        bne     L49B7                           ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'N'                            ;
        bne     L49B7                           ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'G'                            ;
        beq     L4972                           ;
L49B7:  jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

L49BA:  lda     $F9                             ;
        sta     $F7                             ;
L49BE:  ldy     $FE                             ;
        iny                                     ;
        cpy     $FD                             ;
        bne     @1                              ;
        jmp     L4ACD                           ;

@1:     sty     $FE                             ;
        lda     ($FB),y                         ;
        sta     $F6                             ;
        tax                                     ;
        lda     CHARACTER_PROPERTY,x            ;
        and     #$80                            ;
        beq     SW2_49E8                        ;
        ldx     $F7                             ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     $F6                             ;
        beq     L49E3                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

L49E3:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

SW2_49E8:

        lda     $F6                             ; Switch on content of $F5.
        cmp     #' '                            ; Handle ' ' character.
        bne     @1                              ;
        jmp     SW2_SPACE                       ;
@1:     cmp     #'#'                            ; Handle '#' character.
        bne     @2                              ;
        jmp     SW2_HASH                        ;
@2:     cmp     #'.'                            ; Handle '.' character.
        bne     @3                              ;
        jmp     SW2_PERIOD                      ;
@3:     cmp     #'&'                            ; Handle '&' character.
        bne     @4                              ;
        jmp     SW2_AMPERSAND                   ;
@4:     cmp     #'@'                            ; Handle '@' character.
        bne     @5                              ;
        jmp     SW2_AT_SIGN                     ;
@5:     cmp     #'^'                            ; Handle '^' character.
        bne     @6                              ;
        jmp     SW2_CARET                       ;
@6:     cmp     #'+'                            ; Handle '+' character.
        bne     @7                              ;
        jmp     SW2_PLUS                        ;
@7:     cmp     #':'                            ; Handle ':' character.
        bne     @8                              ;
        jmp     SW2_COLON                       ;
@8:     cmp     #'%'                            ; Handle '%' character.
        bne     @9                              ;
        jmp     SW2_PERCENT                     ;
@9:     jsr     SAM_ERROR_SOUND                 ; Any other character: signal error.
        brk                                     ; Abort.

; ----------------------------------------------------------------------------

SW2_SPACE:

        jsr     SUB_4948                        ;
        and     #$80                            ;
        beq     L4A37                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

L4A37:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

SW2_HASH:

        jsr     SUB_4948                        ;
        and     #$40                            ;
        bne     L4A37                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

SW2_PERIOD:

        jsr     SUB_4948                        ;
        and     #$08                            ;
        bne     L4A50                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

L4A50:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

SW2_AMPERSAND:

        jsr     SUB_4948                        ;
        and     #$10                            ;
        bne     L4A50                           ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     MATCH_NEXT                      ;

@1:     inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'C'                            ;
        beq     L4A50                           ;
        cmp     #'S'                            ;
        beq     L4A50                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

SW2_AT_SIGN:

        jsr     SUB_4948                        ;
        and     #$04                            ;
        bne     L4A50                           ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     MATCH_NEXT                      ;

@1:     cmp     #'T'                            ;
        beq     @2                              ;
        cmp     #'C'                            ;
        beq     @2                              ;
        cmp     #'S'                            ;
        beq     @2                              ;
        jmp     MATCH_NEXT                      ;

@2:     stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

SW2_CARET:

        jsr     SUB_4948                        ;
        and     #$20                            ;
        bne     L4AA4                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

L4AA4:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

SW2_PLUS:

        ldx     $F7                             ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'E'                            ;
        beq     L4AA4                           ;
        cmp     #'I'                            ;
        beq     L4AA4                           ;
        cmp     #'Y'                            ;
        beq     L4AA4                           ;
        jmp     MATCH_NEXT                      ;

; ----------------------------------------------------------------------------

SW2_COLON:

        jsr     SUB_4948                        ;
        and     #$20                            ;
        bne     @1                              ;
        jmp     L49BE                           ;

@1:     stx     $F7                             ;
        jmp     SW2_COLON                       ;

; ----------------------------------------------------------------------------

L4ACD:  ldy     $FD                             ;
        lda     $F9                             ;
        sta     $FA                             ;
@1:     lda     ($FB),y                         ;
        sta     $F6                             ;
        and     #$7F                            ;
        cmp     #'='                            ;
        beq     @2                              ;
        inc     $F5                             ;
        ldx     $F5                             ;
        sta     SAM_BUFFER,x                    ;
@2:     bit     $F6                             ;
        bpl     @3                              ;
        jmp     L474A                           ;

@3:     iny                                     ;
        jmp     @1                              ;

; ----------------------------------------------------------------------------

PTAB_INDEX_LO:                  ; LSB of starting address of pronunciation rules specific to A..Z.

        .lobytes   PTAB_A,PTAB_B,PTAB_C,PTAB_D,PTAB_E,PTAB_F,PTAB_G,PTAB_H,PTAB_I,PTAB_J,PTAB_K,PTAB_L,PTAB_M
        .lobytes   PTAB_N,PTAB_O,PTAB_P,PTAB_Q,PTAB_R,PTAB_S,PTAB_T,PTAB_U,PTAB_V,PTAB_W,PTAB_X,PTAB_Y,PTAB_Z

PTAB_INDEX_HI:                  ; MSB of starting address of pronunciation rules specific to A..Z.

        .hibytes   PTAB_A,PTAB_B,PTAB_C,PTAB_D,PTAB_E,PTAB_F,PTAB_G,PTAB_H,PTAB_I,PTAB_J,PTAB_K,PTAB_L,PTAB_M
        .hibytes   PTAB_N,PTAB_O,PTAB_P,PTAB_Q,PTAB_R,PTAB_S,PTAB_T,PTAB_U,PTAB_V,PTAB_W,PTAB_X,PTAB_Y,PTAB_Z

; ----------------------------------------------------------------------------

        ; This is the startup code.
        ; RUNAD will point here after opening the file, so exection starts here.

        ; Store TRAILER address into MEMLO, and into $864 / $869. The latter is a DOS patch, perhaps?

_start: lda     #<TRAILER
        sta     $2E7
        sta     $864
        lda     #>TRAILER
        sta     $2E8
        sta     $869
        lda     #0                               ; Reset WARMST to zero.
        sta     $08
        rts

; ----------------------------------------------------------------------------

        ; List of the 468 pronunciation rules.

        .macro pronunciation_entry Arg
        ; Each entry is a string with the last character's most siginificant bit set to one.
        .repeat .strlen(Arg) - 1, k
        .byte .strat(Arg, k)
        .endrep
        .byte .strat(Arg, .strlen(Arg) - 1) ^ $80
        .endmacro

        .macro pronunciation_index Arg
        ; Each set of letter-specific prononciation rules is preceded by an entry containing "]" followed by the letter.
        pronunciation_entry .concat("]", Arg)
        .endmacro

        .macro pronunciation_rule Arg1, Arg2
        ; A rule is a pattern, followd by an "=" sign, followed by the replacement.
        pronunciation_entry .concat(Arg1, "=", Arg2)
        .endmacro

PTAB_MISC:

        pronunciation_rule     "(A)"        , ""
        pronunciation_rule     "(!)"        , "."
        .byte                  "(",'"',") =-AH5NKWOWT",'-'+$80   ; ca65 strings cannot contain a double quote (0x22) character, so write out this pronunciation rule as bytes.
        .byte                  "(",'"',")=KWOW4T",'-'+$80        ; ca65 strings cannot contain a double quote (0x22) character, so write out this pronunciation rule as bytes.
        pronunciation_rule     "(#)"        , " NAH4MBER"
        pronunciation_rule     "($)"        , " DAA4LER"
        pronunciation_rule     "(%)"        , " PERSEH4NT"
        pronunciation_rule     "(&)"        , " AEND"
        pronunciation_rule     "(')"        , ""
        pronunciation_rule     "(*)"        , " AE4STERIHSK"
        pronunciation_rule     "(+)"        , " PLAH4S"
        pronunciation_rule     "(,)"        , ","
        pronunciation_rule     " (-) "      , "-"
        pronunciation_rule     "(-)"        , ""
        pronunciation_rule     "(.)"        , " POYNT"
        pronunciation_rule     "(/)"        , " SLAE4SH"
        pronunciation_rule     "(0)"        , " ZIY4ROW"
        pronunciation_rule     " (1ST)"     , "FER4ST"
        pronunciation_rule     " (10TH)"    , "TEH4NTH"
        pronunciation_rule     "(1)"        , " WAH4N"
        pronunciation_rule     " (2ND)"     , "SEH4KUND"
        pronunciation_rule     "(2)"        , " TUW4"
        pronunciation_rule     " (3RD)"     , "THER4D"
        pronunciation_rule     "(3)"        , " THRIY4"
        pronunciation_rule     "(4)"        , " FOH4R"
        pronunciation_rule     " (5TH)"     , "FIH4FTH"
        pronunciation_rule     "(5)"        , " FAY4V"
        pronunciation_rule     "(6)"        , " SIH4KS"
        pronunciation_rule     "(7)"        , " SEH4VUN"
        pronunciation_rule     " (8TH)"     , "EY4TH"
        pronunciation_rule     "(8)"        , " EY4T"
        pronunciation_rule     "(9)"        , " NAY4N"
        pronunciation_rule     "(:)"        , "."
        pronunciation_rule     "(;)"        , "."
        pronunciation_rule     "(<)"        , " LEH4S DHAEN"
        pronunciation_rule     "(=)"        , " IY4KWULZ"
        pronunciation_rule     "(>)"        , " GREY4TER DHAEN"
        pronunciation_rule     "(?)"        , "."
        pronunciation_rule     "(@)"        , " AE6T"
        pronunciation_rule     "(^)"        , " KAE4RIXT"

PTAB_A: pronunciation_index    "A"
        pronunciation_rule     " (A.)"      , "EH4Y. "
        pronunciation_rule     "(A) "       , "AH"
        pronunciation_rule     " (ARE) "    , "AAR"
        pronunciation_rule     " (AR)O"     , "AXR"
        pronunciation_rule     "(AR)#"      , "EH4R"
        pronunciation_rule     " ^(AS)#"    , "EY4S"
        pronunciation_rule     "(A)WA"      , "AX"
        pronunciation_rule     "(AW)"       , "AO5"
        pronunciation_rule     " :(ANY)"    , "EH4NIY"
        pronunciation_rule     "(A)^+#"     , "EY5"
        pronunciation_rule     "#:(ALLY)"   , "ULIY"
        pronunciation_rule     " (AL)#"     , "UL"
        pronunciation_rule     "(AGAIN)"    , "AXGEH4N"
        pronunciation_rule     "#:(AG)E"    , "IHJ"
        pronunciation_rule     "(A)^%"      , "EY"
        pronunciation_rule     "(A)^+:#"    , "AE"
        pronunciation_rule     " :(A)^+ "   , "EY4"
        pronunciation_rule     " (ARR)"     , "AXR"
        pronunciation_rule     "(ARR)"      , "AE4R"
        pronunciation_rule     " ^(AR) "    , "AA5R"
        pronunciation_rule     "(AR)"       , "AA5R"
        pronunciation_rule     "(AIR)"      , "EH4R"
        pronunciation_rule     "(AI)"       , "EY4"
        pronunciation_rule     "(AY)"       , "EY5"
        pronunciation_rule     "(AU)"       , "AO4"
        pronunciation_rule     "#:(AL) "    , "UL"
        pronunciation_rule     "#:(ALS) "   , "ULZ"
        pronunciation_rule     "(ALK)"      , "AO4K"
        pronunciation_rule     "(AL)^"      , "AOL"
        pronunciation_rule     " :(ABLE)"   , "EY4BUL"
        pronunciation_rule     "(ABLE)"     , "AXBUL"
        pronunciation_rule     "(A)VO"      , "EY4"
        pronunciation_rule     "(ANG)+"     , "EY4NJ"
        pronunciation_rule     "(ATARI)"    , "AHTAA4RIY"
        pronunciation_rule     "(A)TOM"     , "AE"
        pronunciation_rule     "(A)TTI"     , "AE"
        pronunciation_rule     " (AT) "     , "AET"
        pronunciation_rule     " (A)T"      , "AH"
        pronunciation_rule     "(A)"        , "AE"

PTAB_B: pronunciation_index    "B"
        pronunciation_rule     " (B) "      , "BIY4"
        pronunciation_rule     " (BE)^#"    , "BIH"
        pronunciation_rule     "(BEING)"    , "BIY4IHNX"
        pronunciation_rule     " (BOTH) "   , "BOW4TH"
        pronunciation_rule     " (BUS)#"    , "BIH4Z"
        pronunciation_rule     "(BREAK)"    , "BREY5K"
        pronunciation_rule     "(BUIL)"     , "BIH4L"
        pronunciation_rule     "(B)"        , "B"

PTAB_C: pronunciation_index    "C"
        pronunciation_rule     " (C) "      , "SIY4"
        pronunciation_rule     " (CH)^"     , "K"
        pronunciation_rule     "^E(CH)"     , "K"
        pronunciation_rule     "(CHA)R#"    , "KEH5"
        pronunciation_rule     "(CH)"       , "CH"
        pronunciation_rule     " S(CI)#"    , "SAY4"
        pronunciation_rule     "(CI)A"      , "SH"
        pronunciation_rule     "(CI)O"      , "SH"
        pronunciation_rule     "(CI)EN"     , "SH"
        pronunciation_rule     "(CITY)"     , "SIHTIY"
        pronunciation_rule     "(C)+"       , "S"
        pronunciation_rule     "(CK)"       , "K"
        pronunciation_rule     "(COM)"      , "KAHM"
        pronunciation_rule     "(CUIT)"     , "KIHT"
        pronunciation_rule     "(CREA)"     , "KRIYEY"
        pronunciation_rule     "(C)"        , "K"

PTAB_D: pronunciation_index    "D"
        pronunciation_rule     " (D) "      , "DIY4"
        pronunciation_rule     " (DR.) "    , "DAA4KTER"
        pronunciation_rule     "#:(DED) "   , "DIHD"
        pronunciation_rule     ".E(D) "     , "D"
        pronunciation_rule     "#:^E(D) "   , "T"
        pronunciation_rule     " (DE)^#"    , "DIH"
        pronunciation_rule     " (DO) "     , "DUW"
        pronunciation_rule     " (DOES)"    , "DAHZ"
        pronunciation_rule     "(DONE) "    , "DAH5N"
        pronunciation_rule     "(DOING)"    , "DUW4IHNX"
        pronunciation_rule     " (DOW)"     , "DAW"
        pronunciation_rule     "#(DU)A"     , "JUW"
        pronunciation_rule     "#(DU)^#"    , "JAX"
        pronunciation_rule     "(D)"        , "D"

PTAB_E: pronunciation_index    "E"
        pronunciation_rule     " (E) "      , "IYIY4"
        pronunciation_rule     "#:(E) "     , ""
        pronunciation_rule     "':^(E) "    , ""
        pronunciation_rule     " :(E) "     , "IY"
        pronunciation_rule     "#(ED) "     , "D"
        pronunciation_rule     "#:(E)D "    , ""
        pronunciation_rule     "(EV)ER"     , "EH4V"
        pronunciation_rule     "(E)^%"      , "IY4"
        pronunciation_rule     "(ERI)#"     , "IY4RIY"
        pronunciation_rule     "(ERI)"      , "EH4RIH"
        pronunciation_rule     "#:(ER)#"    , "ER"
        pronunciation_rule     "(ERROR)"    , "EH4ROHR"
        pronunciation_rule     "(ERASE)"    , "IHREY5S"
        pronunciation_rule     "(ER)#"      , "EHR"
        pronunciation_rule     "(ER)"       , "ER"
        pronunciation_rule     " (EVEN)"    , "IYVEHN"
        pronunciation_rule     "#:(E)W"     , ""
        pronunciation_rule     "@(EW)"      , "UW"
        pronunciation_rule     "(EW)"       , "YUW"
        pronunciation_rule     "(E)O"       , "IY"
        pronunciation_rule     "#:&(ES) "   , "IHZ"
        pronunciation_rule     "#:(E)S "    , ""
        pronunciation_rule     "#:(ELY) "   , "LIY"
        pronunciation_rule     "#:(EMENT)"  , "MEHNT"
        pronunciation_rule     "(EFUL)"     , "FUHL"
        pronunciation_rule     "(EE)"       , "IY4"
        pronunciation_rule     "(EARN)"     , "ER5N"
        pronunciation_rule     " (EAR)^"    , "ER5"
        pronunciation_rule     "(EAD)"      , "EHD"
        pronunciation_rule     "#:(EA) "    , "IYAX"
        pronunciation_rule     "(EA)SU"     , "EH5"
        pronunciation_rule     "(EA)"       , "IY5"
        pronunciation_rule     "(EIGH)"     , "EY4"
        pronunciation_rule     "(EI)"       , "IY4"
        pronunciation_rule     " (EYE)"     , "AY4"
        pronunciation_rule     "(EY)"       , "IY"
        pronunciation_rule     "(EU)"       , "YUW5"
        pronunciation_rule     "(EQUAL)"    , "IY4KWUL"
        pronunciation_rule     "(E)"        , "EH"

PTAB_F: pronunciation_index    "F"
        pronunciation_rule     " (F) "      , "EH4F"
        pronunciation_rule     "(FUL)"      , "FUHL"
        pronunciation_rule     "(FRIEND)"   , "FREH5ND"
        pronunciation_rule     "(FATHER)"   , "FAA4DHER"
        pronunciation_rule     "(F)F"       , ""
        pronunciation_rule     "(F)"        , "F"

PTAB_G: pronunciation_index    "G"
        pronunciation_rule     " (G) "      , "JIY4"
        pronunciation_rule     "(GIV)"      , "GIH5V"
        pronunciation_rule     " (G)I^"     , "G"
        pronunciation_rule     "(GE)T"      , "GEH5"
        pronunciation_rule     "SU(GGES)"   , "GJEH4S"
        pronunciation_rule     "(GG)"       , "G"
        pronunciation_rule     " B#(G)"     , "G"
        pronunciation_rule     "(G)+"       , "J"
        pronunciation_rule     "(GREAT)"    , "GREY4T"
        pronunciation_rule     "(GON)E"     , "GAO5N"
        pronunciation_rule     "#(GH)"      , ""
        pronunciation_rule     " (GN)"      , "N"
        pronunciation_rule     "(G)"        , "G"

PTAB_H: pronunciation_index    "H"
        pronunciation_rule    " (H) "       , "EY4CH"
        pronunciation_rule    " (HAV)"      , "/HAE6V"
        pronunciation_rule    " (HERE)"     , "/HIYR"
        pronunciation_rule    " (HOUR)"     , "AW5ER"
        pronunciation_rule    "(HOW)"       , "/HAW"
        pronunciation_rule    "(H)#"        , "/H"
        pronunciation_rule    "(H)"         , ""

PTAB_I: pronunciation_index    "I"
        pronunciation_rule    " (IN)"       , "IHN"
        pronunciation_rule    " (I) "       , "AY4"
        pronunciation_rule    "(I) "        , "AY"
        pronunciation_rule    "(IN)D"       , "AY5N"
        pronunciation_rule    "SEM(I)"      , "IY"
        pronunciation_rule    " ANT(I)"     , "AY"
        pronunciation_rule    "(IER)"       , "IYER"
        pronunciation_rule    "#:R(IED) "   , "IYD"
        pronunciation_rule    "(IED) "      , "AY5D"
        pronunciation_rule    "(IEN)"       , "IYEHN"
        pronunciation_rule    "(IE)T"       , "AY4EH"
        pronunciation_rule    "(I')"        , "AY5"
        pronunciation_rule    " :(I)^%"     , "AY5"
        pronunciation_rule    " :(IE) "     , "AY4"
        pronunciation_rule    "(I)%"        , "IY"
        pronunciation_rule    "(IE)"        , "IY4"
        pronunciation_rule    " (IDEA)"     , "AYDIY5AH"
        pronunciation_rule    "(I)^+:#"     , "IH"
        pronunciation_rule    "(IR)#"       , "AYR"
        pronunciation_rule    "(IZ)%"       , "AYZ"
        pronunciation_rule    "(IS)%"       , "AYZ"
        pronunciation_rule    "I^(I)^#"     , "IH"
        pronunciation_rule    "+^(I)^+"     , "AY"
        pronunciation_rule    "#:^(I)^+"    , "IH"
        pronunciation_rule    "(I)^+"       , "AY"
        pronunciation_rule    "(IR)"        , "ER"
        pronunciation_rule    "(IGH)"       , "AY4"
        pronunciation_rule    "(ILD)"       , "AY5LD"
        pronunciation_rule    " (IGN)"      , "IHGN"
        pronunciation_rule    "(IGN) "      , "AY4N"
        pronunciation_rule    "(IGN)^"      , "AY4N"
        pronunciation_rule    "(IGN)%"      , "AY4N"
        pronunciation_rule    "(ICRO)"      , "AY4KROH"
        pronunciation_rule    "(IQUE)"      , "IY4K"
        pronunciation_rule    "(I)"         , "IH"

PTAB_J: pronunciation_index    "J"
        pronunciation_rule    " (J) "       , "JEY4"
        pronunciation_rule    "(J)"         , "J"

PTAB_K: pronunciation_index    "K"
        pronunciation_rule    " (K) "       , "KEY4"
        pronunciation_rule    " (K)N"       , ""
        pronunciation_rule    "(K)"         , "K"

PTAB_L: pronunciation_index    "L"
        pronunciation_rule    " (L) "       , "EH4L"
        pronunciation_rule    "(LO)C#"      , "LOW"
        pronunciation_rule    "L(L)"        , ""
        pronunciation_rule    "#:^(L)%"     , "UL"
        pronunciation_rule    "(LEAD)"      , "LIYD"
        pronunciation_rule    " (LAUGH)"    , "LAE4F"
        pronunciation_rule    "(L)"         , "L"

PTAB_M: pronunciation_index    "M"
        pronunciation_rule    " (M) "       , "EH4M"
        pronunciation_rule    " (MR.) "     , "MIH4STER"
        pronunciation_rule    " (MS.)"      , "MIH5Z"
        pronunciation_rule    " (MRS.) "    , "MIH4SIXZ"
        pronunciation_rule    "(MOV)"       , "MUW4V"
        pronunciation_rule    "(MACHIN)"    , "MAHSHIY5N"
        pronunciation_rule    "M(M)"        , ""
        pronunciation_rule    "(M)"         , "M"

PTAB_N: pronunciation_index    "N"
        pronunciation_rule     " (N) "      , "EH4N"
        pronunciation_rule     "E(NG)+"     , "NJ"
        pronunciation_rule     "(NG)R"      , "NXG"
        pronunciation_rule     "(NG)#"      , "NXG"
        pronunciation_rule     "(NGL)%"     , "NXGUL"
        pronunciation_rule     "(NG)"       , "NX"
        pronunciation_rule     "(NK)"       , "NXK"
        pronunciation_rule     " (NOW) "    , "NAW4"
        pronunciation_rule     "N(N)"       , ""
        pronunciation_rule     "(NON)E"     , "NAH4N"
        pronunciation_rule     "(N)"        , "N"

PTAB_O: pronunciation_index    "O"
        pronunciation_rule     " (O) "      , "OH4W"
        pronunciation_rule     "(OF) "      , "AHV"
        pronunciation_rule     " (OH) "     , "OW5"
        pronunciation_rule     "(OROUGH)"   , "ER4OW"
        pronunciation_rule     "#:(OR) "    , "ER"
        pronunciation_rule     "#:(ORS) "   , "ERZ"
        pronunciation_rule     "(OR)"       , "AOR"
        pronunciation_rule     " (ONE)"     , "WAHN"
        pronunciation_rule     "#(ONE) "    , "WAHN"
        pronunciation_rule     "(OW)"       , "OW"
        pronunciation_rule     " (OVER)"    , "OW5VER"
        pronunciation_rule     "PR(O)V"     , "UW4"
        pronunciation_rule     "(OV)"       , "AH4V"
        pronunciation_rule     "(O)^%"      , "OW5"
        pronunciation_rule     "(O)^EN"     , "OW"
        pronunciation_rule     "(O)^I#"     , "OW5"
        pronunciation_rule     "(OL)D"      , "OW4L"
        pronunciation_rule     "(OUGHT)"    , "AO5T"
        pronunciation_rule     "(OUGH)"     , "AH5F"
        pronunciation_rule     " (OU)"      , "AW"
        pronunciation_rule     "H(OU)S#"    , "AW4"
        pronunciation_rule     "(OUS)"      , "AXS"
        pronunciation_rule     "(OUR)"      , "OHR"
        pronunciation_rule     "(OULD)"     , "UH5D"
        pronunciation_rule     "(OU)^L"     , "AH5"
        pronunciation_rule     "(OUP)"      , "UW5P"
        pronunciation_rule     "(OU)"       , "AW"
        pronunciation_rule     "(OY)"       , "OY"
        pronunciation_rule     "(OING)"     , "OW4IHNX"
        pronunciation_rule     "(OI)"       , "OY5"
        pronunciation_rule     "(OOR)"      , "OH5R"
        pronunciation_rule     "(OOK)"      , "UH5K"
        pronunciation_rule     "F(OOD)"     , "UW5D"
        pronunciation_rule     "L(OOD)"     , "AH5D"
        pronunciation_rule     "M(OOD)"     , "UW5D"
        pronunciation_rule     "(OOD)"      , "UH5D"
        pronunciation_rule     "F(OOT)"     , "UH5T"
        pronunciation_rule     "(OO)"       , "UW5"
        pronunciation_rule     "(O')"       , "OH"
        pronunciation_rule     "(O)E"       , "OW"
        pronunciation_rule     "(O) "       , "OW"
        pronunciation_rule     "(OA)"       , "OW4"
        pronunciation_rule     " (ONLY)"    , "OW4NLIY"
        pronunciation_rule     " (ONCE)"    , "WAH4NS"
        pronunciation_rule     "(ON'T)"     , "OW4NT"
        pronunciation_rule     "C(O)N"      , "AA"
        pronunciation_rule     "(O)NG"      , "AO"
        pronunciation_rule     " :^(O)N"    , "AH"
        pronunciation_rule     "I(ON)"      , "UN"
        pronunciation_rule     "#:(ON) "    , "UN"
        pronunciation_rule     "#^(ON)"     , "UN"
        pronunciation_rule     "(O)ST "     , "OW"
        pronunciation_rule     "(OF)^"      , "AO4F"
        pronunciation_rule     "(OTHER)"    , "AH5DHER"
        pronunciation_rule     "R(O)B"      , "RAA"
        pronunciation_rule     "^R(O):#"    , "OW5"
        pronunciation_rule     "(OSS) "     , "AO5S"
        pronunciation_rule     "#:^(OM)"    , "AHM"
        pronunciation_rule     "(O)"        , "AA"

PTAB_P: pronunciation_index    "P"
        pronunciation_rule     " (P) "      , "PIY4"
        pronunciation_rule     "(PH)"       , "F"
        pronunciation_rule     "(PEOPL)"    , "PIY5PUL"
        pronunciation_rule     "(POW)"      , "PAW4"
        pronunciation_rule     "(PUT) "     , "PUHT"
        pronunciation_rule     "(P)P"       , ""
        pronunciation_rule     " (P)S"      , ""
        pronunciation_rule     " (P)N"      , ""
        pronunciation_rule     " (PROF.)"   , "PROHFEH4SER"
        pronunciation_rule     "(P)"        , "P"

PTAB_Q: pronunciation_index    "Q"
        pronunciation_rule     " (Q) "      , "KYUW4"
        pronunciation_rule     "(QUAR)"     , "KWOH5R"
        pronunciation_rule     "(QU)"       , "KW"
        pronunciation_rule     "(Q)"        , "K"

PTAB_R: pronunciation_index    "R"
        pronunciation_rule     " (R) "      , "AA5R"
        pronunciation_rule     " (RE)^#"    , "RIY"
        pronunciation_rule     "(R)R"       , ""
        pronunciation_rule     "(R)"        , "R"

PTAB_S: pronunciation_index    "S"
        pronunciation_rule     " (S) "      , "EH4S"
        pronunciation_rule     "(SH)"       , "SH"
        pronunciation_rule     "#(SION)"    , "ZHUN"
        pronunciation_rule     "(SOME)"     , "SAHM"
        pronunciation_rule     "#(SUR)#"    , "ZHER"
        pronunciation_rule     "(SUR)#"     , "SHER"
        pronunciation_rule     "#(SU)#"     , "ZHUW"
        pronunciation_rule     "#(SSU)#"    , "SHUW"
        pronunciation_rule     "#(SED) "    , "ZD"
        pronunciation_rule     "#(S)#"      , "Z"
        pronunciation_rule     "(SAID)"     , "SEHD"
        pronunciation_rule     "^(SION)"    , "SHUN"
        pronunciation_rule     "(S)S"       , ""
        pronunciation_rule     ".(S) "      , "Z"
        pronunciation_rule     "#:.E(S) "   , "Z"
        pronunciation_rule     "#:^#(S) "   , "S"
        pronunciation_rule     "U(S) "      , "S"
        pronunciation_rule     " :#(S) "    , "Z"
        pronunciation_rule     "##(S) "     , "Z"
        pronunciation_rule     " (SCH)"     , "SK"
        pronunciation_rule     "(S)C+"      , ""
        pronunciation_rule     "#(SM)"      , "ZUM"
        pronunciation_rule     "#(SN)'"     , "ZUN"
        pronunciation_rule     "(STLE)"     , "SUL"
        pronunciation_rule     "(S)"        , "S"

PTAB_T: pronunciation_index    "T"
        pronunciation_rule     " (T) "      , "TIY4"
        pronunciation_rule     " (THE) #"   , "DHIY"
        pronunciation_rule     " (THE) "    , "DHAX"
        pronunciation_rule     "(TO) "      , "TUX"
        pronunciation_rule     " (THAT)"    , "DHAET"
        pronunciation_rule     " (THIS) "   , "DHIHS"
        pronunciation_rule     " (THEY)"    , "DHEY"
        pronunciation_rule     " (THERE)"   , "DHEHR"
        pronunciation_rule     "(THER)"     , "DHER"
        pronunciation_rule     "(THEIR)"    , "DHEHR"
        pronunciation_rule     " (THAN) "   , "DHAEN"
        pronunciation_rule     " (THEM) "   , "DHEHM"
        pronunciation_rule     "(THESE) "   , "DHIYZ"
        pronunciation_rule     " (THEN)"    , "DHEHN"
        pronunciation_rule     "(THROUGH)"  , "THRUW4"
        pronunciation_rule     "(THOSE)"    , "DHOHZ"
        pronunciation_rule     "(THOUGH) "  , "DHOW"
        pronunciation_rule     "(TODAY)"    , "TUXDEY"
        pronunciation_rule     "(TOMO)RROW" , "TUMAA5"
        pronunciation_rule     "(TO)TAL"    , "TOW5"
        pronunciation_rule     " (THUS)"    , "DHAH4S"
        pronunciation_rule     "(TH)"       , "TH"
        pronunciation_rule     "#:(TED) "   , "TIXD"
        pronunciation_rule     "S(TI)#N"    , "CH"
        pronunciation_rule     "(TI)O"      , "SH"
        pronunciation_rule     "(TI)A"      , "SH"
        pronunciation_rule     "(TIEN)"     , "SHUN"
        pronunciation_rule     "(TUR)#"     , "CHER"
        pronunciation_rule     "(TU)A"      , "CHUW"
        pronunciation_rule     " (TWO)"     , "TUW"
        pronunciation_rule     "&(T)EN "    , ""
        pronunciation_rule     "(T)"        , "T"

PTAB_U: pronunciation_index    "U"
        pronunciation_rule     " (U) "      , "YUW4"
        pronunciation_rule     " (UN)I"     , "YUWN"
        pronunciation_rule     " (UN)"      , "AHN"
        pronunciation_rule     " (UPON)"    , "AXPAON"
        pronunciation_rule     "@(UR)#"     , "UH4R"
        pronunciation_rule     "(UR)#"      , "YUH4R"
        pronunciation_rule     "(UR)"       , "ER"
        pronunciation_rule     "(U)^ "      , "AH"
        pronunciation_rule     "(U)^^"      , "AH5"
        pronunciation_rule     "(UY)"       , "AY5"
        pronunciation_rule     " G(U)#"     , ""
        pronunciation_rule     "G(U)%"      , ""
        pronunciation_rule     "G(U)#"      , "W"
        pronunciation_rule     "#N(U)"      , "YUW"
        pronunciation_rule     "@(U)"       , "UW"
        pronunciation_rule     "(U)"        , "YUW"

PTAB_V: pronunciation_index    "V"
        pronunciation_rule     " (V) "      , "VIY4"
        pronunciation_rule     "(VIEW)"     , "VYUW5"
        pronunciation_rule     "(V)"        , "V"

PTAB_W: pronunciation_index    "W"
        pronunciation_rule     " (W) "      , "DAH4BULYUW"
        pronunciation_rule     " (WERE)"    , "WER"
        pronunciation_rule     "(WA)SH"     , "WAA"
        pronunciation_rule     "(WA)ST"     , "WEY"
        pronunciation_rule     "(WA)S"      , "WAH"
        pronunciation_rule     "(WA)T"      , "WAA"
        pronunciation_rule     "(WHERE)"    , "WHEHR"
        pronunciation_rule     "(WHAT)"     , "WHAHT"
        pronunciation_rule     "(WHOL)"     , "/HOWL"
        pronunciation_rule     "(WHO)"      , "/HUW"
        pronunciation_rule      "(WH)"      , "WH"
        pronunciation_rule     "(WAR)#"     , "WEHR"
        pronunciation_rule     "(WAR)"      , "WAOR"
        pronunciation_rule     "(WOR)^"     , "WER"
        pronunciation_rule     "(WR)"       , "R"
        pronunciation_rule     "(WOM)A"     , "WUHM"
        pronunciation_rule     "(WOM)E"     , "WIHM"
        pronunciation_rule     "(WEA)R"     , "WEH"
        pronunciation_rule     "(WANT)"     , "WAA5NT"
        pronunciation_rule     "ANS(WER)"   , "ER"
        pronunciation_rule     "(W)"        , "W"

PTAB_X: pronunciation_index    "X"
        pronunciation_rule     " (X) "      , "EH4KS"
        pronunciation_rule     " (X)"       , "Z"
        pronunciation_rule     "(X)"        , "KS"

PTAB_Y: pronunciation_index    "Y"
        pronunciation_rule     " (Y) "      , "WAY4"
        pronunciation_rule     "(YOUNG)"    , "YAHNX"
        pronunciation_rule     " (YOUR)"    , "YOHR"
        pronunciation_rule     " (YOU)"     , "YUW"
        pronunciation_rule     " (YES)"     , "YEHS"
        pronunciation_rule     " (Y)"       , "Y"
        pronunciation_rule     "F(Y)"       , "AY"
        pronunciation_rule     "PS(YCH)"    , "AYK"
        pronunciation_rule     "#:^(Y) "    , "IY"
        pronunciation_rule     "#:^(Y)I"    , "IY"
        pronunciation_rule     " :(Y) "     , "AY"
        pronunciation_rule     " :(Y)#"     , "AY"
        pronunciation_rule     " :(Y)^+:#"  , "IH"
        pronunciation_rule     " :(Y)^#"    , "AY"
        pronunciation_rule     "(Y)"        , "IH"

PTAB_Z: pronunciation_index    "Z"
        pronunciation_rule     " (Z) "      , "ZIY4"
        pronunciation_rule     "(Z)"        , "Z"


TRAILER: .byte   $EA,$A0                         ; Trailing bytes -- probably not important. MEMLO is set to TRAILER on start.

        .segment "RECITER_BLOCK2_HEADER"

	; This is the Atari executable header for the second block in the executable file, which is a small
	; block that sets the ""RUNAD" pointer used by DOS as the run address for executable files.

        .word   __RECITER_BLOCK2_LOAD__
        .word   __RECITER_BLOCK2_LOAD__ + __RECITER_BLOCK2_SIZE__ - 1

        .segment "RECITER_BLOCK2"

        ; The content of the second block is just the run address of the code (0x4b23).

        .word _start
