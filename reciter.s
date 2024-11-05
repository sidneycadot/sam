
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

        .importzp SAM_ZP_CD                     ; Defined by SAM.

        .import SAM_BUFFER                      ; 256-byte buffer where SAM receives its phoneme representation to be rendered as sound.
                                                ; Also used to receive the initial English text.
        .import SAM_SAY_PHONEMES                ; Play the phonemes in SAM_BUFFER as sound.
        .import SAM_COPY_BASIC_SAM_STRING       ; Routine to find and copy SAM$ into the SAM_BUFFER.
        .import SAM_SAVE_ZP_ADDRESSES           ; Save zero-page addresses used by SAM.
        .import SAM_ERROR_SOUND                 ; Routine to signal error using a distinctive error sound.

; ----------------------------------------------------------------------------

        .export RECITER_VIA_SAM_FROM_BASIC
        .export RECITER_VIA_SAM_FROM_MACHINE_LANGUAGE

; ----------------------------------------------------------------------------

        .segment "RECITER_BLOCK1_HEADER"

        ; This is the Atari executable header for the first block, containing the reciter code and data.

        .word   $ffff
        .word   __RECITER_BLOCK1_LOAD__
        .word   __RECITER_BLOCK1_LOAD__ + __RECITER_BLOCK1_SIZE__ - 1

; ----------------------------------------------------------------------------

        .segment "RECITER_BLOCK1"

; ----------------------------------------------------------------------------

ZP_SAM_BUFFER_INDEX     := $F5          ; Destination index in the SAM_BUFFER.
ZP_TEMP1                := $F6          ;
ZP_RB_SUFFIX_INDEX      := $F7          ; Reciter buffer suffix index.
ZP_RB_PREFIX_INDEX      := $F8          ; Reciter buffer prefix index.
ZP_RB_LAST_CHAR_INDEX   := $F9          ;
ZP_RECITER_BUFFER_INDEX := $FA          ; Source index in the RECITER_BUFFER.

ZP_RULE_PTR             := $FB          ; rule pointer
ZP_RULE_PTR_LO          := $FB          ; rule pointer, LSB
ZP_RULE_PTR_HI          := $FC          ; rule pointer, MSB

ZP_TEMP2                := $FD          ;
ZP_RULE_SUFFIX_INDEX    := $FE          ;
ZP_RULE_PREFIX_INDEX    := $FF          ;

; ----------------------------------------------------------------------------

RECITER_BUFFER: .res 256, 0

; ----------------------------------------------------------------------------

        .byte "COPYRIGHT 1982 DON'T ASK"

; ----------------------------------------------------------------------------

CHARACTER_PROPERTIES:

        ; Properties of the 96 characters we support.
        ;
        ; Value 0x00: ignore the character
        ; bit 0 (0x01): 0-9                                                  (digits)
        ; bit 1 (0x02): ! " # $ % & ' * + , - . 0-9 : ; < = > ? @ ^          (special characters and digits)
        ; bit 2 (0x04):       D           J   L   N       R S T           Z
        ; bit 3 (0x08):   B   D     G     J   L M N       R       V W     Z
        ; bit 4 (0x10):     C       G     J                 S         X   Z
        ; bit 5 (0x20):   B C D   F G H   J K L M N   P Q R S T   V W X   Z  (consonants)
        ; bit 6 (0x40): A       E       I           O           U       Y    (vowels)
        ; bit 7 (0x80): A-Z and single quote (') character                   (all letters and single quote)

        .res 32,%00000000                       ; ASCII control characters 0x00..0x1F are all 0x00 (ignore).

        .byte   %00000000                       ; space
        .byte   %00000010                       ; !
        .byte   %00000010                       ; "
        .byte   %00000010                       ; #
        .byte   %00000010                       ; $
        .byte   %00000010                       ; %
        .byte   %00000010                       ; &
        .byte   %10000010                       ; '     -- The single quote has bit 7 set, like A-Z. For things like "brother's" and "haven't".
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

RECITER_VIA_SAM_FROM_MACHINE_LANGUAGE:

        ; The SAM Reciter when entered from machine code.
        ;
        ; The documented way to get here is by calling into "SAM_RUN_RECITER_FROM_MACHINE_LANGUAGE"
        ; (jsr $200B), which is simply a jump to RECITER_VIA_SAM_FROM_MACHINE_LANGUAGE.
        ;
        ; When entering, the English-language string to be translated should be in the SAM_BUFFER.
        ; Here, we're going to copy it to the Reciter buffer, sanatizing the characters on the fly.

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

        ; The string to be translated from English is now in the RECITER_BUFFER.
        ; Translate the RECITER_BUFFER (English) to the SAM_BUFFER (phonemes), then
        ; call into SAM to say the phonemes.

        jsr     TRANSLATE_ENGLISH_TO_PHONEMES   ;

; ----------------------------------------------------------------------------

SAY_PHONEMES:

        jsr     SAM_SAY_PHONEMES                ; Call subroutine in SAM.
        rts                                     ; Done.

; ----------------------------------------------------------------------------

TRANSLATE_ENGLISH_TO_PHONEMES:

        ; Translate English text in the RECITER_BUFFER to phonemes in the SAM_BUFFER.

        lda     #$FF                            ; Point to one before the English language input buffer.
        sta     ZP_RECITER_BUFFER_INDEX         ;

TRANSLATE_NEXT_CHUNK:

        lda     #$FF                            ; Point to one before the SAM phonetic output buffer.
        sta     ZP_SAM_BUFFER_INDEX             ;

; ----------------------------------------------------------------------------

TRANSLATE_NEXT_CHARACTER:

        inc     ZP_RECITER_BUFFER_INDEX         ; Proceed to next character in the source (English) text.
        ldx     ZP_RECITER_BUFFER_INDEX         ;

        lda     RECITER_BUFFER,x                ; Store English character to process in ZP_TEMP2.
        sta     ZP_TEMP2                        ;

        cmp     #$1B                            ; Is the current character the end-of-string character $1B?
        bne     @proceed_1                      ; Nope, proceed.

        inc     ZP_SAM_BUFFER_INDEX             ; Process end-of-string character.
        ldx     ZP_SAM_BUFFER_INDEX             ; Append end-of-string character to the SAM phoneme buffer.
        lda     #$9B                            ;
        sta     SAM_BUFFER,x                    ;
        rts                                     ; Return. The final chunk will be passed to SAM by the caller.

@proceed_1:

        ; Detect and handle end-of-sentence.
        ;
        ; A period character that is not followed by a digit is copied into the SAM phoneme buffer verbatim,
        ; as an "end-of-sentence" indicator to.
        ;
        ; However, periods that are followed by a digit are assumed to be part of a number, and those will be
        ; rendered as "POYNT" by a miscellaneous pronunciation rule later.

        cmp     #'.'                            ; Compare current character to period ('.').
        bne     @proceed_2                      ;
        inx                                     ; Is the period following the period a digit (0-9)?
        lda     RECITER_BUFFER,x                ; Load the next character.
        tay                                     ; Is it a digit (0-9)?
        lda     CHARACTER_PROPERTIES,y          ;
        and     #$01                            ;
        bne     @proceed_2                      ; Yes; the period is not an end-of-sentence indicator. Skip to @proceed_2.

        inc     ZP_SAM_BUFFER_INDEX             ; Handle end-of-sentence period.
        ldx     ZP_SAM_BUFFER_INDEX             ; Append a period character to the SAM phoneme buffer.
        lda     #'.'                            ;
        sta     SAM_BUFFER,x                    ;
        jmp     TRANSLATE_NEXT_CHARACTER        ; Proceed to the next English character.

@proceed_2:                                     ; The current character is not a period, or it is a period followed by a digit.

        lda     ZP_TEMP2                        ; Check if the English character is in the "miscellaneous symbols including digits" class.
        tay                                     ;
        lda     CHARACTER_PROPERTIES,y          ;
        sta     ZP_TEMP1                        ;
        and     #$02                            ;
        beq     @proceed_3                      ; No: proceed.

        lda     #<PTAB_MISC                     ; Apply miscellaneous pronunciation rules.
        sta     ZP_RULE_PTR_LO                  ;
        lda     #>PTAB_MISC                     ;
        sta     ZP_RULE_PTR_HI                  ;
        jmp     TRY_NEXT_RULE                   ;

@proceed_3:

        lda     ZP_TEMP1                        ; Check if the character is "space-like" (i.e., it properties flags are all zero).
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

SAVE_RECITER_BUFFER_INDEX: .byte 0              ; Temporary storage for ZP_RECITER_BUFFER_INDEX while flushing the phoneme buffer.

FLUSH_SAM_BUFFER:

        lda     #$9B                            ; Add an end-of-line to the phoneme buffer.
        sta     SAM_BUFFER,x                    ;

        lda     ZP_RECITER_BUFFER_INDEX         ; Save reciter buffer index.
        sta     SAVE_RECITER_BUFFER_INDEX       ;

        sta     SAM_ZP_CD                       ; Store non-zero here to let SAM_SAY_PHONEMES know that this is not
                                                ; the last time it is called. This prevents SAM_SAY_PHONEMES from
                                                ; restoring ZP addresses and re-enabling interrupts when it's done.
                                                ;
                                                ; SAM_SAY_PHONEMES will reset the value of SAM_ZP_CD to zero.

        jsr     SAY_PHONEMES                    ; Speak the current phonemes in the SAM_BUFFER.

        lda     SAVE_RECITER_BUFFER_INDEX       ; Restore the reciter buffer index.
        sta     ZP_RECITER_BUFFER_INDEX         ;

        jmp     TRANSLATE_NEXT_CHUNK            ; Render the next chunk.

; ----------------------------------------------------------------------------

TRANSLATE_ALPHABETIC_CHARACTER:

        lda     ZP_TEMP1                        ; Verify that ZP_TEMP1 contains a value with its most significant bit set.
        and     #$80                            ;
        bne     @good                           ; Character is alphabetic, or a single quote.
        brk                                     ; Abort. Unexpected character type.

@good:  lda     ZP_TEMP2                        ; Load the English character to be processed from ZP_TEMP5.
        sec                                     ; Set ZP_RULE_PTR to the table entry corresponding to the letter.
        sbc     #'A'                            ;
        tax                                     ;
        lda     PTAB_INDEX_LO,x                 ;
        sta     ZP_RULE_PTR_LO                  ;
        lda     PTAB_INDEX_HI,x                 ;
        sta     ZP_RULE_PTR_HI                  ;

TRY_NEXT_RULE:

        ; Scan forward to find a new rule which we will try to match.
        ;
        ; ZP_RULE_PTR is incremented until it points to a value with its most significant bit set.
        ; The rule to be matched comes right after that.
        ; This will be used as the base pointer while attempting to match the text in the RECITER_BUFFER with the rule.

        ldy     #0                              ; Set Y=0 for accessing ZP_RULE_PTR later on.

@1:     clc                                     ; Increment ZP_RULE_PTR by one.
        lda     ZP_RULE_PTR_LO                  ;
        adc     #<1                             ;
        sta     ZP_RULE_PTR_LO                  ;
        lda     ZP_RULE_PTR_HI                  ;
        adc     #>1                             ;
        sta     ZP_RULE_PTR_HI                  ;

        lda     (ZP_RULE_PTR),y                 ; Load byte at address pointed to by ZP_RULE_PTR.
        bpl     @1                              ; Repeat increment until we find a value with its most significant bit set.

        iny                                     ;
@2:     lda     (ZP_RULE_PTR),y                 ; Find '(' character in rule definition.
        cmp     #'('                            ;
        beq     PROCESS_RULE                    ; Found it. process the current rule.
        iny                                     ; Try next character.
        jmp     @2

; ----------------------------------------------------------------------------

PROCESS_RULE:

        ; ZP_RULE_PTR points to a character in front of a rule (which has bit #7 set).
        ; (ZP_RULE_PTR),y is a left-parenthesis character.

        sty     ZP_RULE_PREFIX_INDEX            ; ZP_RULE_PREFIX_INDEX is the offset for the '(' character in the rule.

@1:     iny                                     ; Scan the rule for the ')' character.
        lda     (ZP_RULE_PTR),y                 ;
        cmp     #')'                            ;
        bne     @1                              ;

        sty     ZP_RULE_SUFFIX_INDEX            ; ZP_RULE_SUFFIX_INDEX is the offset for the ')' character in the rule.

@2:     iny                                     ; Scan the rule definition for the '=' character.
        lda     (ZP_RULE_PTR),y                 ;
        and     #$7F                            ; The '=' character may be the last character, so set bit 7 to zero.
        cmp     #'='                            ;   before comparing.
        bne     @2                              ;

        sty     ZP_TEMP2                        ; ZP_TEMP2 is the Y offset for '=' character.

        ; We will now determine if the rule matches, and we start by looking at the stem pattern.
        ; The stem pattern of a rule definition is the characters between the '(' and the ')'.
        ; The stem pattern characters are always matched literally; no wildcards are used.

        ldx     ZP_RECITER_BUFFER_INDEX         ; Initialize ZP_RB_LAST_CHAR_INDEX with current reciter buffer index.
        stx     ZP_RB_LAST_CHAR_INDEX           ;
        ldy     ZP_RULE_PREFIX_INDEX            ; Check for literal match of the rule's stem stem pattern, i.e., 
        iny                                     ;   everything between the '(' and ')' characters in the rule definition.

@stem_match_loop:

        lda     RECITER_BUFFER,x                ; Parenthesized character is a literal match?
        sta     ZP_TEMP1                        ;
        lda     (ZP_RULE_PTR),y                 ;
        cmp     ZP_TEMP1                        ;
        beq     @stem_character_matched         ;
        jmp     TRY_NEXT_RULE                   ; Mismatch: no literal match of stem character.

@stem_character_matched:

        iny                                     ; Increment stem index.
        cpy     ZP_RULE_SUFFIX_INDEX            ; Have we reached the end of the stem?
        bne     @5                              ;
        jmp     MATCH_PREFIX                    ; Literal match of stem successful. Proceed to match the prefix pattern.

@5:     inx                                     ; Increment ZP_RB_LAST_CHAR_INDEX.
        stx     ZP_RB_LAST_CHAR_INDEX           ;
        jmp     @stem_match_loop                ;


MATCH_PREFIX:

        ; After successfully matching the stem pattern, try to match the prefix pattern.
        ; The prefix pattern of a rule definition is the characters in front of the '('.
        ; Unlike the stem pattern, the prefix pattern may include wildcard characters.

        lda     ZP_RECITER_BUFFER_INDEX         ; Index to the anchor character in the English source text.
        sta     ZP_RB_PREFIX_INDEX              ;

MATCH_NEXT_PREFIX_CHARACTER:

        ldy     ZP_RULE_PREFIX_INDEX            ; Load the next character of the prefix pattern, going from right to left.
        dey                                     ;
        sty     ZP_RULE_PREFIX_INDEX            ;
        lda     (ZP_RULE_PTR),y                 ;
        sta     ZP_TEMP1                        ; The prefix pattern character to be matched.
        bpl     @1                              ; If most significant bit is set, we've reached the end of the prefix pattern.
        jmp     MATCH_SUFFIX                    ; The match was successful; proceed to matching the suffix pattern.

@1:     and     #$7F                            ; Set most significant bit to zero, even though it is already zero when we get here.
        tax                                     ; Get character properties of the current prefix pattern character.
        lda     CHARACTER_PROPERTIES,x          ;
        and     #$80                            ; A-Z and the single quote character are matched directly below.
        beq     MATCH_PREFIX_WILDCARD           ; Anything else is handled by MATCH_PREFIX_WILDCARD.

        ldx     ZP_RB_PREFIX_INDEX              ; Load the source character.
        dex                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     ZP_TEMP1                        ; Compare prefix pattern character with source character.
        beq     MATCH_PREFIX_SUCCESS_1          ; They are identical. Proceed to the next character.
        jmp     TRY_NEXT_RULE                   ; Match failure. Abandon the current rule and proceed to the next one.

; ----------------------------------------------------------------------------

MATCH_PREFIX_SUCCESS_1:

        stx     ZP_RB_PREFIX_INDEX              ;
        jmp     MATCH_NEXT_PREFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

MATCH_PREFIX_WILDCARD:

        ; Check for a match of a prefix pattern wildcard character.

        lda     ZP_TEMP1                        ; Load the prefix pattern wildcard character.

        cmp     #' '                            ; Handle ' ' wildcard (space).
        bne     @1                              ;
        jmp     MATCH_PREFIX_WILDCARD_SPACE     ;
@1:     cmp     #'#'                            ; Handle '#' wildcard (vowel).
        bne     @2                              ;
        jmp     MATCH_PREFIX_WILDCARD_HASH      ;
@2:     cmp     #'.'                            ; Handle '.' wildcard.
        bne     @3                              ;
        jmp     MATCH_PREFIX_WILDCARD_PERIOD    ;
@3:     cmp     #'&'                            ; Handle '&' wildcard.
        bne     @4                              ;
        jmp     MATCH_PREFIX_WILDCARD_AMPERSAND ;
@4:     cmp     #'@'                            ; Handle '@' wildcard.
        bne     @5                              ;
        jmp     MATCH_PREFIX_WILDCARD_AT_SIGN   ;
@5:     cmp     #'^'                            ; Handle '^' wildcard (consonant).
        bne     @6                              ;
        jmp     MATCH_PREFIX_WILDCARD_CARET     ;
@6:     cmp     #'+'                            ; Handle '+' wildcard (E/I/Y).
        bne     @7                              ;
        jmp     MATCH_PREFIX_WILDCARD_PLUS      ;
@7:     cmp     #':'                            ; Handle ':' wildcard.
        bne     @8                              ;
        jmp     MATCH_PREFIX_WILDCARD_COLON     ;

@8:     jsr     SAM_ERROR_SOUND                 ; Any other wildcard character: signal error.
        brk                                     ; This should never happen. Abort.

; ----------------------------------------------------------------------------

MATCH_PREFIX_WILDCARD_SPACE:

        ; A space character in a rule matches a small pause in the vocalisation -- a "space".
        ;
        ; Any character that is not A-Z or a single quote matches this.
        ; Single quotes are assumed to also imply that the character is preceded by a letter,
        ; e.g. "haven't" or "brother's".

        jsr     GET_PREFIX_CHARACTER_PROPERTIES ;
        and     #$80                            ;
        beq     MATCH_PREFIX_SUCCESS_2          ; Match: space.
        jmp     TRY_NEXT_RULE                   ; Mismatch: character is a letter or a single quote character.

; ----------------------------------------------------------------------------

MATCH_PREFIX_SUCCESS_2:

        stx     ZP_RB_PREFIX_INDEX              ;
        jmp     MATCH_NEXT_PREFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

MATCH_PREFIX_WILDCARD_HASH:

        ; A '#' character in a rule matches a vowel, i.e., any of:
        ;     {A, E, I, O, U, Y}.

        jsr     GET_PREFIX_CHARACTER_PROPERTIES ;
        and     #$40                            ;
        bne     MATCH_PREFIX_SUCCESS_2          ; Match: vowel.
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_PREFIX_WILDCARD_PERIOD:

        ; A '.' character in a rule matches any of the letters {B, D, G, J, L, M, N, R, V, W, Z}.

        jsr     GET_PREFIX_CHARACTER_PROPERTIES ;
        and     #$08                            ;
        bne     MATCH_PREFIX_SUCCESS_3          ; Match: {B, D, G, J, L, M, N, R, V, W, Z}.
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_PREFIX_SUCCESS_3:

        stx     ZP_RB_PREFIX_INDEX              ;
        jmp     MATCH_NEXT_PREFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

MATCH_PREFIX_WILDCARD_AMPERSAND:

        ; A '&' character in the rule matches any of the letters {C, G, J, S, X, Z} or a two-letter combination {CH, SH}.

        jsr     GET_PREFIX_CHARACTER_PROPERTIES ;
        and     #$10                            ;
        bne     MATCH_PREFIX_SUCCESS_3          ; Match: {C, G, J, S, X, Z}.
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     TRY_NEXT_RULE                   ; Mismatch.

@1:     dex                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'C'                            ;
        beq     MATCH_PREFIX_SUCCESS_3          ; Match: "CH".
        cmp     #'S'                            ;
        beq     MATCH_PREFIX_SUCCESS_3          ; Match: "SH".
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_PREFIX_WILDCARD_AT_SIGN:

        ; A '@' character in the rule being matched indicates any of the letters {D, J, L, N, R, S, T, Z} or a two-letter combination {TH, CH, SH}.

        jsr     GET_PREFIX_CHARACTER_PROPERTIES ;
        and     #$04                            ;
        bne     MATCH_PREFIX_SUCCESS_3          ; Match: {D, J, L, N, R, S, T, Z}.
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     TRY_NEXT_RULE                   ; Mismatch.

@1:     cmp     #'T'                            ; *** BUG *** Forgot to go to the next letter, yikes!
        beq     MATCH_PREFIX_SUCCESS_4          ; All comparisons will fail.
        cmp     #'C'                            ;
        beq     MATCH_PREFIX_SUCCESS_4          ;
        cmp     #'S'                            ;
        beq     MATCH_PREFIX_SUCCESS_4          ;
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_PREFIX_SUCCESS_4:

        stx     ZP_RB_PREFIX_INDEX              ;
        jmp     MATCH_NEXT_PREFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

MATCH_PREFIX_WILDCARD_CARET:

        ; A '^' character matches a consonant, i.e., any of:
        ;     {B, C, D, F, G, H, J, K, L, M, N, P, Q, R, S, T, V, W, X, Z}.

        jsr     GET_PREFIX_CHARACTER_PROPERTIES ;
        and     #$20                            ;
        bne     MATCH_PREFIX_SUCCESS_5          ; Match: consonant.
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_PREFIX_SUCCESS_5:

        stx     ZP_RB_PREFIX_INDEX              ;
        jmp     MATCH_NEXT_PREFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

MATCH_PREFIX_WILDCARD_PLUS:

        ; A '+' character matches any of the letters {E, I, Y}.

        ldx     ZP_RB_PREFIX_INDEX              ;
        dex                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'E'                            ;
        beq     MATCH_PREFIX_SUCCESS_5          ; Match: "E".
        cmp     #'I'                            ;
        beq     MATCH_PREFIX_SUCCESS_5          ; Match: "I".
        cmp     #'Y'                            ;
        beq     MATCH_PREFIX_SUCCESS_5          ; Match: "Y".
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_PREFIX_WILDCARD_COLON:

        ; Match zero or more consonants.

        jsr     GET_PREFIX_CHARACTER_PROPERTIES ;
        and     #$20                            ;
        bne     @consonant                      ;
        jmp     MATCH_NEXT_PREFIX_CHARACTER     ; Not a consonant. Proceed to the next prefix pattern character.
@consonant:
        stx     ZP_RB_PREFIX_INDEX              ;
        jmp     MATCH_PREFIX_WILDCARD_COLON     ;

; ----------------------------------------------------------------------------

GET_PREFIX_CHARACTER_PROPERTIES:

        ldx     ZP_RB_PREFIX_INDEX              ;
        dex                                     ;
        lda     RECITER_BUFFER,x                ;
        tay                                     ;
        lda     CHARACTER_PROPERTIES,y          ;
        rts                                     ;

; ----------------------------------------------------------------------------

GET_SUFFIX_CHARACTER_PROPERTIES:

        ldx     ZP_RB_SUFFIX_INDEX              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        tay                                     ;
        lda     CHARACTER_PROPERTIES,y          ;
        rts                                     ;

; ----------------------------------------------------------------------------

MATCH_SUFFIX_WILDCARD_PERCENT:

        ldx     ZP_RB_SUFFIX_INDEX              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'E'                            ;
        bne     @2                              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        tay                                     ;
        dex                                     ;
        lda     CHARACTER_PROPERTIES,y          ;
        and     #$80                            ;
        beq     @MATCH_SUFFIX_SUCCESS_1         ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'R'                            ;

        bne     @continue                       ;

; ----------------------------------------------------------------------------

@MATCH_SUFFIX_SUCCESS_1:

        stx     ZP_RB_SUFFIX_INDEX              ;
        jmp     MATCH_NEXT_SUFFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

@continue:

        cmp     #'S'                            ;
        beq     @MATCH_SUFFIX_SUCCESS_1         ;
        cmp     #'D'                            ;
        beq     @MATCH_SUFFIX_SUCCESS_1         ;
        cmp     #'L'                            ;
        bne     @1                              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'Y'                            ;
        bne     @3                              ;
        beq     @MATCH_SUFFIX_SUCCESS_1         ;
@1:     cmp     #'F'                            ;
        bne     @3                              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'U'                            ;
        bne     @3                              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'L'                            ;
        beq     @MATCH_SUFFIX_SUCCESS_1         ;
        bne     @3                              ;
@2:     cmp     #'I'                            ;
        bne     @3                              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'N'                            ;
        bne     @3                              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'G'                            ;
        beq     @MATCH_SUFFIX_SUCCESS_1         ;
@3:     jmp     TRY_NEXT_RULE                   ;

; ----------------------------------------------------------------------------

MATCH_SUFFIX:

        ; After successfully matching the stem pattern and the prefix pattern, try to match the suffix pattern.
        ; The suffix pattern of a rule definition is the characters after the ')' and before the '='.
        ; Like the prefix pattern, the suffix pattern may include wildcard characters.

        lda     ZP_RB_LAST_CHAR_INDEX           ; Index to the anchor character in the English source text.
        sta     ZP_RB_SUFFIX_INDEX              ;

; ----------------------------------------------------------------------------

MATCH_NEXT_SUFFIX_CHARACTER:

        ldy     ZP_RULE_SUFFIX_INDEX            ; Load the next character of the suffix pattern, going from left to right.
        iny                                     ;
        cpy     ZP_TEMP2                        ; Compare to location of '=' character in rule.
        bne     @1                              ;
        jmp     APPLY_RULE                      ; We've reached the end of the suffix pattern. The match was successful, apply the rule.

@1:     sty     ZP_RULE_SUFFIX_INDEX            ;
        lda     (ZP_RULE_PTR),y                 ;
        sta     ZP_TEMP1                        ; The suffix pattern character to be matched.
        tax                                     ;
        lda     CHARACTER_PROPERTIES,x          ;
        and     #$80                            ; A-Z and the single quote character are matched directly below.
        beq     MATCH_SUFFIX_WILDCARD           ; Anything else is handled by MATCH_SUFFIX_WILDCARD.

        ldx     ZP_RB_SUFFIX_INDEX              ; Load the source character.
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     ZP_TEMP1                        ; Compare suffix pattern character with source character.
        beq     MATCH_SUFFIX_SUCCESS_2          ; They are identical. Proceed to the next character.
        jmp     TRY_NEXT_RULE                   ; 

; ----------------------------------------------------------------------------

MATCH_SUFFIX_SUCCESS_2:

        stx     ZP_RB_SUFFIX_INDEX              ;
        jmp     MATCH_NEXT_SUFFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

MATCH_SUFFIX_WILDCARD:

        ; Check for match of a suffix pattern wildcard character.

        lda     ZP_TEMP1                        ; Load the match rule placeholder character.

        cmp     #' '                            ; Handle ' ' wildcard (space).
        bne     @1                              ;
        jmp     MATCH_SUFFIX_WILDCARD_SPACE     ;
@1:     cmp     #'#'                            ; Handle '#' wildcard (vowel).
        bne     @2                              ;
        jmp     MATCH_SUFFIX_WILDCARD_HASH      ;
@2:     cmp     #'.'                            ; Handle '.' wildcard.
        bne     @3                              ;
        jmp     MATCH_SUFFIX_WILDCARD_PERIOD    ;
@3:     cmp     #'&'                            ; Handle '&' wildcard.
        bne     @4                              ;
        jmp     MATCH_SUFFIX_WILDCARD_AMPERSAND ;
@4:     cmp     #'@'                            ; Handle '@' wildcard.
        bne     @5                              ;
        jmp     MATCH_SUFFIX_WILDCARD_AT_SIGN   ;
@5:     cmp     #'^'                            ; Handle '^' wildcard (consonant).
        bne     @6                              ;
        jmp     MATCH_SUFFIX_WILDCARD_CARET     ;
@6:     cmp     #'+'                            ; Handle '+' wildcard (E/I/Y).
        bne     @7                              ;
        jmp     MATCH_SUFFIX_WILDCARD_PLUS      ;
@7:     cmp     #':'                            ; Handle ':' wildcard.
        bne     @8                              ;
        jmp     MATCH_SUFFIX_WILDCARD_COLON     ;
@8:     cmp     #'%'                            ; Handle '%' wildcard.
        bne     @9                              ;
        jmp     MATCH_SUFFIX_WILDCARD_PERCENT   ;

@9:     jsr     SAM_ERROR_SOUND                 ; Any other wildcard character: signal error.
        brk                                     ; This should never happen. Abort.

; ----------------------------------------------------------------------------

MATCH_SUFFIX_WILDCARD_SPACE:

        ; A space character matches a small pause in the vocalisation -- a "space".
        ;
        ; Any character that is not A-Z or a single quote matches this.
        ; Single quotes are assumed to also imply that the character is preceded by a letter,
        ; e.g. "haven't" or "brother's".

        jsr     GET_SUFFIX_CHARACTER_PROPERTIES ;
        and     #$80                            ;
        beq     MATCH_SUFFIX_SUCCESS_3          ; Match: space.
        jmp     TRY_NEXT_RULE                   ; Mismatch: character is a letter or a single quote character.

; ----------------------------------------------------------------------------

MATCH_SUFFIX_SUCCESS_3:

        stx     ZP_RB_SUFFIX_INDEX              ;
        jmp     MATCH_NEXT_SUFFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

MATCH_SUFFIX_WILDCARD_HASH:

        ; A '#' character in the rule matches a vowel, i.e., any of:
        ;     {A, E, I, O, U, Y}.

        jsr     GET_SUFFIX_CHARACTER_PROPERTIES ;
        and     #$40                            ;
        bne     MATCH_SUFFIX_SUCCESS_3          ; Match: vowel.
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_SUFFIX_WILDCARD_PERIOD:

        ; A '.' character in the rule matches any of the letters {B, D, G, J, L, M, N, R, V, W, Z}.

        jsr     GET_SUFFIX_CHARACTER_PROPERTIES ;
        and     #$08                            ;
        bne     MATCH_SUFFIX_SUCCESS_4          ; Match: {B, D, G, J, L, M, N, R, V, W, Z}.
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_SUFFIX_SUCCESS_4:

        stx     ZP_RB_SUFFIX_INDEX              ;
        jmp     MATCH_NEXT_SUFFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

MATCH_SUFFIX_WILDCARD_AMPERSAND:

        ; A '&' character in the rule tries to match any of the letters {C, G, J, S, X, Z} or a two-letter combination {CH, SH}.
        ;
        ; That's the intention, but there is a bug here.
        ;
        ; *** BUG *** This code is more-or-less identical to the code in MATCH_PREFIX_AMPERSAND,
        ;             but here we're scanning from left-to-right, which is makes a difference for
        ;             handling the two-character matches.
        ;
        ; Intended behavior : match C / G / J / S / X / Z / CH / SH
        ; Actual behavior   : match C / G / J / S / X / Z / HC / HS

        jsr     GET_SUFFIX_CHARACTER_PROPERTIES ;
        and     #$10                            ;
        bne     MATCH_SUFFIX_SUCCESS_4          ; Match: {C, G, J, S, X, Z}.
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     TRY_NEXT_RULE                   ;

@1:     inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'C'                            ;
        beq     MATCH_SUFFIX_SUCCESS_4          ; Match: "HC".
        cmp     #'S'                            ;
        beq     MATCH_SUFFIX_SUCCESS_4          ; Match: "HS".
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_SUFFIX_WILDCARD_AT_SIGN:

        ; A '@' character in the rule tries to match any of the letters {D / J / L / N / R / S / T / Z}
        ;   or a two-letter combination {TH, CH, SH}.
        ;
        ; That's the intention, but there is a bug here.
        ;
        ; *** BUG *** This code is more-or-less identical to the code in MATCH_PREFIX_AT_SIGN,
        ;             but here we're scanning from left-to-right, which is makes a difference for
        ;             handling the two-character matches.
        ;
        ; Intended behavior : match D / J / L / N / R / S / T / Z / TH / CH / SH.
        ; Actual behavior   : match D / J / L / N / R / S / T / Z / HT / HC / HS.

        jsr     GET_SUFFIX_CHARACTER_PROPERTIES ;
        and     #$04                            ;
        bne     MATCH_SUFFIX_SUCCESS_4          ; Match: {D, J, L, N, R, S, T, Z}.
        lda     RECITER_BUFFER,x                ;
        cmp     #'H'                            ;
        beq     @1                              ;
        jmp     TRY_NEXT_RULE                   ; Mismatch.

@1:     cmp     #'T'                            ;
        beq     MATCH_SUFFIX_SUCCESS_5          ; Match: "HT".
        cmp     #'C'                            ;
        beq     MATCH_SUFFIX_SUCCESS_5          ; Match: "HC".
        cmp     #'S'                            ;
        beq     MATCH_SUFFIX_SUCCESS_5          ; Match: "HS".
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_SUFFIX_SUCCESS_5:

        stx     ZP_RB_SUFFIX_INDEX              ;
        jmp     MATCH_NEXT_SUFFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

MATCH_SUFFIX_WILDCARD_CARET:

        ; A '^' character matches a consonant, i.e., any of:
        ;     {B, C, D, F, G, H, J, K, L, M, N, P, Q, R, S, T, V, W, X, Z}.

        jsr     GET_SUFFIX_CHARACTER_PROPERTIES ;
        and     #$20                            ;
        bne     MATCH_SUFFIX_SUCCESS_6          ; Match: consonant.
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_SUFFIX_SUCCESS_6:

        stx     ZP_RB_SUFFIX_INDEX              ;
        jmp     MATCH_NEXT_SUFFIX_CHARACTER     ;

; ----------------------------------------------------------------------------

MATCH_SUFFIX_WILDCARD_PLUS:

        ; A '+' character matches any of the letters {E, I, Y}.

        ldx     ZP_RB_SUFFIX_INDEX              ;
        inx                                     ;
        lda     RECITER_BUFFER,x                ;
        cmp     #'E'                            ;
        beq     MATCH_SUFFIX_SUCCESS_6          ; Match "E".
        cmp     #'I'                            ;
        beq     MATCH_SUFFIX_SUCCESS_6          ; Match "I".
        cmp     #'Y'                            ;
        beq     MATCH_SUFFIX_SUCCESS_6          ; Match "Y".
        jmp     TRY_NEXT_RULE                   ; Mismatch.

; ----------------------------------------------------------------------------

MATCH_SUFFIX_WILDCARD_COLON:

        ; Match zero or more consonants.

        jsr     GET_SUFFIX_CHARACTER_PROPERTIES ;
        and     #$20                            ;
        bne     @consonant                      ; consonant.
        jmp     MATCH_NEXT_SUFFIX_CHARACTER     ; non-consonant.
@consonant:
        stx     ZP_RB_SUFFIX_INDEX              ;
        jmp     MATCH_SUFFIX_WILDCARD_COLON     ;

; ----------------------------------------------------------------------------

APPLY_RULE:

        ; The rule fully matches; perform the translation.

        ldy     ZP_TEMP2                        ; Location of '=' character.
        lda     ZP_RB_LAST_CHAR_INDEX           ;
        sta     ZP_RECITER_BUFFER_INDEX         ; Update ZP_RECITER_BUFFER_INDEX.
@loop:  lda     (ZP_RULE_PTR),y                 ; Load rule character.
        sta     ZP_TEMP1                        ; Save to ZP_TEMP1, for end-of-loop sign bit check.
        and     #$7F                            ; Make sure sign bit is not set.
        cmp     #'='                            ; Is it an '=' character?
        beq     @skip                           ; Yes, skip character copy.
        inc     ZP_SAM_BUFFER_INDEX             ; Copy rule replacement character to the SAM_BUFFER,
        ldx     ZP_SAM_BUFFER_INDEX             ; and increment ZP_SAM_BUFFER_INDEX.
        sta     SAM_BUFFER,x                    ;
@skip:  bit     ZP_TEMP1                        ; Was the most significant bit of the rule character set?
        bpl     @proceed                        ; No: proceed to next rule character.

        jmp     TRANSLATE_NEXT_CHARACTER        ; Yes: Done copying; proceed with the next character.

@proceed:

        iny                                     ; Proceed to next rule character.
        jmp     @loop                           ;

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

        ; List of the 442 pronunciation rules.

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
