
; Source code for the SAM reciter.
;
; The "reciter" program performs English-to-SAM phoneme translation.
;
; It is designed to be called through entry points in the SAM program.

; ----------------------------------------------------------------------------

        .setcpu "6502"

        ; We enable ca65's "string_escape" feature to allow escaped quotes in pronunciation rules.
        .feature string_escapes

; ----------------------------------------------------------------------------

        .import __RECITER_BLOCK1_LOAD__, __RECITER_BLOCK1_SIZE__
        .import __RECITER_BLOCK2_LOAD__, __RECITER_BLOCK2_SIZE__

; ----------------------------------------------------------------------------

        .importzp WARMST
        .import MEMLO
        .import BASIC

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

; ----------------------------------------------------------------------------

        .segment "RECITER_BLOCK1"

; ----------------------------------------------------------------------------

        ZP_SAM_BUFFER_INDEX        := $F5  ; Destination index in the SAM_BUFFER.
        ZP_CURRENT_CHARACTER_PROPS := $F6  ; Current character to be translated.
        ZP_RECITER_BUFFER_INDEX    := $FA  ; Source index in the RECITER_BUFFER.
        ZP_CURRENT_CHARACTER       := $FD  ; Current character to be translated.

; ----------------------------------------------------------------------------

RECITER_BUFFER: .res 256, 0

; ----------------------------------------------------------------------------

        .byte "COPYRIGHT 1982 DON'T ASK"

; ----------------------------------------------------------------------------

CHARACTER_PROPERTY:

        ; Properties of the 96 characters we support.
        ;
        ; Value 0x00: ignore the character
        ; bit 0 (%00000001): 0-9                                                  (digits)
        ; bit 1 (%00000010): ! " # $ % & ' * + , - . 0-9 : ; < = > ? @ ^          (special characters and digits)
        ; bit 2 (%00000100):       D           J L     N       R S T           Z
        ; bit 3 (%00001000):   B   D     G     J L M   N       R       V W     Z
        ; bit 4 (%00010000):     C       G     J                 S         X   Z
        ; bit 5 (%00100000):   B C D   F G H   J K L M N   P Q R S T   V W X   Z  (consonants)
        ; bit 6 (%01000000): A       E       I           O           U       Y    (vowels)
        ; bit 7 (%10000000): ' A-Z                                                (single quote and all letters)

        .res 32,%00000000                       ; ASCII control characters 0x00..0x1F are all 0x00 (ignore).

        .byte   %00000000                       ; space
        .byte   %00000010                       ; !
        .byte   %00000010                       ; "
        .byte   %00000010                       ; #
        .byte   %00000010                       ; $
        .byte   %00000010                       ; %
        .byte   %00000010                       ; &
        .byte   %10000010                       ; '     -- Note that the single quote has bit 7 set, like the letters A-Z. Mistake?
        .byte   %00000000                       ; (     -- ignore.
        .byte   %00000000                       ; )     -- ignore.
        .byte   %00000010                       ; *
        .byte   %00000010                       ; +
        .byte   %00000010                       ; ,
        .byte   %00000010                       ; -
        .byte   %00000010                       ; .
        .byte   %00000010                       ; /
        .byte   %00000011                       ; 0
        .byte   %00000011                       ; 1
        .byte   %00000011                       ; 2
        .byte   %00000011                       ; 3
        .byte   %00000011                       ; 4
        .byte   %00000011                       ; 5
        .byte   %00000011                       ; 6
        .byte   %00000011                       ; 7
        .byte   %00000011                       ; 8
        .byte   %00000011                       ; 9
        .byte   %00000010                       ; :
        .byte   %00000010                       ; ;
        .byte   %00000010                       ; <
        .byte   %00000010                       ; =
        .byte   %00000010                       ; >
        .byte   %00000010                       ; ?
        .byte   %00000010                       ; @
        .byte   %11000000                       ; A
        .byte   %10101000                       ; B
        .byte   %10110000                       ; C
        .byte   %10101100                       ; D
        .byte   %11000000                       ; E
        .byte   %10100000                       ; F
        .byte   %10111000                       ; G
        .byte   %10100000                       ; H
        .byte   %11000000                       ; I
        .byte   %10111100                       ; J
        .byte   %10100000                       ; K
        .byte   %10101100                       ; L
        .byte   %10101000                       ; M
        .byte   %10101100                       ; N
        .byte   %11000000                       ; O
        .byte   %10100000                       ; P
        .byte   %10100000                       ; Q
        .byte   %10101100                       ; R
        .byte   %10110100                       ; S
        .byte   %10100100                       ; T
        .byte   %11000000                       ; U
        .byte   %10101000                       ; V
        .byte   %10101000                       ; W
        .byte   %10110000                       ; X
        .byte   %11000000                       ; Y
        .byte   %10111100                       ; Z
        .byte   %00000000                       ; [    -- ignore.
        .byte   %00000000                       ; \    -- ignore.
        .byte   %00000000                       ; ]    -- ignore.
        .byte   %00000010                       ; ^
        .byte   %00000000                       ; _    -- ignore.

; ----------------------------------------------------------------------------

RECITER_VIA_SAM_FROM_BASIC:

        ; Reciter when entered from BASIC, through a call to the USR(8200) function.
        ; When entering here, the number of arguments is already popped from the 6502 stack.

        jsr     SAM_COPY_BASIC_SAM_STRING       ; Find and copy SAM$.

; ----------------------------------------------------------------------------

RECITER_VIA_SAM_FROM_MACHINE_CODE:

        ; Reciter when entered from machine code.
        ; When entering, the English-language string to be translated should be in the SAM_BUFFER.

        jsr     SAM_SAVE_ZP_ADDRESSES           ; Save ZP registers.

        ; Copy content of SAM buffer to RECITER buffer, with some character remapping.
        ; The translation performed first zeroes then most significant bit of each character,
        ; to ensure it is an ASCII character.
        ;
        ; Then, it maps the 32 highest ASCII characters (0x60..0x7f, which include the
        ; lowercase letters) to 0x40..0x5F.
        ;
        ; To summarize the effects:
        ;
        ; The end-of-line character 0x9b map to 0x1b (the escape character).
        ;
        ; `   (backtick)            maps to '@'.
        ; a-z (lowercase letters)   map  to A-Z.
        ; {   (curly bracket open)  maps to '[' (angle bracket open).
        ; |   (pipe)                maps to '\' (backslash).
        ; }   (curly bracket close) maps to ']' (angle bracket close).
        ; ~   (tilde)               maps to '^' (caret).
        ; DEL (0x7f)                maps to '_' (underscore).
        ;
        ; What remains are 96 characters that need to be handled:
        ;
        ; * 32 ASCII control characters 0x00 .. 0x1f, including escape (0x1f) that is used as an end-of-string marker.
        ; * 16 characters ' ' (space), '!', '"', '#', '$', '%', '&', single-quote, '(', ')', '*', '+', ',', '-', '.', '/'
        ; * 10 characters '0' .. '9'.
        ; *  7 characters ':', ';', '<', '=', '>', '?', '@'
        ; * 26 characters 'A' .. 'Z'
        ; *  5 characters '[', '\', ']', '^', '_'

        lda     #' '                            ; Put a space character at the start of the RECITER buffer.
        sta     RECITER_BUFFER                  ;
        ldx     #1                              ; Prepare the character copy loop.
        ldy     #0                              ;

@loop:  lda     SAM_BUFFER,y                    ; Start of character copy loop; load character.
        and     #$7F                            ; Set bit 7 of the character to zero. Note that this turns end-of-line, 0x9b, into 0x1b.
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

        ldx     #$FF                            ; Store $1B at the end of the RECITER buffer.
        lda     #$1B                            ; This ensures the RECITER buffer's string will end in $1B.
        sta     RECITER_BUFFER,x                ;

        jsr     SUB_ENGLISH_TO_PHONEMES         ; Translate buffer to phonemes, then say those.

; ----------------------------------------------------------------------------

SAY_PHONEMES:

        jsr     SAM_SAY_PHONEMES                ; Call subroutine in SAM.
        rts                                     ; Done.

; ----------------------------------------------------------------------------

SUB_ENGLISH_TO_PHONEMES:

        ; Translate English text in the RECITER_BUFFER to phonemes in the SAM_BUFFER.

        lda     #$FF                            ;
        sta     ZP_RECITER_BUFFER_INDEX         ;

TRANSLATE_NEXT_CHUNK:

        lda     #$FF                            ;
        sta     ZP_SAM_BUFFER_INDEX             ;

; ----------------------------------------------------------------------------

TRANSLATE_NEXT_CHARACTER:

        inc     ZP_RECITER_BUFFER_INDEX         ;
        ldx     ZP_RECITER_BUFFER_INDEX         ;
        lda     RECITER_BUFFER,x                ; Load English character to translate in ZP_CURRENT_CHARACTER.
        sta     ZP_CURRENT_CHARACTER            ; Store for later use.

        cmp     #$1B                            ; Is the current character the end-of-string character $1B?
        bne     @not_end_of_string              ;
                                                ; Handle end-of-string.
        inc     ZP_SAM_BUFFER_INDEX             ; Append end-of-string character to the SAM phoneme buffer.
        ldx     ZP_SAM_BUFFER_INDEX             ;
        lda     #$9B                            ;
        sta     SAM_BUFFER,x                    ; then return. We're done.
        rts                                     ; (The final chunk will be passed to SAM by the caller).

@not_end_of_string:

	; The following sequence of 13 instructions implements the rule that a period character that is not
	; followed by a digit is copied into the SAM phoneme buffer verbatim; it is an "end-of-sentence"
	; indicator.
        ;
        ; Periods that precede a digit are assumed to be part of a number, and those will be rendered as "POYNT"
        ; by a miscellaneous pronunciation rule later.

        cmp     #'.'                            ; Compare current character to period ('.').
        bne     @proceed_1                      ;
        inx                                     ; Is the period following the period a digit (0-9)?
        lda     RECITER_BUFFER,x                ;
        tay                                     ;
        lda     CHARACTER_PROPERTY,y            ;
        and     #$01                            ;
        bne     @proceed_1                      ; Yes, skip to @proceed_1.

                                                ; Handle end-of-sentence period.

        inc     ZP_SAM_BUFFER_INDEX             ; Append the period character to the SAM phoneme byffer.
        ldx     ZP_SAM_BUFFER_INDEX             ;
        lda     #'.'                            ;
        sta     SAM_BUFFER,x                    ;
        jmp     TRANSLATE_NEXT_CHARACTER        ; Proceed to the next English character.

@proceed_1:                                     ; The current character is not a period, or it is a period followed by a digit.

        lda     ZP_CURRENT_CHARACTER            ; Check if the character is in the "miscellaneous symbols including digits" class.
        tay                                     ;
        lda     CHARACTER_PROPERTY,y            ;
        sta     ZP_CURRENT_CHARACTER_PROPS      ;
        and     #$02                            ;
        beq     @proceed_2                      ; No: proceed.

        lda     #<PTAB_MISC                     ; Try to match miscellaneous pronunciation rules.
        sta     $FB                             ;
        lda     #>PTAB_MISC                     ;
        sta     $FC                             ;
        jmp     MATCH_RULE                      ;

@proceed_2:

        lda     ZP_CURRENT_CHARACTER_PROPS      ; Check if the character is "space-like" (i.e., it properties flags are all zero).
        bne     TRANSLATE_ALPHABETIC_CHARACTER  ; If not, proceed to match an alphabetic character.

        lda     #' '                            ; Replace the character in the source (english) buffer by a space.
        sta     RECITER_BUFFER,x                ;

        inc     ZP_SAM_BUFFER_INDEX             ; Increment the SAM phoneme buffer index.
        ldx     ZP_SAM_BUFFER_INDEX             ;
                                                ; We're rendering a space; this would be a good time to flush the buffer.
        cpx     #$78                            ; Is the SAM phoneme buffer approximately half full?
        bcs     FLUSH_SAM_BUFFER                ; Yes! Flush (say) the current phoneme buffer.

        sta     SAM_BUFFER,x                    ; Store a space character to the SAM phoneme buffer.
        jmp     TRANSLATE_NEXT_CHARACTER        ; Proceed with next character.

; ----------------------------------------------------------------------------

SAVE_FA: .byte 0                                ; Temporary storage for ZP_RECITER_BUFFER_INDEX.

FLUSH_SAM_BUFFER:

        lda     #$9B                            ; Add an end-of-line to the rendered buffer.
        sta     SAM_BUFFER,x                    ;
        lda     ZP_RECITER_BUFFER_INDEX         ; Save reciter buffer index.
        sta     SAVE_FA                         ;
        sta     $CD                             ; ??? Is this important? (Maybe for SAM?)
        jsr     SAY_PHONEMES                    ; Speak the current phonemes in the SAM_BUFFER.
        lda     SAVE_FA                         ; Restore the reciter buffer index.
        sta     ZP_RECITER_BUFFER_INDEX         ;
        jmp     TRANSLATE_NEXT_CHUNK            ; Render the next chunk.

; ----------------------------------------------------------------------------

TRANSLATE_ALPHABETIC_CHARACTER:

        lda     ZP_CURRENT_CHARACTER_PROPS      ; Verify that $F6 contains a value with its most significant bit set.
        and     #$80                            ;
        bne     @good                           ; Character is alphabetic, or a single quote.
        brk                                     ; Abort. Unexpected character type.

@good:  lda     ZP_CURRENT_CHARACTER            ; Load the character to be processed from ZP_CURRENT_CHARACTER.
        sec                                     ; Set ($FB, $FC) pointer to the table entry corresponding to the letter.
        sbc     #'A'                            ;
        tax                                     ;
        lda     PTAB_INDEX_LO,x                 ;
        sta     $FB                             ;
        lda     PTAB_INDEX_HI,x                 ;
        sta     $FC                             ;

MATCH_RULE:

        ; ($FB, $FC) are pointing to a rule or rule index.

        ldy     #0                              ; Set Y=0 for accessing ($FB, $FC) later on.

        ; Find end-of-rule.

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

        ; ($FB, $FC) is at the opening parenthesis of a rule definition.

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
        sty     ZP_CURRENT_CHARACTER            ;
        ldx     ZP_RECITER_BUFFER_INDEX         ;
        stx     $F9                             ;
        ldy     $FF                             ;
        iny                                     ;
@3:     lda     RECITER_BUFFER,x                ;
        sta     ZP_CURRENT_CHARACTER_PROPS      ;
        lda     ($FB),y                         ;
        cmp     ZP_CURRENT_CHARACTER_PROPS      ;
        beq     @4                              ;
        jmp     MATCH_RULE                      ;

@4:     iny                                     ;
        cpy     $FE                             ;
        bne     @5                              ;
        jmp     @6                              ;

@5:     inx                                     ;
        stx     $F9                             ;
        jmp     @3                              ;

@6:     lda     ZP_RECITER_BUFFER_INDEX         ;
        sta     $F8                             ;
L4835:  ldy     $FF                             ;
        dey                                     ;
        sty     $FF                             ;
        lda     ($FB),y                         ;
        sta     ZP_CURRENT_CHARACTER_PROPS      ;
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
        cmp     ZP_CURRENT_CHARACTER_PROPS      ;
        beq     @1                              ;
        jmp     MATCH_RULE                      ;

@1:     stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

SW1_485F:

        lda     ZP_CURRENT_CHARACTER_PROPS      ; Switch on content of $F6.
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

        jsr     SUB_GET_CHAR_PROPERTY_F8_PREV   ;
        and     #$80                            ;
        beq     L48A7                           ;
        jmp     MATCH_RULE                      ;

; ----------------------------------------------------------------------------

L48A7:  stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

SW1_HASH:

        jsr     SUB_GET_CHAR_PROPERTY_F8_PREV   ;
        and     #$40                            ;
        bne     L48A7                           ; vowel: go to L48A7
        jmp     MATCH_RULE                      ; non-vowel.

; ----------------------------------------------------------------------------

SW1_PERIOD:

        jsr     SUB_GET_CHAR_PROPERTY_F8_PREV   ;
        and     #$08                            ;
        bne     L48C0                           ;
        jmp     MATCH_RULE                      ;

; ----------------------------------------------------------------------------

L48C0:  stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

SW1_AMPERSAND:

        jsr     SUB_GET_CHAR_PROPERTY_F8_PREV   ;
        and     #$10                            ;
        bne     L48C0                           ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     MATCH_RULE                      ;

@1:     dex                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'C'                            ;
        beq     L48C0                           ;
        cmp     #'S'                            ;
        beq     L48C0                           ;
        jmp     MATCH_RULE                      ;

; ----------------------------------------------------------------------------

SW1_AT_SIGN:

        jsr     SUB_GET_CHAR_PROPERTY_F8_PREV   ;
        and     #$04                            ;
        bne     L48C0                           ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     MATCH_RULE                      ;

@1:     cmp     #'T'                            ;
        beq     @2                              ;
        cmp     #'C'                            ;
        beq     @2                              ;
        cmp     #'S'                            ;
        beq     @2                              ;
        jmp     MATCH_RULE                      ;

@2:     stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

SW1_CARET:

        jsr     SUB_GET_CHAR_PROPERTY_F8_PREV   ;
        and     #$20                            ;
        bne     L4914                           ; consonant.
        jmp     MATCH_RULE                      ; non-consonant.

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
        jmp     MATCH_RULE                      ;

; ----------------------------------------------------------------------------

SW1_COLON:

        jsr     SUB_GET_CHAR_PROPERTY_F8_PREV   ;
        and     #$20                            ;
        bne     @1                              ; consonant.
        jmp     L4835                           ; non-consonant.

@1:     stx     $F8                             ;
        jmp     SW1_COLON                       ;

; ----------------------------------------------------------------------------

SUB_GET_CHAR_PROPERTY_F8_PREV:

        ldx     $F8                             ;
        dex                                     ;
        lda     RECITER_BUFFER,x                ;
        tay                                     ;
        lda     CHARACTER_PROPERTY,y            ;
        rts                                     ;

; ----------------------------------------------------------------------------

SUB_GET_CHAR_PROPERTY_F7_NEXT:

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
        bne     @1                              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'Y'                            ;
        bne     L49B7                           ;
        beq     L4972                           ;
@1:     cmp     #'F'                            ;
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
L49B7:  jmp     MATCH_RULE                      ;

; ----------------------------------------------------------------------------

L49BA:  lda     $F9                             ;
        sta     $F7                             ;
L49BE:  ldy     $FE                             ;
        iny                                     ;
        cpy     ZP_CURRENT_CHARACTER            ;
        bne     @1                              ;
        jmp     L4ACD                           ;

@1:     sty     $FE                             ;
        lda     ($FB),y                         ;
        sta     ZP_CURRENT_CHARACTER_PROPS      ;
        tax                                     ;
        lda     CHARACTER_PROPERTY,x            ;
        and     #$80                            ;
        beq     SW2_49E8                        ;
        ldx     $F7                             ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     ZP_CURRENT_CHARACTER_PROPS      ;
        beq     L49E3                           ;
        jmp     MATCH_RULE                      ;

; ----------------------------------------------------------------------------

L49E3:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

SW2_49E8:

        lda     ZP_CURRENT_CHARACTER_PROPS      ; Switch on content of $F6.
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

        jsr     SUB_GET_CHAR_PROPERTY_F7_NEXT   ;
        and     #$80                            ;
        beq     L4A37                           ;
        jmp     MATCH_RULE                      ;

; ----------------------------------------------------------------------------

L4A37:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

SW2_HASH:

        jsr     SUB_GET_CHAR_PROPERTY_F7_NEXT   ;
        and     #$40                            ;
        bne     L4A37                           ; vowel: go to L4A37.
        jmp     MATCH_RULE                      ; non-vowel

; ----------------------------------------------------------------------------

SW2_PERIOD:

        jsr     SUB_GET_CHAR_PROPERTY_F7_NEXT   ;
        and     #$08                            ;
        bne     L4A50                           ;
        jmp     MATCH_RULE                      ;

; ----------------------------------------------------------------------------

L4A50:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

SW2_AMPERSAND:

        jsr     SUB_GET_CHAR_PROPERTY_F7_NEXT   ;
        and     #$10                            ;
        bne     L4A50                           ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     MATCH_RULE                      ;

@1:     inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'C'                            ;
        beq     L4A50                           ;
        cmp     #'S'                            ;
        beq     L4A50                           ;
        jmp     MATCH_RULE                      ;

; ----------------------------------------------------------------------------

SW2_AT_SIGN:

        jsr     SUB_GET_CHAR_PROPERTY_F7_NEXT   ;
        and     #$04                            ;
        bne     L4A50                           ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     MATCH_RULE                      ;

@1:     cmp     #'T'                            ;
        beq     @2                              ;
        cmp     #'C'                            ;
        beq     @2                              ;
        cmp     #'S'                            ;
        beq     @2                              ;
        jmp     MATCH_RULE                      ;

@2:     stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

SW2_CARET:

        jsr     SUB_GET_CHAR_PROPERTY_F7_NEXT   ;
        and     #$20                            ;
        bne     L4AA4                           ; consonant.
        jmp     MATCH_RULE                      ; non-consonant.

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
        jmp     MATCH_RULE                      ;

; ----------------------------------------------------------------------------

SW2_COLON:

        jsr     SUB_GET_CHAR_PROPERTY_F7_NEXT   ;
        and     #$20                            ;
        bne     @1                              ; consonant.
        jmp     L49BE                           ; non-consonant.

@1:     stx     $F7                             ;
        jmp     SW2_COLON                       ;

; ----------------------------------------------------------------------------

L4ACD:  ldy     ZP_CURRENT_CHARACTER            ;
        lda     $F9                             ;
        sta     ZP_RECITER_BUFFER_INDEX         ;
@1:     lda     ($FB),y                         ;
        sta     ZP_CURRENT_CHARACTER_PROPS      ;
        and     #$7F                            ;
        cmp     #'='                            ;
        beq     @2                              ;
        inc     ZP_SAM_BUFFER_INDEX             ;
        ldx     ZP_SAM_BUFFER_INDEX             ;
        sta     SAM_BUFFER,x                    ;
@2:     bit     ZP_CURRENT_CHARACTER_PROPS      ;
        bpl     @3                              ;
        jmp     TRANSLATE_NEXT_CHARACTER        ;

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
        sta     MEMLO
        sta     $864
        lda     #>TRAILER
        sta     MEMLO+1
        sta     $869
        lda     #0                               ; Reset WARMST to zero.
        sta     WARMST
        rts

; ----------------------------------------------------------------------------

        ; Three macros used to define the pronunciation rules below.

        .macro pronunciation_list_entry Arg
        ; Each entry is a string with the last character's most siginificant bit set to one.
        .repeat .strlen(Arg) - 1, k
        .byte .strat(Arg, k)
        .endrep
        .byte .strat(Arg, .strlen(Arg) - 1) ^ $80
        .endmacro

        .macro pronunciation_index Arg
        ; Each set of letter-specific prononciation rules is preceded by an entry containing "]" followed by the letter.
        pronunciation_list_entry .concat("]", Arg)
        .endmacro

        .macro pronunciation_rule Arg1, Arg2
        ; A rule is a pattern, followd by an "=" sign, followed by the replacement.
        pronunciation_list_entry .concat(Arg1, "=", Arg2)
        .endmacro

; ----------------------------------------------------------------------------

        ; List of the 468 pronunciation rules.

PTAB_MISC:

        pronunciation_rule     "(A)"        , ""
        pronunciation_rule     "(!)"        , "."
        pronunciation_rule     "(\") "      , "-AH5NKWOWT-"
        pronunciation_rule     "(\")"       , "KWOW4T-"
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

; ----------------------------------------------------------------------------

TRAILER: .byte   $EA,$A0                         ; Trailing bytes -- probably not important. MEMLO is set to TRAILER on start.

; ----------------------------------------------------------------------------

        .segment "RECITER_BLOCK2_HEADER"

        ; This is the Atari executable header for the second block in the executable file, which is a small
        ; block that sets the ""RUNAD" pointer used by DOS as the run address for executable files.

        .word   __RECITER_BLOCK2_LOAD__
        .word   __RECITER_BLOCK2_LOAD__ + __RECITER_BLOCK2_SIZE__ - 1

; ----------------------------------------------------------------------------

        .segment "RECITER_BLOCK2"

        ; The content of the second block is just the run address of the code (0x4b23).

        .word _start

; ----------------------------------------------------------------------------
