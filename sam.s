
; ----------------------------------------------------------------------------

        .setcpu "6502"

; ----------------------------------------------------------------------------

        .import __SAM_BLOCK1_LOAD__, __SAM_BLOCK1_SIZE__
        .import __SAM_BLOCK2_LOAD__, __SAM_BLOCK2_SIZE__
        .import __SAM_BLOCK3_LOAD__, __SAM_BLOCK3_SIZE__

; ----------------------------------------------------------------------------

        .importzp WARMST
        .importzp POKMSK
        .importzp RTCLOK
        .importzp VNTP
        .importzp VNTD
        .importzp VVTP
        .importzp STARP
        .import MEMLO
        .import BASIC
        .import CONSOL
        .import AUDC1
        .import IRQEN
        .import DMACTL
        .import NMIEN

; ----------------------------------------------------------------------------

        .import RECITER_VIA_SAM_FROM_BASIC
        .import RECITER_VIA_SAM_FROM_MACHINE_LANGUAGE

; ----------------------------------------------------------------------------

        .exportzp SAM_ZP_CD

        .export SAM_BUFFER                      ; 256-byte buffer where SAM receives its phoneme representation to be rendered as sound.
        .export SAM_SAY_PHONEMES                ; Play the phonemes in SAM_BUFFER as sound.
        .export SAM_COPY_BASIC_SAM_STRING       ; Routine to find and copy SAM$ into the SAM_BUFFER.
        .export SAM_SAVE_ZP_ADDRESSES           ; Save zero-page addresses used by SAM.
        .export SAM_ERROR_SOUND                 ; Routine to signal error using a distinctive error sound.

; ----------------------------------------------------------------------------

        .segment "SAM_BLOCK1_HEADER"

        ; This is the Atari executable header for the first block.

        .word   $ffff
        .word   __SAM_BLOCK1_LOAD__
        .word   __SAM_BLOCK1_LOAD__ + __SAM_BLOCK1_SIZE__ - 1

; ----------------------------------------------------------------------------

        .segment "SAM_BLOCK1"

; ----------------------------------------------------------------------------

; Note: addresses $CB and $CC are used for two things:

ZP_CB_PTR := $CB                                ; Used in "SAM_COPY_BASIC_SAM_STRING" as a cariable index counter,
ZP_CB_PTR_LO := $CB                             ; then as a pointer into the Atari BASIC variable value table.
ZP_CB_PTR_HI := $CC                             ;

ZP_CB_SAM_STRING_RESULT := $CB                  ; Secondary usage: result code from ZP_CB_SAM_STRING_FOUND.
ZP_CC_TEMP := $CC                               ; Secondary usage: counter in SAM_ERROR_SOUND.

; Address $CD is used as a temporary variable in SAM_COPY_BASIC_SAM_STRING to hold the size of the string copied
; from SAM$ into SAM_BUFFER.
;
; TODO: document/figure out its use outside of SAM_COPY_BASIC_SAM_STRING.

SAM_ZP_CD := $CD                                ; TODO

ZP_CE_PTR    := $CE                             ; Exclusively used in "SAM_COPY_BASIC_SAM_STRING" as a pointer into
ZP_CE_PTR_LO := $CE                             ; the Atari BASIC variable name table while looking for SAM$.
ZP_CE_PTR_HI := $CF                             ;

ZP_D0_PTR := $D0                                ; Exclusively used in "SAM_COPY_BASIC_SAM_STRING" as a to
ZP_D0_PTR_LO := $D0                             ; the content of SAM$.
ZP_D0_PTR_HI := $D1                             ;

ZP_E0 := $E0                                    ;
ZP_E1 := $E1                                    ;
ZP_E2 := $E2                                    ;
ZP_E3 := $E3                                    ;
ZP_E4 := $E4                                    ;
ZP_E5 := $E5                                    ;
ZP_E6 := $E6                                    ;
ZP_E7 := $E7                                    ;
ZP_E8 := $E8                                    ;
ZP_E9 := $E9                                    ;
ZP_EA := $EA                                    ;

;
;
;

ZP_EB_PTR := $EB                                ;
ZP_EB_PTR_LO := $EB                             ;
ZP_EB_PTR_HI := $EC                             ;

;

ZP_ED := $ED                                    ;
ZP_EE := $EE                                    ;
ZP_EF := $EF                                    ;
ZP_F0 := $F0                                    ;
ZP_F1 := $F1                                    ;
ZP_F2 := $F2                                    ;
ZP_F3 := $F3                                    ;
ZP_F4 := $F4                                    ;
ZP_F5 := $F5                                    ;
ZP_F6 := $F6                                    ;
ZP_F7 := $F7                                    ;
ZP_F8 := $F8                                    ;
ZP_F9 := $F9                                    ;
ZP_SAVE_Y := $FA                                ;
ZP_SAVE_X := $FB                                ;
ZP_SAVE_A := $FC                                ;
ZP_FD := $FD                                    ;
ZP_FE := $FE                                    ;
ZP_FF := $FF                                    ;

; ----------------------------------------------------------------------------

        ; SAM entry point from BASIC (address 8192).
        ; SAM$ is assumed to contain a string holding phonemes.

; ----------------------------------------------------------------------------

SAM_RUN_SAM_FROM_BASIC:

        pla                                     ; Pop the number of arguments from the 6502 stack that was pushed by Atari BASIC.
        jmp     RUN_SAM_FROM_BASIC              ;

; ----------------------------------------------------------------------------

        ; SAM entry point from machine code (address $2004).
        ; The phonemes are assumed to be in the SAM_BUFFER.

SAM_RUN_SAM_FROM_MACHINE_LANGUAGE:

        jmp     RUN_SAM_FROM_MACHINE_LANGUAGE   ;

; ----------------------------------------------------------------------------

        ; Reciter entry point from BASIC (address 8199).
        ; SAM$ is assumed to contain a string holding English text.

SAM_RUN_RECITER_FROM_BASIC:

        pla                                     ; Pop the number of arguments from the 6502 stack that was pushed by Atari BASIC.
        jmp     RECITER_VIA_SAM_FROM_BASIC      ;

; ----------------------------------------------------------------------------

SAM_RUN_RECITER_FROM_MACHINE_LANGUAGE:

        ; Reciter entry point from machine code (address $200B).
        ; The English text is assumed to be in the SAM_BUFFER.

        jmp     RECITER_VIA_SAM_FROM_MACHINE_LANGUAGE

; ----------------------------------------------------------------------------

SPEED_L1:       .byte   $41                     ; Lights-on  speed value(self-modifying code value).
PITCH_L1:       .byte   $40                     ; Lights-on  pitch value (self-modifying code value).
SPEED_L0:       .byte   $46                     ; Lights-off speed value (self-modifying code value).
PITCH_L0:       .byte   $40                     ; Lights-off pitch value(self-modifying code value).
LIGHTS:         .byte   0                       ; Lights 0 = video off (default), Lights 1 = video on.
ERROR:          .byte   $FF                     ;

; ----------------------------------------------------------------------------

        ; This is the 256-byte input buffer for SAM. It is pre-loaded with a small phonetic greeting:
        ;
        ;     "Hello, my name is Sam. I am a speech synthesizer on a disk."

SAM_BUFFER:

        .byte   "/HEH3LOW. MAY3 NEYM IHZ SAE4M. AY3 AEM AH  SPIY4CH SIH4NTHAHSAYZER-AA5N AH DIH2SK.", $9B
        .res 173, 0

; ----------------------------------------------------------------------------

RUN_SAM_FROM_BASIC:                             ; Entry point from BASIC (after PLA).

        jsr     SAM_COPY_BASIC_SAM_STRING       ; Find SAM$ and copy its content into the SAM_BUFFER.
        lda     ZP_CB_SAM_STRING_RESULT         ; Is result zero (good?)
        beq     RUN_SAM_FROM_MACHINE_LANGUAGE   ; Yes: play the phonemes.
        rts                                     ; No: return to BASIC.

; ----------------------------------------------------------------------------

RUN_SAM_FROM_MACHINE_LANGUAGE:

        ; The documented way to get here is by calling into "SAM_RUN_SAM_FROM_MACHINE_LANGUAGE"
        ; (jsr $2004), which is simply a jump to RUN_SAM_FROM_MACHINE_LANGUAGE.

        jsr     SAM_SAVE_ZP_ADDRESSES           ; Save ZP addresses, then proceed with SAM_SAY_PHONEMES.

; ----------------------------------------------------------------------------

SAM_SAY_PHONEMES:                               ; Render phonemes in SAM_BUFFER as sound.

        ; When we get here, it is expected that SAM_SAVE_ZP_ADDRESSES has been called
        ; previously to save addresses $E1..$FF.
        ;
        ; The content of SAM_ZP_CD on enrty of this function is important.
        ; If it is zero (the normal value), SAM_SAY_PHONEMES will restore zero
        ; page addresses ($E1..$FF range) and re-enable interrupts when done.
        ;
        ; To prevent this, the caller can set SAM_ZP_CD to a non-zero value prior
        ; to the call, which promises that the current call is not the last call.
        ;
        ; SAM_SAY_PHONEMES itself resets SAM_ZP_CD back to zero.

        lda     #$FF                            ;
        sta     ERROR                           ;
        jsr     SUB_26EA                        ; Translate text-based SAM_BUFFER phonemes to binary.
        lda     ERROR                           ;
        cmp     #$FF                            ;
        bne     @5                              ;
        jsr     SUB_2837                        ;
        jsr     SUB_2A1D                        ;
        jsr     SUB_2775                        ;
        jsr     SUB_43F2                        ;
        jsr     SUB_279A                        ;

        lda     #0                              ; Time-critical section starts here:
        sta     NMIEN                           ; - Disable NMI interrupts.
        sta     IRQEN                           ; - Disable IRQ interrupts.

        lda     LIGHTS                          ; Select mode #0 (normal) or mode #1 (debug?)
        beq     @lights_off                     ;

        lda     #1                              ; Lights on: Initialize self-modifying code values.
        sta     SMC_42DF                        ;
        sta     SMC_4210                        ;
        sta     SMC_42B0                        ;
        lda     PITCH_L1                        ;
        sta     SMC_PITCH                       ;
        lda     SPEED_L1                        ;
        sta     SMC_SPEED                       ;
        jmp     @join                           ;

@lights_off:

        lda     #0                              ; Initialize lights off (default) mode.
        sta     DMACTL                          ; Disable DMA (Antic). NOTE: It is never restored?
        lda     #16                             ; Initialize self-modifying code values.
        sta     SMC_4210                        ;
        lda     #13                             ;
        sta     SMC_42B0                        ;
        lda     #12                             ;
        sta     SMC_42DF                        ;
        lda     PITCH_L0                        ;
        sta     SMC_PITCH                       ;
        lda     SPEED_L0                        ;
        sta     SMC_SPEED                       ;

@join:  lda     D2262,x                         ;
        cmp     #80                             ;
        bcs     @3                              ;
        inx                                     ;
        bne     @join                           ;
        beq     @4                              ;
@3:     lda     #$FF                            ;
        sta     D2262,x                         ;

@4:     jsr     SUB_4336                        ;

        lda     #$FF                            ; Ensure there's a termination phoneme.
        sta     D2262 + $FE                     ;

        jsr     SUB_43AA                        ;

        ldx     #0                              ; Inspect SAM_ZP_CD to see if it is currently 0.
        cpx     SAM_ZP_CD                       ;
        stx     SAM_ZP_CD                       ; Always reset SAM_ZP_CD to zero.
        beq     @5                              ; If it was previously zero, restore ZP addresses and interrupts.
        rts                                     ; If not, just return.

@5:     jsr     SAM_RESTORE_ZP_ADDRESSES        ; Restore zero page addresses.
        lda     #$FF                            ;
        sta     NMIEN                           ; Enable NMI interrupts.
        lda     POKMSK                          ; Load shadow IRQ enabled mask.
        sta     IRQEN                           ; Restore IRQ interrupts.
        rts                                     ;

; ----------------------------------------------------------------------------

SAM_COPY_BASIC_SAM_STRING:

        ; This subroutine searches the BASIC string variable SAM$ and copies its contents
        ; into the SAM_BUFFER. Setting SAM$ is the prescribed way to pass data to SAM or
        ; the Reciter when using Atari BASIC.
        ;
        ; This routine is called as the first thing when SAM is called directly from BASIC.
        ; It is also called from the RECITER.
        ;
        ; *** BUG *** The code matches any BASIC string variable that ends with "SAM$".
        ;             So FLOTSAM$ or JETSAM$ will also be matched.
        ;
        ; If a string name ending in SAM$ is found, its content is copied to the SAM_BUFFER.
        ;
        ; *** Note #1 *** Dual use of $CB.
        ;
        ; In this routine, the variable $CB is used for two purposes:
        ;
        ; (1) As the lo byte of the ZP_CB_PTR, while looking for and copying the string.
        ;     When used like this, the address is called ZP_CB_PTR_LO.
        ; (2) To report success/failure back to the caller, at the end of the subroutine.
        ;     When used like this, the address is called ZP_CB_SAM_STRING_RESULT.
        ;
        ; *** Note #2 *** Use of ZP_SAM_CD in this routine.
        ;
        ; The use of the variable "SAM_ZP_CD" in this subroutine is somewhat confusing.
        ;
        ; * It is initialized to 0 at the start.
        ; * It is used to hold the size of the string being copied from.
        ; * It is set to zero in the succesful return path.
        ;
        ; The net result, as seen from the caller, is that this routine always sets SAM_ZP_CD to zero.

        lda     #0                              ; Initialize ZP_CB_PTR and ZP_CD to zero.
        sta     ZP_CB_PTR_LO                    ; For now, ZP_CB_PTR will hold a 0-based variable index;
        sta     ZP_CB_PTR_HI                    ;   it will become a proper pointer later on.

        sta     SAM_ZP_CD                       ; Initialize string size to 0.

        lda     VNTP                            ; Copy variable name table pointer VNTP to ZP_CE_PTR.
        sta     ZP_CE_PTR_LO                    ;
        lda     VNTP+1                          ;
        sta     ZP_CE_PTR_HI                    ;

        lda     STARP                           ; Copy string and array pointer STARP to ZP_D0_PTR.
        sta     ZP_D0_PTR_LO                    ;
        lda     STARP+1                         ;
        sta     ZP_D0_PTR_HI                    ;

@check_variable_name:

        ldy     #0                              ; Check if we find "SAM$" at the ZP_CE_PTR location.
        lda     (ZP_CE_PTR),y                   ;
        cmp     #'S'                            ;
        bne     @not_found_here                 ; If not found, proceed to @not_found_here.
        iny                                     ;
        lda     (ZP_CE_PTR),y                   ;
        cmp     #'A'                            ;
        bne     @not_found_here                 ;
        iny                                     ;
        lda     (ZP_CE_PTR),y                   ;
        cmp     #'M'                            ;
        bne     @not_found_here                 ;
        iny                                     ;
        lda     (ZP_CE_PTR),y                   ;
        cmp     #'$' + $80                      ; String names end with '$', with the most significant bit set to one.
        bne     @not_found_here                 ;
        jmp     @found_sam_string_variable      ; If found, proceed to @found_sam_string_variable.

@not_found_here:

        lda     ZP_CE_PTR_LO                    ; Check if pointer ZP_CE_PTR is identical to VNTD, which
        cmp     VNTD                            ; is the end of BASIC variable name memory.
        bne     @continue_search                ; If not equal, continue the search.
        lda     ZP_CE_PTR_HI                    ;
        cmp     VNTD+1                          ; If equal, we've reached the end of the BASIC program,
        beq     @report_error                   ; and we didn't find a matching variable name. Report an error.

@continue_search:

        ldy     #0                              ;
        lda     (ZP_CE_PTR),y                   ;
        bpl     @1                              ; Increment variable index whenever we pass over
        inc     ZP_CB_PTR_LO                    ;   a character with its most significant bit set.

@1:     inc     ZP_CE_PTR_LO                    ; Increment ZP_CE_PTR.
        bne     @2                              ;
        inc     ZP_CE_PTR_HI                    ;
@2:     jmp     @check_variable_name            ; Proceed to check if the variable name is in this new location.

@found_sam_string_variable:

        clc                                     ; Multiply variable index ZP_CB_PTR by 8.
        asl     ZP_CB_PTR_LO                    ;
        rol     ZP_CB_PTR_HI                    ;
        asl     ZP_CB_PTR_LO                    ;
        rol     ZP_CB_PTR_HI                    ;
        asl     ZP_CB_PTR_LO                    ;
        rol     ZP_CB_PTR_HI                    ;

        clc                                     ; Make ZP_CB_PTR an address into the Atari BASIC variable value table.
        lda     ZP_CB_PTR_LO                    ;
        adc     VVTP                            ; In other words: ptr = VVTP + 8 * index_when_found
        sta     ZP_CB_PTR_LO                    ;
        lda     ZP_CB_PTR_HI                    ;
        adc     VVTP+1                          ;
        sta     ZP_CB_PTR_HI                    ;

        ldy     #5                              ; Fifth byte of entry is MSB of size.
        lda     (ZP_CB_PTR),y                   ; If the size of the string exceeds 255, report an error.
        bne     @report_error                   ;

        dey                                     ; Copy string size (LSB of string size word) into SAM_ZP_CD.
        lda     (ZP_CB_PTR),y                   ;
        sta     SAM_ZP_CD                       ;

        ldy     #2                              ; Prepare ZP_D0_PTR to point at the beginning of the content of SAM$.
        lda     (ZP_CB_PTR),y                   ;
        clc                                     ; ZP_D0_PTR = STARP + offset.
        adc     ZP_D0_PTR_LO                    ;
        sta     ZP_D0_PTR_LO                    ; Note: it is unclear why ZP_D0_PTR_LO was initialized above.
        ldy     #3                              ; Adding to STARP here would be more efficient.
        lda     (ZP_CB_PTR),y                   ;
        adc     ZP_D0_PTR_HI                    ;
        sta     ZP_D0_PTR_HI                    ;

        ldy     #0                              ; Copy content of SAM$ into SAM_BUFFER.
@copy:  lda     (ZP_D0_PTR),y                   ;
        sta     SAM_BUFFER,y                    ;
        iny                                     ;
        cpy     SAM_ZP_CD                       ; Equal to string size?
        bne     @copy                           ;

        lda     #$9B                            ; Append $9B character, denoting end of line.
        sta     SAM_BUFFER,y                    ;

@success:

        lda     #0                              ; Use address $CB now to report back the result code. 0 = success.
        sta     ZP_CB_SAM_STRING_RESULT         ; 
        sta     SAM_ZP_CD                       ; Reset SAM_ZP_CD to zero.
        rts                                     ; Return succesfully.

@report_error:

        jsr     SAM_ERROR_SOUND                 ; Sound an error.
        lda     #1                              ; Use address $CB now to report back the result code. 1 = error.
        sta     ZP_CB_SAM_STRING_RESULT         ; 
        rts                                     ; Return to caller.

; ----------------------------------------------------------------------------

        ; Three memory blocks of 256 bytes each.
        ; We conjucture that they are filled with garbage in the binary image.

        ; We suspect that D2262 is the binary phoneme buffer.

D2262:  .byte   $24,$07,$13,$34,$14,$01,$FE,$00,$1B,$31,$15,$00,$1C,$30,$15,$1B
        .byte   $00,$06,$26,$00,$20,$08,$1B,$01,$FE,$00,$31,$15,$00,$08,$1B,$00
        .byte   $0A,$00,$00,$20,$36,$37,$38,$05,$2A,$2B,$00,$20,$06,$1C,$23,$0A
        .byte   $20,$31,$15,$26,$0F,$04,$FE,$09,$1C,$00,$0A,$00,$39,$3A,$3B,$06
        .byte   $20,$3F,$40,$41,$01,$FE,$FF,$08,$1B,$00,$0A,$00,$00,$20,$36,$37
        .byte   $38,$05,$2A,$2B,$00,$20,$06,$1C,$23,$0A,$20,$31,$15,$26,$0F,$04
        .byte   $FE,$09,$1C,$00,$0A,$00,$39,$3A,$3B,$06,$20,$3F,$40,$41,$01,$FE
        .byte   $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00

D2362:  .byte   $02,$0B,$09,$0E,$0D,$12,$02,$00,$08,$0F,$08,$00,$07,$0D,$09,$07
        .byte   $00,$0B,$06,$00,$02,$1C,$0B,$12,$02,$00,$0F,$08,$00,$0B,$07,$00
        .byte   $06,$00,$00,$02,$08,$01,$02,$0B,$06,$02,$00,$02,$0C,$07,$02,$06
        .byte   $02,$0C,$09,$06,$11,$08,$02,$13,$07,$00,$06,$00,$07,$01,$01,$0E
        .byte   $02,$0A,$01,$02,$12,$02,$00,$0B,$07,$00,$06,$00,$00,$02,$08,$01
        .byte   $02,$0B,$06,$02,$00,$02,$0C,$07,$02,$06,$02,$0C,$09,$06,$11,$08
        .byte   $02,$13,$07,$00,$06,$00,$07,$01,$01,$0E,$02,$0A,$01,$02,$12,$02
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

D2462:  .byte   $04,$03,$00,$00,$00,$00,$00,$00,$04,$03,$03,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$05,$04,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$05,$05,$05,$04,$00,$00,$00,$05,$04,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$03,$03,$03,$02
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

STRESS:  .byte   "*123456789"          ; Note: stress markers are the characters 1..8.

        ;  *     0    timing
        ; .*     1    inflection
        ; ?*     2    inflection
        ; ,*     3    timing
        ; -*     4    timing
        ; IY     5    vowel
        ; IH     6    vowel
        ; EH     7    vowel
        ; AE     8    vowel
        ; AA     9    vowel
        ; AH    10    vowel
        ; AO    11    vowel
        ; UH    12    vowel
        ; AX    13    vowel
        ; IX    14    vowel
        ; ER    15    vowel
        ; UX    16    vowel
        ; OH    17    vowel
        ; RX    18    internal
        ; LX    19    internal
        ; WX    20    internal
        ; YX    21    internal
        ; WH    22    voiced consonant
        ; R*    23    voiced consonant
        ; L*    24    voiced consonant
        ; W*    25    voiced consonant
        ; Y*    26    voiced consonant
        ; M*    27    voiced consonant
        ; N*    28    voiced consonant
        ; NX    29    voiced consonant
        ; DX    30    internal
        ; Q*    31    special phoneme
        ; S*    32    unvoiced consonant
        ; SH    33    unvoiced consonant
        ; F*    34    unvoiced consonant
        ; TH    35    unvoiced consonant
        ; /H    36    unvoiced consonant
        ; /X    37    internal
        ; Z*    38    voiced consonant
        ; ZH    39    voiced consonant
        ; V*    40    voiced consonant
        ; DH    41    voiced consonant
        ; CH    42    unvoiced consonant
        ; **    43    n/a
        ; J*    44    voiced consonant
        ; **    45
        ; **    46
        ; **    47
        ; EY    48    dipthongs
        ; AY    49    dipthongs
        ; OY    50    dipthongs
        ; AW    51    dipthongs
        ; OW    52    dipthongs
        ; UW    53    dipthongs
        ; B*    54    voiced consonant
        ; **    55
        ; **    56
        ; D*    57    voiced consonant
        ; **    58
        ; **    59
        ; G*    60    voiced consonant
        ; **    61
        ; **    62
        ; GX    63    *** undocumented ***
        ; **    64
        ; **    65
        ; P*    66    unvoiced consonant
        ; **    67
        ; **    68
        ; T*    69    unvoiced consonant
        ; **    70
        ; **    71
        ; K*    72    unvoiced consonant
        ; **    73
        ; **    74
        ; KX    75    *** undocumented ***
        ; **    76
        ; **    77
        ; UL    78    special phoneme
        ; UM    79    special phoneme
        ; UN    80    special phoneme

PHONEMES_1ST:  .byte   " .?,-IIEAAAAUAIEUORLWYWRLWYMNNDQSSFT//ZZVDC*J***EAOAOUB**D**G**G**P**T**K**K**UUU"
PHONEMES_2ND:  .byte   "*****YHHEAHOHXXRXHXXXXH******XX**H*HHX*H*HH*****YYYWWW*********X***********X**LMN"

; ----------------------------------------------------------------------------

D260E:  .byte   $00,$00,$00,$00,$00,$A4,$A4,$A4,$A4,$A4,$A4,$84,$84,$A4,$A4,$84
        .byte   $84,$84,$84,$84,$84,$84,$44,$44,$44,$44,$44,$4C,$4C,$4C,$48,$4C
        .byte   $40,$40,$40,$40,$40,$40,$44,$44,$44,$44,$48,$40,$4C,$44,$00,$00
        .byte   $B4,$B4,$B4,$94,$94,$94,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E
        .byte   $4E,$4E,$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B

D265C:  .byte   $80,$C1,$C1,$C1,$C1,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$10,$10,$10,$10,$08,$0C,$08,$04,$40
        .byte   $24,$20,$20,$24,$00,$00,$24,$20,$20,$24,$20,$20,$00,$20,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$04,$04,$04,$00,$00,$00,$00,$00,$00

; ----------------------------------------------------------------------------

SUB_SAVE_AXY:

        sta     ZP_SAVE_A                       ;
        stx     ZP_SAVE_X                       ;
        sty     ZP_SAVE_Y                       ;
        rts                                     ;

; ----------------------------------------------------------------------------

SUB_RESTORE_AXY:

        lda     ZP_SAVE_A                       ;
        ldx     ZP_SAVE_X                       ;
        ldy     ZP_SAVE_Y                       ;
        rts                                     ;

; ----------------------------------------------------------------------------

SUB_26B8:

        jsr     SUB_SAVE_AXY                    ;
        ldx     #$FF                            ;
        ldy     #0                              ;
@1:     dex                                     ;
        dey                                     ;
        lda     D2262,x                         ;
        sta     D2262,y                         ;
        lda     D2362,x                         ;
        sta     D2362,y                         ;
        lda     D2462,x                         ;
        sta     D2462,y                         ;
        cpx     ZP_F6                           ;
        bne     @1                              ;
        lda     ZP_F9                           ;
        sta     D2262,x                         ;
        lda     ZP_F8                           ;
        sta     D2362,x                         ;
        lda     ZP_F7                           ;
        sta     D2462,x                         ;
        jsr     SUB_RESTORE_AXY                 ;
        rts                                     ;

; ----------------------------------------------------------------------------

SUB_26EA:                                       ; First subroutine called by SAM_SAY_PHONEMES.
                                                ; This translates the SAM phonemes in ASCII to a binary representation.

        ldx     #0                              ; Initialize A, X, Y registers to zero.
        txa                                     ;
        tay                                     ;

        sta     ZP_FF                           ; Set ZP_FF to 0.

@init:  sta     D2462,y                         ; Initialize first 255 bytes of D4262 buffer to zero.
        iny                                     ;
        cpy     #$FF                            ;
        bne     @init                           ;

@next_phoneme:

        lda     SAM_BUFFER,x                    ; Are we seeing the end of the SAM_BUFFER?
        cmp     #$9B                            ;
        beq     @13                             ;

        sta     ZP_FE                           ; Copy 2-byte phoneme to ZP_FE, ZP_FD.
        inx                                     ;
        lda     SAM_BUFFER,x                    ;
        sta     ZP_FD                           ;

        ldy     #0                              ; Search phoneme tables.
@3:     lda     PHONEMES_1ST,y                  ;
        cmp     ZP_FE                           ;
        bne     @4                              ;
        lda     PHONEMES_2ND,y                  ;
        cmp     #'*'                            ;
        beq     @4                              ;
        cmp     ZP_FD                           ;
        beq     @found_phoneme                  ; Found phoneme match.

@4:     iny                                     ;
        cpy     #81                             ; End of ASCII phoneme table?
        bne     @3                              ; Try next phoneme.
        beq     @phoneme_not_found              ; Oops, phoneme not found.

@found_phoneme:

        tya                                     ; Save phoneme into D2262 phoneme byte table.
        ldy     ZP_FF                           ;
        sta     D2262,y                         ;
        inc     ZP_FF                           ;
        inx                                     ;
        jmp     @next_phoneme                   ; Process next phoneme.

@phoneme_not_found:

        ldy     #0                              ;
@7:     lda     PHONEMES_2ND,y                  ;
        cmp     #'*'                            ;
        bne     @8                              ;
        lda     PHONEMES_1ST,y                  ;
        cmp     ZP_FE                           ;
        beq     @9                              ;
@8:     iny                                     ;
        cpy     #81                             ;
        bne     @7                              ;
        beq     @10                             ;

@9:     tya                                     ; Found.
        ldy     ZP_FF                           ;
        sta     D2262,y                         ;
        inc     ZP_FF                           ;
        jmp     @next_phoneme                   ;

@10:    lda     ZP_FE                           ; Not found.
        ldy     #8                              ;
@11:    cmp     STRESS,y                        ;
        beq     @12                             ;
        dey                                     ;
        bne     @11                             ;
        stx     ERROR                           ;
        jsr     SAM_ERROR_SOUND                 ;
        rts                                     ;

@12:    tya                                     ;
        ldy     ZP_FF                           ;
        dey                                     ;
        sta     D2462,y                         ;
        jmp     @next_phoneme                   ;

@13:    lda     #$FF                            ; Set D2262+$FF buffer to $FF.
        ldy     ZP_FF                           ;
        sta     D2262,y                         ;
        rts                                     ;

; ----------------------------------------------------------------------------

SUB_2775:                                       ; Called by SAM_SAY_PHONEMES.

        ldy     #0                              ;
@1:     lda     D2262,y                         ;
        cmp     #$FF                            ;
        beq     @4                              ;
        tax                                     ;
        lda     D2462,y                         ;
        beq     @2                              ;
        bmi     @2                              ;
        lda     D37E0,x                         ;
        sta     D2362,y                         ;
        jmp     @3                              ;

@2:     lda     D3830,x                         ;
        sta     D2362,y                         ;
@3:     iny                                     ;
        jmp     @1                              ;

@4:     rts                                     ;

; ----------------------------------------------------------------------------

SUB_279A:                                       ; Called by SAM_SAY_PHONEMES.

        lda     #0                              ;
        sta     ZP_FF                           ;
@1:     ldx     ZP_FF                           ;
        lda     D2262,x                         ;
        cmp     #$FF                            ;
        bne     @2                              ;
        rts                                     ;

@2:     sta     ZP_F9                           ;
        tay                                     ;
        lda     D260E,y                         ;
        tay                                     ;
        and     #$02                            ;
        bne     @3                              ;
        inc     ZP_FF                           ;
        jmp     @1                              ;

@3:     tya                                     ;
        and     #$01                            ;
        bne     @4                              ;
        inc     ZP_F9                           ;
        ldy     ZP_F9                           ;
        lda     D2462,x                         ;
        sta     ZP_F7                           ;
        lda     D3830,y                         ;
        sta     ZP_F8                           ;
        inx                                     ;
        stx     ZP_F6                           ;
        jsr     SUB_26B8                        ;
        inc     ZP_F9                           ;
        ldy     ZP_F9                           ;
        lda     D3830,y                         ;
        sta     ZP_F8                           ;
        inx                                     ;
        stx     ZP_F6                           ;
        jsr     SUB_26B8                        ;
        inc     ZP_FF                           ;
        inc     ZP_FF                           ;
        inc     ZP_FF                           ;
        jmp     @1                              ;

@4:     inx                                     ;
        lda     D2262,x                         ;
        beq     @4                              ;
        sta     ZP_F5                           ;
        cmp     #$FF                            ;
        bne     @5                              ;
        jmp     @6                              ;

@5:     tay                                     ;
        lda     D260E,y                         ;
        and     #$08                            ;
        bne     @7                              ;
        lda     ZP_F5                           ;
        cmp     #$24                            ;
        beq     @7                              ;
        cmp     #$25                            ;
        beq     @7                              ;
@6:     ldx     ZP_FF                           ;
        lda     D2462,x                         ;
        sta     ZP_F7                           ;
        inx                                     ;
        stx     ZP_F6                           ;
        ldx     ZP_F9                           ;
        inx                                     ;
        stx     ZP_F9                           ;
        lda     D3830,x                         ;
        sta     ZP_F8                           ;
        jsr     SUB_26B8                        ;
        inc     ZP_F6                           ;
        inx                                     ;
        stx     ZP_F9                           ;
        lda     D3830,x                         ;
        sta     ZP_F8                           ;
        jsr     SUB_26B8                        ;
        inc     ZP_FF                           ;
        inc     ZP_FF                           ;
@7:     inc     ZP_FF                           ;
        jmp     @1                              ;

; ----------------------------------------------------------------------------

SUB_2837:                                       ; Called by SAM_SAY_PHONEMES.

        lda     #0                              ;
        sta     ZP_FF                           ;
@1:     ldx     ZP_FF                           ;
        lda     D2262,x                         ;
        bne     @2                              ;
        inc     ZP_FF                           ;
        jmp     @1                              ;

@2:     cmp     #$FF                            ;
        bne     @3                              ;
        rts                                     ;

@3:     tay                                     ;
        lda     D260E,y                         ;
        and     #$10                            ;
        beq     @6                              ;
        lda     D2462,x                         ;
        sta     ZP_F7                           ;
        inx                                     ;
        stx     ZP_F6                           ;
        lda     D260E,y                         ;
        and     #$20                            ;
        beq     @5                              ;
        lda     #$15                            ;
@4:     sta     ZP_F9                           ;
        jsr     SUB_26B8                        ;
        ldx     ZP_FF                           ;
        jmp     @25                             ;

@5:     lda     #$14                            ;
        bne     @4                              ;
@6:     lda     D2262,x                         ;
        cmp     #$4E                            ;
        bne     @8                              ;
        lda     #$18                            ;
@7:     sta     ZP_F9                           ;
        lda     D2462,x                         ;
        sta     ZP_F7                           ;
        lda     #$0D                            ;
        sta     D2262,x                         ;
        inx                                     ;
        stx     ZP_F6                           ;
        jsr     SUB_26B8                        ;
        jmp     @36                             ;

@8:     cmp     #$4F                            ;
        bne     @9                              ;
        lda     #$1B                            ;
        bne     @7                              ;
@9:     cmp     #$50                            ;
        bne     @10                             ;
        lda     #$1C                            ;
        bne     @7                              ;
@10:    tay                                     ;
        lda     D260E,y                         ;
        and     #$80                            ;
        beq     @11                             ;
        lda     D2462,x                         ;
        beq     @11                             ;
        inx                                     ;
        lda     D2262,x                         ;
        bne     @11                             ;
        inx                                     ;
        ldy     D2262,x                         ;
        lda     D260E,y                         ;
        and     #$80                            ;
        beq     @11                             ;
        lda     D2462,x                         ;
        beq     @11                             ;
        stx     ZP_F6                           ;
        lda     #0                              ;
        sta     ZP_F7                           ;
        lda     #$1F                            ;
        sta     ZP_F9                           ;
        jsr     SUB_26B8                        ;
        jmp     @36                             ;

@11:    ldx     ZP_FF                           ;
        lda     D2262,x                         ;
        cmp     #$17                            ;
        bne     @15                             ;
        dex                                     ;
        lda     D2262,x                         ;
        cmp     #$45                            ;
        bne     @12                             ;
        lda     #$2A                            ;
        sta     D2262,x                         ;
        jmp     @27                             ;

@12:    cmp     #$39                            ;
        bne     @13                             ;
        lda     #$2C                            ;
        sta     D2262,x                         ;
        jmp     @29                             ;

@13:    tay                                     ;
        inx                                     ;
        lda     D260E,y                         ;
        and     #$80                            ;
        bne     @14                             ;
        jmp     @36                             ;

@14:    lda     #$12                            ;
        sta     D2262,x                         ;
        jmp     @36                             ;

@15:    cmp     #$18                            ;
        bne     @17                             ;
        dex                                     ;
        ldy     D2262,x                         ;
        inx                                     ;
        lda     D260E,y                         ;
        and     #$80                            ;
        bne     @16                             ;
        jmp     @36                             ;

@16:    lda     #$13                            ;
        sta     D2262,x                         ;
        jmp     @36                             ;

@17:    cmp     #$20                            ;
        bne     @19                             ;
        dex                                     ;
        lda     D2262,x                         ;
        cmp     #$3C                            ;
        beq     @18                             ;
        jmp     @36                             ;

@18:    inx                                     ;
        lda     #$26                            ;
        sta     D2262,x                         ;
        jmp     @36                             ;

@19:    cmp     #$48                            ;
        bne     @21                             ;
        inx                                     ;
        ldy     D2262,x                         ;
        dex                                     ;
        lda     D260E,y                         ;
        and     #$20                            ;
        beq     @20                             ;
        jmp     @23                             ;

@20:    lda     #$4B                            ;
        sta     D2262,x                         ;
        jmp     @23                             ;

@21:    cmp     #$3C                            ;
        bne     @23                             ;
        inx                                     ;
        ldy     D2262,x                         ;
        dex                                     ;
        lda     D260E,y                         ;
        and     #$20                            ;
        beq     @22                             ;
        jmp     @36                             ;

@22:    lda     #$3F                            ;
        sta     D2262,x                         ;
        jmp     @36                             ;

@23:    ldy     D2262,x                         ;
        lda     D260E,y                         ;
        and     #$01                            ;
        beq     @25                             ;
        dex                                     ;
        lda     D2262,x                         ;
        inx                                     ;
        cmp     #$20                            ;
        beq     @24                             ;
        tya                                     ;
        jmp     @31                             ;

@24:    sec                                     ;
        tya                                     ;
        sbc     #$0C                            ;
        sta     D2262,x                         ;
        jmp     @36                             ;

@25:    lda     D2262,x                         ;
        cmp     #$35                            ;
        bne     @27                             ;
        dex                                     ;
        ldy     D2262,x                         ;
        inx                                     ;
        lda     D265C,y                         ;
        and     #$04                            ;
        bne     @26                             ;
        jmp     @36                             ;

@26:    lda     #$10                            ;
        sta     D2262,x                         ;
        jmp     @36                             ;

@27:    cmp     #$2A                            ;
        bne     @29                             ;
@28:    tay                                     ;
        iny                                     ;
        jmp     @30                             ;

@29:    cmp     #$2C                            ;
        beq     @28                             ;
        jmp     @31                             ;

@30:    sty     ZP_F9                           ;
        inx                                     ;
        stx     ZP_F6                           ;
        dex                                     ;
        lda     D2462,x                         ;
        sta     ZP_F7                           ;
        jsr     SUB_26B8                        ;
        jmp     @36                             ;

@31:    cmp     #$45                            ;
        bne     @32                             ;
        beq     @33                             ;
@32:    cmp     #$39                            ;
        beq     @33                             ;
        jmp     @36                             ;

@33:    dex                                     ;
        ldy     D2262,x                         ;
        inx                                     ;
        lda     D260E,y                         ;
        and     #$80                            ;
        beq     @36                             ;
        inx                                     ;
        lda     D2262,x                         ;
        beq     @35                             ;
        tay                                     ;
        lda     D260E,y                         ;
        and     #$80                            ;
        beq     @36                             ;
        lda     D2462,x                         ;
        bne     @36                             ;
@34:    ldx     ZP_FF                           ;
        lda     #$1E                            ;
        sta     D2262,x                         ;
        jmp     @36                             ;

@35:    inx                                     ;
        lda     D2262,x                         ;
        tay                                     ;
        lda     D260E,y                         ;
        and     #$80                            ;
        bne     @34                             ;
@36:    inc     ZP_FF                           ;
        jmp     @1                              ;

; ----------------------------------------------------------------------------

SUB_2A1D:                                       ; Called by SAM_SAY_PHONEMES.

        lda     #0                              ;
        sta     ZP_FF                           ;
@1:     ldx     ZP_FF                           ;
        ldy     D2262,x                         ;
        cpy     #$FF                            ;
        bne     @2                              ;
        rts                                     ;

@2:     lda     D260E,y                         ;
        and     #$40                            ;
        beq     @3                              ;
        inx                                     ;
        ldy     D2262,x                         ;
        lda     D260E,y                         ;
        and     #$80                            ;
        beq     @3                              ;
        ldy     D2462,x                         ;
        beq     @3                              ;
        bmi     @3                              ;
        iny                                     ;
        dex                                     ;
        tya                                     ;
        sta     D2462,x                         ;
@3:     inc     ZP_FF                           ;
        jmp     @1                              ;

; ----------------------------------------------------------------------------

        ; Area for saving 32 zero page values from $E1..$FF.
        ;
        ; The byte values stored here could/should be zero.

D2A4F:  .byte   $00,$82,$09,$00,$00,$00,$EB,$37,$A2,$31,$30,$00,$20,$11,$00,$80
        .byte   $02,$04,$04,$80,$05,$00,$00,$20,$00,$06,$66,$00,$FE,$9B,$2E,$2C

; ----------------------------------------------------------------------------

        ; It seems as if the are from 0x2A6F .. 0x2AD9 is not used (?)

        ; (97 bytes)

D2A6F:  .res 97,0

        ; (10 bytes)

L2AD0:  sta     D2A6F,x                         ; Nobody jumps here.
        dex                                     ; This may just be a garbage code fragment.
        bmi     @1                              ;
        jmp     L2AD0                           ;
@1:     rts                                     ;

; ----------------------------------------------------------------------------

        .byte   "COPYRIGHT 1982 DON'T ASK - ALL RIGHTS "

; ----------------------------------------------------------------------------

D2B00:  .byte   $00,$00,$00,$10,$10,$10,$10,$10,$10,$20,$20,$20,$20,$20,$20,$30
        .byte   $30,$30,$30,$30,$30,$30,$40,$40,$40,$40,$40,$40,$40,$50,$50,$50
        .byte   $50,$50,$50,$50,$50,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
        .byte   $60,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70
        .byte   $70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70
        .byte   $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$50,$50,$50,$50
        .byte   $50,$50,$50,$50,$40,$40,$40,$40,$40,$40,$40,$30,$30,$30,$30,$30
        .byte   $30,$30,$20,$20,$20,$20,$20,$20,$10,$10,$10,$10,$10,$10,$00,$00
        .byte   $00,$00,$00,$F0,$F0,$F0,$F0,$F0,$F0,$E0,$E0,$E0,$E0,$E0,$E0,$D0
        .byte   $D0,$D0,$D0,$D0,$D0,$D0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$B0,$B0,$B0
        .byte   $B0,$B0,$B0,$B0,$B0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90
        .byte   $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$B0,$B0,$B0,$B0
        .byte   $B0,$B0,$B0,$B0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$D0,$D0,$D0,$D0,$D0
        .byte   $D0,$D0,$E0,$E0,$E0,$E0,$E0,$E0,$F0,$F0,$F0,$F0,$F0,$F0,$00,$00

; ----------------------------------------------------------------------------

D2C00:  .byte   $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90
        .byte   $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90
        .byte   $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90
        .byte   $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90
        .byte   $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90
        .byte   $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90
        .byte   $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90
        .byte   $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90
        .byte   $70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70
        .byte   $70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70
        .byte   $70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70
        .byte   $70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70
        .byte   $70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70
        .byte   $70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70
        .byte   $70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70
        .byte   $70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70

; ----------------------------------------------------------------------------

D2D00:  .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$07
        .byte   $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F
        .byte   $00,$01,$03,$04,$06,$07,$09,$0A,$0C,$0D,$0F,$10,$12,$13,$15,$16
        .byte   $00,$02,$04,$06,$08,$0A,$0C,$0E,$10,$12,$14,$16,$18,$1A,$1C,$1E
        .byte   $00,$02,$05,$07,$0A,$0C,$0F,$11,$14,$16,$19,$1B,$1E,$20,$23,$25
        .byte   $00,$03,$06,$09,$0C,$0F,$12,$15,$18,$1B,$1E,$21,$24,$27,$2A,$2D
        .byte   $00,$03,$07,$0A,$0E,$11,$15,$18,$1C,$1F,$23,$26,$2A,$2D,$31,$34
        .byte   $00,$FC,$F8,$F4,$F0,$EC,$E8,$E4,$E0,$DC,$D8,$D4,$D0,$CC,$C8,$C4
        .byte   $00,$FC,$F9,$F5,$F2,$EE,$EB,$E7,$E4,$E0,$DD,$D9,$D6,$D2,$CF,$CB
        .byte   $00,$FD,$FA,$F7,$F4,$F1,$EE,$EB,$E8,$E5,$E2,$DF,$DC,$D9,$D6,$D3
        .byte   $00,$FD,$FB,$F8,$F6,$F3,$F1,$EE,$EC,$E9,$E7,$E4,$E2,$DF,$DD,$DA
        .byte   $00,$FE,$FC,$FA,$F8,$F6,$F4,$F2,$F0,$EE,$EC,$EA,$E8,$E6,$E4,$E2
        .byte   $00,$FE,$FD,$FB,$FA,$F8,$F7,$F5,$F4,$F2,$F1,$EF,$EE,$EC,$EB,$E9
        .byte   $00,$FF,$FE,$FD,$FC,$FB,$FA,$F9,$F8,$F7,$F6,$F5,$F4,$F3,$F2,$F1
        .byte   $00,$FF,$FF,$FE,$FE,$FD,$FD,$FC,$FC,$FB,$FB,$FA,$FA,$F9,$F9,$F8

; ----------------------------------------------------------------------------

D2E00:  .byte   $2C,$2C,$2A,$28,$27,$26,$25,$23,$23,$25,$27,$29,$2B,$2E,$31,$33
        .byte   $35,$38,$38,$39,$3A,$3B,$3C,$3D,$3E,$3E,$3F,$40,$41,$42,$43,$44
        .byte   $45,$46,$48,$49,$4A,$4C,$4D,$4E,$50,$51,$52,$53,$52,$50,$4E,$4D
        .byte   $4A,$47,$46,$43,$41,$40,$3E,$3C,$3B,$39,$37,$37,$37,$37,$37,$37
        .byte   $37,$37,$37,$2D,$2E,$26,$13,$09,$F6,$F5,$F4,$F3,$F2,$F1,$F0,$EF
        .byte   $EF,$EF,$EF,$EF,$EF,$EF,$EF,$EF,$EE,$EF,$F1,$F2,$FE,$13,$1F,$20
        .byte   $22,$22,$22,$22,$22,$22,$0E,$FA,$E6,$D2,$E6,$FA,$0E,$22,$0E,$F0
        .byte   $DC,$BE,$BE,$BE,$BE,$BE,$BE,$BE,$C8,$D2,$DC,$DC,$E6,$F0,$FA,$FA
        .byte   $FA,$FA,$04,$04,$0E,$18,$18,$18,$0E,$04,$FA,$F0,$E6,$E6,$E6,$E6
        .byte   $E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6
        .byte   $E6,$E6,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; ----------------------------------------------------------------------------

        ; The following three tables, 160 bytes each, only seem to have their
        ; first 162 values used.

D2F00:  .byte   $0E,$0E,$10,$13,$13,$13,$13,$13,$13,$13,$13,$13,$12,$12,$11,$10
        .byte   $10,$10,$10,$10,$10,$10,$10,$11,$11,$12,$12,$12,$12,$12,$12,$12
        .byte   $12,$12,$11,$11,$10,$0F,$0F,$0E,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
        .byte   $0E,$10,$11,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13
        .byte   $13,$13,$13,$06,$06,$09,$0C,$0F,$13,$13,$13,$13,$13,$13,$13,$13
        .byte   $13,$13,$13,$13,$13,$13,$13,$13,$0E,$0E,$0E,$0E,$0C,$09,$06,$06
        .byte   $06,$06,$06,$06,$06,$06,$0A,$0E,$12,$17,$13,$0F,$0B,$06,$0B,$10
        .byte   $15,$1B,$1B,$1B,$1B,$1B,$1B,$1A,$18,$17,$15,$14,$12,$11,$0F,$0F
        .byte   $0F,$0E,$0D,$0C,$0B,$09,$09,$09,$0A,$0C,$0E,$10,$12,$12,$12,$12
        .byte   $12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$13,$13,$13,$13
        .byte   $13,$13,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

D3000:  .byte   $49,$49,$46,$43,$43,$43,$43,$43,$43,$43,$43,$3D,$37,$31,$2B,$25
        .byte   $25,$25,$25,$25,$25,$24,$23,$21,$20,$1E,$1E,$1E,$1E,$1E,$1E,$1E
        .byte   $1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D
        .byte   $26,$30,$39,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
        .byte   $43,$43,$43,$54,$54,$50,$4C,$48,$43,$43,$43,$43,$43,$43,$43,$43
        .byte   $43,$43,$43,$43,$43,$43,$43,$43,$49,$49,$49,$49,$43,$3D,$36,$36
        .byte   $36,$36,$39,$3C,$3F,$42,$3D,$37,$32,$2C,$33,$3A,$41,$49,$41,$38
        .byte   $30,$27,$27,$27,$27,$27,$27,$2A,$2E,$32,$36,$39,$3D,$41,$45,$45
        .byte   $45,$42,$3E,$3B,$37,$33,$33,$33,$33,$33,$32,$32,$31,$31,$31,$31
        .byte   $31,$31,$31,$31,$31,$31,$31,$31,$31,$35,$3A,$3E,$43,$43,$43,$43
        .byte   $43,$43,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

D3100:  .byte   $5D,$5D,$5C,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5E,$62,$66,$6A,$6E
        .byte   $6E,$6E,$6E,$6E,$6E,$6A,$66,$61,$5D,$58,$58,$58,$58,$58,$58,$58
        .byte   $58,$57,$56,$55,$54,$53,$52,$51,$50,$50,$50,$50,$50,$50,$50,$50
        .byte   $52,$55,$58,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B
        .byte   $5B,$5B,$5B,$5E,$5E,$5E,$5D,$5C,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B
        .byte   $5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5D,$5D,$5D,$5D,$66,$6F,$79,$79
        .byte   $79,$79,$79,$79,$79,$79,$71,$68,$60,$57,$5A,$5D,$60,$63,$61,$5E
        .byte   $5B,$58,$58,$58,$58,$58,$58,$58,$59,$59,$5A,$5B,$5B,$5C,$5D,$5D
        .byte   $5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$57,$51,$4B,$45,$3E,$3E,$3E,$3E
        .byte   $3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$45,$4C,$53,$5B,$5B,$5B,$5B
        .byte   $5B,$5B,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; ----------------------------------------------------------------------------

        ; D3200 .. D34FF hold 768 samples of four bits each (?)

D3200:  .byte   $00,$00,$04,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0B
        .byte   $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0D,$0D,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0D,$0D,$0D,$0D,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
        .byte   $06,$04,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$00,$02,$02,$02,$0F,$02,$02,$02,$00,$02,$02
        .byte   $02,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

D3300:  .byte   $00,$00,$03,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$09,$08,$06,$05,$04
        .byte   $04,$04,$04,$04,$04,$04,$05,$06,$08,$09,$09,$09,$09,$09,$09,$09
        .byte   $09,$09,$08,$08,$06,$06,$05,$05,$04,$04,$04,$04,$04,$04,$04,$04
        .byte   $03,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$00,$02,$02,$02,$02,$02,$02,$02,$00,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

D3400:  .byte   $00,$00,$02,$04,$04,$04,$04,$04,$04,$04,$04,$04,$03,$02,$02,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00
        .byte   $00,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$00,$00,$00,$01,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; ----------------------------------------------------------------------------

D3500:  .byte   $7C,$7C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$BB,$BB,$00,$00,$00,$00,$00,$00,$F1,$F1,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; ----------------------------------------------------------------------------

D3600:  .byte   $00,$13,$13,$13,$13,$0A,$0E,$13,$18,$1B,$17,$15,$10,$14,$0E,$12
        .byte   $0E,$12,$12,$10,$0D,$0F,$0B,$12,$0E,$0B,$09,$06,$06,$06,$06,$11
        .byte   $06,$06,$06,$06,$0E,$10,$09,$0A,$08,$0A,$06,$06,$06,$05,$06,$00
        .byte   $13,$1B,$15,$1B,$12,$0D,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
        .byte   $06,$06,$06,$06,$06,$06,$06,$06,$06,$0A,$0A,$06,$06,$06,$2C,$13

D3650:  .byte   $00,$43,$43,$43,$43,$54,$49,$43,$3F,$28,$2C,$1F,$25,$2D,$49,$31
        .byte   $24,$1E,$33,$25,$1D,$45,$18,$32,$1E,$18,$53,$2E,$36,$56,$36,$43
        .byte   $49,$4F,$1A,$42,$49,$25,$33,$42,$28,$2F,$4F,$4F,$42,$4F,$6E,$00
        .byte   $48,$27,$1F,$2B,$1E,$22,$1A,$1A,$1A,$42,$42,$42,$6E,$6E,$6E,$54
        .byte   $54,$54,$1A,$1A,$1A,$42,$42,$42,$6D,$56,$6D,$54,$54,$54,$7F,$7F

D36A0:  .byte   $00,$5B,$5B,$5B,$5B,$6E,$5D,$5B,$58,$59,$57,$58,$52,$59,$5D,$3E
        .byte   $52,$58,$3E,$6E,$50,$5D,$5A,$3C,$6E,$5A,$6E,$51,$79,$65,$79,$5B
        .byte   $63,$6A,$51,$79,$5D,$52,$5D,$67,$4C,$5D,$65,$65,$79,$65,$79,$00
        .byte   $5A,$58,$58,$58,$58,$52,$51,$51,$51,$79,$79,$79,$70,$6E,$6E,$5E
        .byte   $5E,$5E,$51,$51,$51,$79,$79,$79,$65,$65,$70,$5E,$5E,$5E,$08,$01

D36F0:  .byte   $00,$00,$00,$00,$00,$0D,$0D,$0E,$0F,$0F,$0F,$0F,$0F,$0C,$0D,$0C
        .byte   $0F,$0F,$0D,$0D,$0D,$0E,$0D,$0C,$0D,$0D,$0D,$0C,$09,$09,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$0B,$0B,$0B,$0B,$00,$00,$01,$0B,$00,$02
        .byte   $0E,$0F,$0F,$0F,$0F,$0D,$02,$04,$00,$02,$04,$00,$01,$04,$00,$01
        .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$00,$00,$00,$00,$0F,$0F

D3740:  .byte   $00,$00,$00,$00,$00,$0A,$0B,$0D,$0E,$0D,$0C,$0C,$0B,$09,$0B,$0B
        .byte   $0C,$0C,$0C,$08,$08,$0C,$08,$0A,$08,$08,$0A,$03,$09,$06,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$03,$05,$03,$04,$00,$00,$00,$05,$0A,$02
        .byte   $0E,$0D,$0C,$0D,$0C,$08,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00
        .byte   $01,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$00,$00,$0A,$00,$00,$00

D3790:  .byte   $00,$00,$00,$00,$00,$08,$07,$08,$08,$01,$01,$00,$01,$00,$07,$05
        .byte   $01,$00,$06,$01,$00,$07,$00,$05,$01,$00,$08,$00,$00,$03,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$0E,$01
        .byte   $09,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$05,$00,$13,$10

D37E0:  .byte   $00,$12,$12,$12,$08,$0B,$09,$0B,$0E,$0F,$0B,$10,$0C,$06,$06,$0E
        .byte   $0C,$0E,$0C,$0B,$08,$08,$0B,$0A,$09,$08,$08,$08,$08,$08,$03,$05
        .byte   $02,$02,$02,$02,$02,$02,$06,$06,$08,$06,$06,$02,$09,$04,$02,$01
        .byte   $0E,$0F,$0F,$0F,$0E,$0E,$08,$02,$02,$07,$02,$01,$07,$02,$02,$07
        .byte   $02,$02,$08,$02,$02,$06,$02,$02,$07,$02,$04,$07,$01,$04,$05,$05

D3830:  .byte   $00,$12,$12,$12,$08,$08,$08,$08,$08,$0B,$06,$0C,$0A,$05,$05,$0B
        .byte   $0A,$0A,$0A,$09,$08,$07,$09,$07,$06,$08,$06,$07,$07,$07,$02,$05
        .byte   $02,$02,$02,$02,$02,$02,$06,$06,$07,$06,$06,$02,$08,$03,$01,$1E
        .byte   $0D,$0C,$0C,$0C,$0E,$09,$06,$01,$02,$05,$01,$01,$06,$01,$02,$06
        .byte   $01,$02,$08,$02,$02,$04,$02,$02,$06,$01,$04,$06,$01,$04,$C7,$FF

D3880:  .byte   $00,$02,$02,$02,$02,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
        .byte   $04,$04,$03,$02,$04,$04,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$02,$02,$02,$01,$00,$01,$00,$01,$00,$05
        .byte   $05,$05,$05,$05,$04,$04,$02,$00,$01,$02,$00,$01,$02,$00,$01,$02
        .byte   $00,$01,$02,$00,$02,$02,$00,$01,$03,$00,$02,$03,$00,$02,$A0,$A0

D38D0:  .byte   $00,$02,$02,$02,$02,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
        .byte   $04,$04,$03,$03,$04,$04,$03,$03,$03,$03,$03,$01,$02,$03,$02,$01
        .byte   $03,$03,$03,$03,$01,$01,$03,$03,$03,$02,$02,$03,$02,$03,$00,$00
        .byte   $05,$05,$05,$05,$04,$04,$02,$00,$02,$02,$00,$03,$02,$00,$04,$02
        .byte   $00,$03,$02,$00,$02,$02,$00,$02,$03,$00,$03,$03,$00,$03,$B0,$A0

D3920:  .byte   $00,$1F,$1F,$1F,$1F,$02,$02,$02,$02,$02,$02,$02,$02,$02,$05,$05
        .byte   $02,$0A,$02,$08,$05,$05,$0B,$0A,$09,$08,$08,$A0,$08,$08,$17,$1F
        .byte   $12,$12,$12,$12,$1E,$1E,$14,$14,$14,$14,$17,$17,$1A,$1A,$1D,$1D
        .byte   $02,$02,$02,$02,$02,$02,$1A,$1D,$1B,$1A,$1D,$1B,$1A,$1D,$1B,$1A
        .byte   $1D,$1B,$17,$1D,$17,$17,$1D,$17,$17,$1D,$17,$17,$1D,$17,$17,$17

D3970:  .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $F1,$E2,$D3,$BB,$7C,$95,$01,$02,$03,$03,$00,$72,$00,$02,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$1B,$00,$00,$19,$00,$00,$00,$00,$00,$00,$00,$00,$00

; ----------------------------------------------------------------------------

        ; Five pages of memory, currently not understood what they are used for.

D39C0:  .byte   $38,$84,$6B,$19,$C6,$63,$18,$86,$73,$98,$C6,$B1,$1C,$CA,$31,$8C
        .byte   $C7,$31,$88,$C2,$30,$98,$46,$31,$18,$C6,$35,$0C,$CA,$31,$0C,$C6
        .byte   $21,$10,$24,$69,$12,$C2,$31,$14,$C4,$71,$08,$4A,$22,$49,$AB,$6A
        .byte   $A8,$AC,$49,$51,$32,$D5,$52,$88,$93,$6C,$94,$22,$15,$54,$D2,$25
        .byte   $96,$D4,$50,$A5,$46,$21,$08,$85,$6B,$18,$C4,$63,$10,$CE,$6B,$18
        .byte   $8C,$71,$19,$8C,$63,$35,$0C,$C6,$33,$99,$CC,$6C,$B5,$4E,$A2,$99
        .byte   $46,$21,$28,$82,$95,$2E,$E3,$30,$9C,$C5,$30,$9C,$A2,$B1,$9C,$67
        .byte   $31,$88,$66,$59,$2C,$53,$18,$84,$67,$50,$CA,$E3,$0A,$AC,$AB,$30
        .byte   $AC,$62,$30,$8C,$63,$10,$94,$62,$B1,$8C,$82,$28,$96,$33,$98,$D6
        .byte   $B5,$4C,$62,$29,$A5,$4A,$B5,$9C,$C6,$31,$14,$D6,$38,$9C,$4B,$B4
        .byte   $86,$65,$18,$AE,$67,$1C,$A6,$63,$19,$96,$23,$19,$84,$13,$08,$A6
        .byte   $52,$AC,$CA,$22,$89,$6E,$AB,$19,$8C,$62,$34,$C4,$62,$19,$86,$63
        .byte   $18,$C4,$23,$58,$D6,$A3,$50,$42,$54,$4A,$AD,$4A,$25,$11,$6B,$64
        .byte   $89,$4A,$63,$39,$8A,$23,$31,$2A,$EA,$A2,$A9,$44,$C5,$12,$CD,$42
        .byte   $34,$8C,$62,$18,$8C,$63,$11,$48,$66,$31,$9D,$44,$33,$1D,$46,$31
        .byte   $9C,$C6,$B1,$0C,$CD,$32,$88,$C4,$73,$18,$86,$73,$08,$D6,$63,$58

        .byte   $07,$81,$E0,$F0,$3C,$07,$87,$90,$3C,$7C,$0F,$C7,$C0,$C0,$F0,$7C
        .byte   $1E,$07,$80,$80,$00,$1C,$78,$70,$F1,$C7,$1F,$C0,$0C,$FE,$1C,$1F
        .byte   $1F,$0E,$0A,$7A,$C0,$71,$F2,$83,$8F,$03,$0F,$0F,$0C,$00,$79,$F8
        .byte   $61,$E0,$43,$0F,$83,$E7,$18,$F9,$C1,$13,$DA,$E9,$63,$8F,$0F,$83
        .byte   $83,$87,$C3,$1F,$3C,$70,$F0,$E1,$E1,$E3,$87,$B8,$71,$0E,$20,$E3
        .byte   $8D,$48,$78,$1C,$93,$87,$30,$E1,$C1,$C1,$E4,$78,$21,$83,$83,$C3
        .byte   $87,$06,$39,$E5,$C3,$87,$07,$0E,$1C,$1C,$70,$F4,$71,$9C,$60,$36
        .byte   $32,$C3,$1E,$3C,$F3,$8F,$0E,$3C,$70,$E3,$C7,$8F,$0F,$0F,$0E,$3C
        .byte   $78,$F0,$E3,$87,$06,$F0,$E3,$07,$C1,$99,$87,$0F,$18,$78,$70,$70
        .byte   $FC,$F3,$10,$B1,$8C,$8C,$31,$7C,$70,$E1,$86,$3C,$64,$6C,$B0,$E1
        .byte   $E3,$0F,$23,$8F,$0F,$1E,$3E,$38,$3C,$38,$7B,$8F,$07,$0E,$3C,$F4
        .byte   $17,$1E,$3C,$78,$F2,$9E,$72,$49,$E3,$25,$36,$38,$58,$39,$E2,$DE
        .byte   $3C,$78,$78,$E1,$C7,$61,$E1,$E1,$B0,$F0,$F0,$C3,$C7,$0E,$38,$C0
        .byte   $F0,$CE,$73,$73,$18,$34,$B0,$E1,$C7,$8E,$1C,$3C,$F8,$38,$F0,$E1
        .byte   $C1,$8B,$86,$8F,$1C,$78,$70,$F0,$78,$AC,$B1,$8F,$39,$31,$DB,$38
        .byte   $61,$C3,$0E,$0E,$38,$78,$73,$17,$1E,$39,$1E,$38,$64,$E1,$F1,$C1

        .byte   $4E,$0F,$40,$A2,$02,$C5,$8F,$81,$A1,$FC,$12,$08,$64,$E0,$3C,$22
        .byte   $E0,$45,$07,$8E,$0C,$32,$90,$F0,$1F,$20,$49,$E0,$F8,$0C,$60,$F0
        .byte   $17,$1A,$41,$AA,$A4,$D0,$8D,$12,$82,$1E,$1E,$03,$F8,$3E,$03,$0C
        .byte   $73,$80,$70,$44,$26,$03,$24,$E1,$3E,$04,$4E,$04,$1C,$C1,$09,$CC
        .byte   $9E,$90,$21,$07,$90,$43,$64,$C0,$0F,$C6,$90,$9C,$C1,$5B,$03,$E2
        .byte   $1D,$81,$E0,$5E,$1D,$03,$84,$B8,$2C,$0F,$80,$B1,$83,$E0,$30,$41
        .byte   $1E,$43,$89,$83,$50,$FC,$24,$2E,$13,$83,$F1,$7C,$4C,$2C,$C9,$0D
        .byte   $83,$B0,$B5,$82,$E4,$E8,$06,$9C,$07,$A0,$99,$1D,$07,$3E,$82,$8F
        .byte   $70,$30,$74,$40,$CA,$10,$E4,$E8,$0F,$92,$14,$3F,$06,$F8,$84,$88
        .byte   $43,$81,$0A,$34,$39,$41,$C6,$E3,$1C,$47,$03,$B0,$B8,$13,$0A,$C2
        .byte   $64,$F8,$18,$F9,$60,$B3,$C0,$65,$20,$60,$A6,$8C,$C3,$81,$20,$30
        .byte   $26,$1E,$1C,$38,$D3,$01,$B0,$26,$40,$F4,$0B,$C3,$42,$1F,$85,$32
        .byte   $26,$60,$40,$C9,$CB,$01,$EC,$11,$28,$40,$FA,$04,$34,$E0,$70,$4C
        .byte   $8C,$1D,$07,$69,$03,$16,$C8,$04,$23,$E8,$C6,$9A,$0B,$1A,$03,$E0
        .byte   $76,$06,$05,$CF,$1E,$BC,$58,$31,$71,$66,$00,$F8,$3F,$04,$FC,$0C
        .byte   $74,$27,$8A,$80,$71,$C2,$3A,$26,$06,$C0,$1F,$05,$0F,$98,$40,$AE

        .byte   $01,$7F,$C0,$07,$FF,$00,$0E,$FE,$00,$03,$DF,$80,$03,$EF,$80,$1B
        .byte   $F1,$C2,$00,$E7,$E0,$18,$FC,$E0,$21,$FC,$80,$3C,$FC,$40,$0E,$7E
        .byte   $00,$3F,$3E,$00,$0F,$FE,$00,$1F,$FF,$00,$3E,$F0,$07,$FC,$00,$7E
        .byte   $10,$3F,$FF,$00,$3F,$38,$0E,$7C,$01,$87,$0C,$FC,$C7,$00,$3E,$04
        .byte   $0F,$3E,$1F,$0F,$0F,$1F,$0F,$02,$83,$87,$CF,$03,$87,$0F,$3F,$C0
        .byte   $07,$9E,$60,$3F,$C0,$03,$FE,$00,$3F,$E0,$77,$E1,$C0,$FE,$E0,$C3
        .byte   $E0,$01,$DF,$F8,$03,$07,$00,$7E,$70,$00,$7C,$38,$18,$FE,$0C,$1E
        .byte   $78,$1C,$7C,$3E,$0E,$1F,$1E,$1E,$3E,$00,$7F,$83,$07,$DB,$87,$83
        .byte   $07,$C7,$07,$10,$71,$FF,$00,$3F,$E2,$01,$E0,$C1,$C3,$E1,$00,$7F
        .byte   $C0,$05,$F0,$20,$F8,$F0,$70,$FE,$78,$79,$F8,$02,$3F,$0C,$8F,$03
        .byte   $0F,$9F,$E0,$C1,$C7,$87,$03,$C3,$C3,$B0,$E1,$E1,$C1,$E3,$E0,$71
        .byte   $F0,$00,$FC,$70,$7C,$0C,$3E,$38,$0E,$1C,$70,$C3,$C7,$03,$81,$C1
        .byte   $C7,$E7,$00,$0F,$C7,$87,$19,$09,$EF,$C4,$33,$E0,$C1,$FC,$F8,$70
        .byte   $F0,$78,$F8,$F0,$61,$C7,$00,$1F,$F8,$01,$7C,$F8,$F0,$78,$70,$3C
        .byte   $7C,$CE,$0E,$21,$83,$CF,$08,$07,$8F,$08,$C1,$87,$8F,$80,$C7,$E3
        .byte   $00,$07,$F8,$E0,$EF,$00,$39,$F7,$80,$0E,$F8,$E1,$E3,$F8,$21,$9F

        .byte   $C0,$FF,$03,$F8,$07,$C0,$1F,$F8,$C4,$04,$FC,$C4,$C1,$BC,$87,$F0
        .byte   $0F,$C0,$7F,$05,$E0,$25,$EC,$C0,$3E,$84,$47,$F0,$8E,$03,$F8,$03
        .byte   $FB,$C0,$19,$F8,$07,$9C,$0C,$17,$F8,$07,$E0,$1F,$A1,$FC,$0F,$FC
        .byte   $01,$F0,$3F,$00,$FE,$03,$F0,$1F,$00,$FD,$00,$FF,$88,$0D,$F9,$01
        .byte   $FF,$00,$70,$07,$C0,$3E,$42,$F3,$0D,$C4,$7F,$80,$FC,$07,$F0,$5E
        .byte   $C0,$3F,$00,$78,$3F,$81,$FF,$01,$F8,$01,$C3,$E8,$0C,$E4,$64,$8F
        .byte   $E4,$0F,$F0,$07,$F0,$C2,$1F,$00,$7F,$C0,$6F,$80,$7E,$03,$F8,$07
        .byte   $F0,$3F,$C0,$78,$0F,$82,$07,$FE,$22,$77,$70,$02,$76,$03,$FE,$00
        .byte   $FE,$67,$00,$7C,$C7,$F1,$8E,$C6,$3B,$E0,$3F,$84,$F3,$19,$D8,$03
        .byte   $99,$FC,$09,$B8,$0F,$F8,$00,$9D,$24,$61,$F9,$0D,$00,$FD,$03,$F0
        .byte   $1F,$90,$3F,$01,$F8,$1F,$D0,$0F,$F8,$37,$01,$F8,$07,$F0,$0F,$C0
        .byte   $3F,$00,$FE,$03,$F8,$0F,$C0,$3F,$00,$FA,$03,$F0,$0F,$80,$FF,$01
        .byte   $B8,$07,$F0,$01,$FC,$01,$BC,$80,$13,$1E,$00,$7F,$E1,$40,$7F,$A0
        .byte   $7F,$B0,$00,$3F,$C0,$1F,$C0,$38,$0F,$F0,$1F,$80,$FF,$01,$FC,$03
        .byte   $F1,$7E,$01,$FE,$01,$F0,$FF,$00,$7F,$C0,$1D,$07,$F0,$0F,$C0,$7E
        .byte   $06,$E0,$07,$E0,$0F,$F8,$06,$C1,$FE,$01,$FC,$03,$E0,$0F,$00,$FC

; ----------------------------------------------------------------------------

        ; Three blocks of 60 bytes each.

D3EC0:  .byte   $24,$07,$13,$34,$14,$01,$FF,$38,$17,$07,$21,$0A,$1C,$1C,$FF,$23
        .byte   $0A,$20,$31,$15,$26,$0F,$04,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

D3EFC:  .byte   $04,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

D3F38:  .byte   $02,$0B,$09,$0E,$0D,$12,$01,$02,$05,$08,$02,$08,$07,$05,$07,$02
        .byte   $06,$02,$0C,$09,$06,$11,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; ----------------------------------------------------------------------------

D3F74_GAIN:  .byte   0,1,2,2,2,3,3,4,4,5,6,8,9,11,13,15 ; 4-bit sample gain curve.

; ----------------------------------------------------------------------------

D3F84:  .byte   $00,$00,$E0,$E6,$EC,$F3,$F9,$00,$06,$0C,$06

; ----------------------------------------------------------------------------

SUB_3F8F:

        ldy     #0                              ;
        bit     ZP_F2                           ;
        bpl     @1                              ;
        sec                                     ;
        lda     #0                              ;
        sbc     ZP_F2                           ;
        sta     ZP_F2                           ;
        ldy     #$80                            ;
@1:     sty     ZP_EF                           ;
        lda     #0                              ;
        ldx     #8                              ;
@2:     asl     ZP_F2                           ;
        rol     a                               ;
        cmp     ZP_F1                           ;
        bcc     @3                              ;
        sbc     ZP_F1                           ;
        inc     ZP_F2                           ;
@3:     dex                                     ;
        bne     @2                              ;
        sta     ZP_F0                           ;
        bit     ZP_EF                           ;
        bpl     @4                              ;
        sec                                     ;
        lda     #0                              ;
        sbc     ZP_F2                           ;
        sta     ZP_F2                           ;
@4:     rts                                     ;

; ----------------------------------------------------------------------------

SAM_SAVE_ZP_ADDRESSES:

        ; Save zero page addresses $E1..$FF.
        ; Note that address $E0 is not saved. (Bug?)

        ldx     #$1F                            ;
@loop:  lda     ZP_E0,x                         ;
        sta     D2A4F,x                         ;
        dex                                     ;
        bne     @loop                           ;
        rts                                     ;

; ----------------------------------------------------------------------------

SAM_RESTORE_ZP_ADDRESSES:

        ; Restore zero page addresses $E1..$FF.
        ; Note that address $E0 is not restored. (Bug?)

        ldx     #$1F                            ;
@loop:  lda     D2A4F,x                         ;
        sta     ZP_E0,x                         ;
        dex                                     ;
        bne     @loop                           ;
        rts                                     ;

; ----------------------------------------------------------------------------

SUB_3FD6:

        lda     D3EC0                           ;
        cmp     #$FF                            ;
        bne     @1                              ;
        rts                                     ;

@1:     lda     #0                              ;
        tax                                     ;
        sta     ZP_E9                           ;
L3FE3:  ldy     ZP_E9                           ;
        lda     D3EC0,y                         ;
        sta     ZP_F5                           ;
        cmp     #$FF                            ;
        bne     @100                            ;
        jmp     L404E                           ;

; ----------------------------------------------------------------------------

@100:   cmp     #1                              ;
        bne     @101                            ;
        jmp     L42F5                           ;

@101:   cmp     #2                              ;
        bne     L3FFF                           ;
        jmp     L42FB                           ;

; ----------------------------------------------------------------------------

L3FFF:  lda     D3EFC,y                         ;
        sta     ZP_E8                           ;
        lda     D3F38,y                         ;
        sta     ZP_E7                           ;
        ldy     ZP_E8                           ;
        iny                                     ;
        lda     D3F84,y                         ;
        sta     ZP_E8                           ;
        ldy     ZP_F5                           ;

L4013:  lda     D3600,y                         ;
        sta     D2F00,x                         ;
        lda     D3650,y                         ;
        sta     D3000,x                         ;
        lda     D36A0,y                         ;
        sta     D3100,x                         ;
        lda     D36F0,y                         ;
        sta     D3200,x                         ;
        lda     D3740,y                         ;
        sta     D3300,x                         ;
        lda     D3790,y                         ;
        sta     D3400,x                         ;
        lda     D3970,y                         ;
        sta     D3500,x                         ;
        clc                                     ;

SMC_PITCH := * + 1                              ; Self-modifying code: argument of lda #imm below.

        lda     #$40                            ;
        adc     ZP_E8                           ;
        sta     D2E00,x                         ;
        inx                                     ;
        dec     ZP_E7                           ;
        bne     L4013                           ;
        inc     ZP_E9                           ;
        bne     L3FE3                           ;
L404E:  lda     #0                              ;
        sta     ZP_E9                           ;
        sta     ZP_EE                           ;
        tax                                     ;
@900:   ldy     D3EC0,x                         ;
        inx                                     ;
        lda     D3EC0,x                         ;
        cmp     #$FF                            ;
        bne     @100                            ;
        jmp     @600                            ;

@100:   tax                                     ;
        lda     D3920,x                         ;
        sta     ZP_F5                           ;
        lda     D3920,y                         ;
        cmp     ZP_F5                           ;
        beq     @102                            ;
        bcc     @101                            ;
        lda     D3880,y                         ;
        sta     ZP_E8                           ;
        lda     D38D0,y                         ;
        sta     ZP_E7                           ;
        jmp     @103                            ;

@101:   lda     D38D0,x                         ;
        sta     ZP_E8                           ;
        lda     D3880,x                         ;
        sta     ZP_E7                           ;
        jmp     @103                            ;

@102:   lda     D3880,y                         ;
        sta     ZP_E8                           ;
        lda     D3880,x                         ;
        sta     ZP_E7                           ;
@103:   clc                                     ;
        lda     ZP_EE                           ;
        ldy     ZP_E9                           ;
        adc     D3F38,y                         ;
        sta     ZP_EE                           ;
        adc     ZP_E7                           ;
        sta     ZP_EA                           ;
        lda     #<D2E00                         ;
        sta     ZP_EB_PTR_LO                    ;
        lda     #>D2E00                         ;
        sta     ZP_EB_PTR_HI                    ;
        sec                                     ;
        lda     ZP_EE                           ;
        sbc     ZP_E8                           ;
        sta     ZP_E6                           ;
        clc                                     ;
        lda     ZP_E8                           ;
        adc     ZP_E7                           ;
        sta     ZP_E3                           ;
        tax                                     ;
        dex                                     ;
        dex                                     ;
        bpl     @150                            ;
        jmp     @500                            ;

@150:   lda     ZP_E3                           ;
        sta     ZP_E5                           ;
        lda     ZP_EB_PTR_HI                    ;
        cmp     #>D2E00                         ;
        bne     @200                            ;
        ldy     ZP_E9                           ;
        lda     D3F38,y                         ;
        lsr     a                               ;
        sta     ZP_E1                           ;
        iny                                     ;
        lda     D3F38,y                         ;
        lsr     a                               ;
        sta     ZP_E2                           ;
        clc                                     ;
        lda     ZP_E1                           ;
        adc     ZP_E2                           ;
        sta     ZP_E5                           ;
        clc                                     ;
        lda     ZP_EE                           ;
        adc     ZP_E2                           ;
        sta     ZP_E2                           ;
        sec                                     ;
        lda     ZP_EE                           ;
        sbc     ZP_E1                           ;
        sta     ZP_E1                           ;
        ldy     ZP_E2                           ;
        lda     (ZP_EB_PTR),y                   ;
        sec                                     ;
        ldy     ZP_E1                           ;
        sbc     (ZP_EB_PTR),y                   ;
        sta     ZP_F2                           ;
        lda     ZP_E5                           ;
        sta     ZP_F1                           ;
        jsr     SUB_3F8F                        ;
        ldx     ZP_E5                           ;
        ldy     ZP_E1                           ;
        jmp     @199                            ;

@200:   ldy     ZP_EA                           ;
        sec                                     ;
        lda     (ZP_EB_PTR),y                   ;
        ldy     ZP_E6                           ;
        sbc     (ZP_EB_PTR),y                   ;
        sta     ZP_F2                           ;
        lda     ZP_E5                           ;
        sta     ZP_F1                           ;
        jsr     SUB_3F8F                        ;
        ldx     ZP_E5                           ;
        ldy     ZP_E6                           ;
@199:   lda     #0                              ;
        sta     ZP_F5                           ;
        clc                                     ;
@399:   lda     (ZP_EB_PTR),y                   ;
        adc     ZP_F2                           ;
        sta     ZP_ED                           ;
        iny                                     ;
        dex                                     ;
        beq     @402                            ;
        clc                                     ;
        lda     ZP_F5                           ;
        adc     ZP_F0                           ;
        sta     ZP_F5                           ;
        cmp     ZP_E5                           ;
        bcc     @401                            ;
        lda     ZP_F5                           ;
        sbc     ZP_E5                           ;
        sta     ZP_F5                           ;
        bit     ZP_EF                           ;
        bmi     @400                            ;
        inc     ZP_ED                           ;
        bne     @401                            ;
@400:   dec     ZP_ED                           ;
@401:   lda     ZP_ED                           ;
        sta     (ZP_EB_PTR),y                   ;
        clc                                     ;
        bcc     @399                            ;
@402:   inc     ZP_EB_PTR_HI                    ;
        lda     ZP_EB_PTR_HI                    ;
        cmp     #>D3500                         ;
        beq     @500                            ;
        jmp     @150                            ;

@500:   inc     ZP_E9                           ;
        ldx     ZP_E9                           ;
        jmp     @900                            ;

@600:   lda     ZP_EE                           ;
        clc                                     ;
        ldy     ZP_E9                           ;
        adc     D3F38,y                         ;
        sta     ZP_ED                           ;
        ldx     #0                              ;
@798:   lda     D2F00,x                         ;
        lsr     a                               ;
        sta     ZP_F5                           ;
        sec                                     ;
        lda     D2E00,x                         ;
        sbc     $F5                             ;
        sta     D2E00,x                         ;
        dex                                     ;
        bne     @798                            ;
        lda     #0                              ;
        sta     ZP_E8                           ;
        sta     ZP_E7                           ;
        sta     ZP_E6                           ;
        sta     ZP_EE                           ;
        lda     #$48                            ;
        sta     ZP_EA                           ;

        ; --- Apply sample gain curve.

        lda     #3                              ; Map 3 pages of values through D374 gain curve (?)
        sta     ZP_F5                           ;

        lda     #<D3200                         ;
        sta     ZP_EB_PTR_LO                    ;
        lda     #>D3200                         ;
        sta     ZP_EB_PTR_HI                    ;

@799:   ldy     #0                              ; Copy a page, applying the sample gain curve.
@800:   lda     (ZP_EB_PTR),y                   ;
        tax                                     ;
        lda     D3F74_GAIN,x                    ;
        sta     (ZP_EB_PTR),y                   ;
        dey                                     ;
        bne     @800                            ;

        inc     ZP_EB_PTR_HI                    ;
        dec     ZP_F5                           ;
        bne     @799                            ;

        ; --- end of: sample gain curve.

        ldy     #0                              ;
        lda     D2E00,y                         ;
        sta     ZP_E9                           ;
        tax                                     ;
        lsr     a                               ;
        lsr     a                               ;
        sta     ZP_F5                           ;
        sec                                     ;
        txa                                     ;
        sbc     ZP_F5                           ;
        sta     ZP_E3                           ;
        jmp     L41CE                           ;

; ----------------------------------------------------------------------------

L41C2:  jsr     SUB_426A                        ;
        iny                                     ;
        iny                                     ;
        dec     ZP_ED                           ;
        dec     ZP_ED                           ;
        jmp     L421B                           ;

; ----------------------------------------------------------------------------

L41CE:  lda     D3500,y                         ;
        sta     ZP_E4                           ;
        and     #$F8                            ;
        bne     L41C2                           ;

        ldx     ZP_E8                           ;
        clc                                     ;
        lda     D2B00,x                         ;
        ora     D3200,y                         ;
        tax                                     ;
        lda     D2D00,x                         ;
        sta     ZP_F5                           ;
        ldx     ZP_E7                           ;
        lda     D2B00,x                         ;
        ora     D3300,y                         ;
        tax                                     ;
        lda     D2D00,x                         ;
        adc     ZP_F5                           ;
        sta     ZP_F5                           ;
        ldx     ZP_E6                           ;
        lda     D2C00,x                         ;
        ora     D3400,y                         ;
        tax                                     ;
        lda     D2D00,x                         ;
        adc     ZP_F5                           ;
        adc     #$88                            ;
        lsr     a                               ;
        lsr     a                               ;
        lsr     a                               ;
        lsr     a                               ;
        ora     #$10                            ;
        sta     AUDC1                           ;

SMC_4210 := * + 1                               ; Self-modifying code: argument of ldx #imm below.

        ldx     #$10                            ;
@100:   dex                                     ;
        bne     @100                            ;
        dec     ZP_EA                           ;
        bne     L4222                           ;
        iny                                     ;
        dec     ZP_ED                           ;
L421B:  bne     L421E                           ;
        rts                                     ;

; ----------------------------------------------------------------------------

L421E:

SMC_SPEED := * + 1                              ; Self-modifying code: argument of lda #imm below.

        lda     #$46                            ;
        sta     ZP_EA                           ;
L4222:  dec     ZP_E9                           ;
        bne     @101                            ;
@100:   lda     D2E00,y                         ;
        sta     ZP_E9                           ;
        tax                                     ;
        lsr     a                               ;
        lsr     a                               ;
        sta     ZP_F5                           ;
        sec                                     ;
        txa                                     ;
        sbc     ZP_F5                           ;
        sta     ZP_E3                           ;
        lda     #0                              ;
        sta     ZP_E8                           ;
        sta     ZP_E7                           ;
        sta     ZP_E6                           ;
        jmp     L41CE                           ;

; ----------------------------------------------------------------------------

@101:   dec     ZP_E3                           ;
        bne     L424F                           ;
        lda     ZP_E4                           ;
        beq     L424F                           ;
        jsr     SUB_426A                        ;
        jmp     @100                            ;

; ----------------------------------------------------------------------------

L424F:  clc                                     ;
        lda     ZP_E8                           ;
        adc     D2F00,y                         ;
        sta     ZP_E8                           ;
        clc                                     ;
        lda     ZP_E7                           ;
        adc     D3000,y                         ;
        sta     ZP_E7                           ;
        clc                                     ;
        lda     ZP_E6                           ;
        adc     D3100,y                         ;
        sta     ZP_E6                           ;
        jmp     L41CE                           ;

; ----------------------------------------------------------------------------

SUB_426A:

        sty     ZP_EE                           ;
        lda     ZP_E4                           ;
        tay                                     ;
        and     #$07                            ;
        tax                                     ;
        dex                                     ;
        stx     ZP_F5                           ;
        lda     D4331,x                         ;
        sta     ZP_F2                           ;
        clc                                     ;
        lda     #>D39C0                         ;
        adc     ZP_F5                           ;
        sta     ZP_EB_PTR_HI                    ;
        lda     #<D39C0                         ;
        sta     ZP_EB_PTR_LO                    ;
        tya                                     ;
        and     #$F8                            ;
        bne     L4296                           ;
        ldy     ZP_EE                           ;
        lda     D2E00,y                         ;
        lsr     a                               ;
        lsr     a                               ;
        lsr     a                               ;
        lsr     a                               ;
        jmp     L42C2                           ;

; ----------------------------------------------------------------------------

L4296:  eor     #$FF                            ;
        tay                                     ;
L4299:  lda     #8                              ;
        sta     ZP_F5                           ;
        lda     (ZP_EB_PTR),y                   ;
L429F:  asl     a                               ;
        bcc     @100                            ;
        ldx     ZP_F2                           ;
        stx     AUDC1                           ;
        bne     @101                            ;
@100:   ldx     #$15                            ;
        stx     AUDC1                           ;
        nop                                     ;
@101:

SMC_42B0 := * + 1                               ; Self-modifying code: argument of ldx #imm below.

        ldx     #13                             ;
@wait:  dex                                     ;
        bne     @wait                           ;
        dec     ZP_F5                           ;
        bne     L429F                           ;
        iny                                     ;
        bne     L4299                           ;
        lda     #1                              ;
        sta     ZP_E9                           ;
        ldy     ZP_EE                           ;
        rts                                     ;

; ----------------------------------------------------------------------------

L42C2:  eor     #$FF                            ;
        sta     ZP_E8                           ;
        ldy     ZP_FF                           ;
L42C8:  lda     #8                              ;
        sta     ZP_F5                           ;
        lda     (ZP_EB_PTR),y                   ;
L42CE:  asl     a                               ;
        bcc     @100                            ;
        ldx     #$1A                            ;
        stx     AUDC1                           ;
        bne     @101                            ;
@100:   ldx     #$16                            ;
        stx     AUDC1                           ;
        nop                                     ;
@101:

SMC_42DF := * + 1                               ; Self-modifying code: argument of ldx #imm below.

        ldx     #12                             ;
@102:   dex                                     ;
        bne     @102                            ;
        dec     ZP_F5                           ;
        bne     L42CE                           ;
        iny                                     ;
        inc     ZP_E8                           ;
        bne     L42C8                           ;
        lda     #1                              ;
        sta     ZP_E9                           ;
        sty     ZP_FF                           ;
        ldy     ZP_EE                           ;
        rts                                     ;

; ----------------------------------------------------------------------------

L42F5:  lda     #1                              ;
        sta     ZP_ED                           ;
        bne     L42FF                           ;

; ----------------------------------------------------------------------------

L42FB:  lda     #$FF                            ;
        sta     ZP_ED                           ;

L42FF:  stx     ZP_EE                           ;
        txa                                     ;
        sec                                     ;
        sbc     #$1E                            ;
        bcs     @1                              ;
        lda     #0                              ;
@1:     tax                                     ;
@2:     lda     D2E00,x                         ;
        cmp     #$7F                            ;
        bne     @3                              ;
        inx                                     ;
        jmp     @2                              ;

@3:     clc                                     ;
        adc     ZP_ED                           ;
        sta     ZP_E8                           ;
        sta     D2E00,x                         ;
@4:     inx                                     ;
        cpx     ZP_EE                           ;
        beq     @5                              ;
        lda     D2E00,x                         ;
        cmp     #$FF                            ;
        beq     @4                              ;
        lda     ZP_E8                           ;
        jmp     @3                              ;

@5:     jmp     L3FFF                           ;

; ----------------------------------------------------------------------------

D4331:  .byte   $18,$1A,$17,$17,$17

; ----------------------------------------------------------------------------

SUB_4336:

        ldx     #$FF                            ;
        stx     ZP_F3                           ;
        inx                                     ;
        stx     ZP_F4                           ;
        stx     ZP_FF                           ;
@1:     ldx     ZP_FF                           ;
        ldy     D2262,x                         ;
        cpy     #$FF                            ;
        bne     @2                              ;
        rts                                     ;

@2:     clc                                     ;
        lda     ZP_F4                           ;
        adc     D2362,x                         ;
        sta     ZP_F4                           ;
        cmp     #$E8                            ;
        bcc     @3                              ;
        jmp     @6                              ;

@3:     lda     D265C,y                         ;
        and     #$01                            ;
        beq     @4                              ;
        inx                                     ;
        stx     ZP_F6                           ;
        lda     #0                              ;
        sta     ZP_F4                           ;
        sta     ZP_F7                           ;
        lda     #$FE                            ;
        sta     ZP_F9                           ;
        jsr     SUB_26B8                        ;
        inc     ZP_FF                           ;
        inc     ZP_FF                           ;
        jmp     @1                              ;

@4:     cpy     #0                              ;
        bne     @5                              ;
        stx     ZP_F3                           ;
@5:     inc     ZP_FF                           ;
        jmp     @1                              ;

@6:     ldx     ZP_F3                           ;
        lda     #$1F                            ;
        sta     D2262,x                         ;
        lda     #4                              ;
        sta     D2362,x                         ;
        lda     #0                              ;
        sta     D2462,x                         ;
        inx                                     ;
        stx     ZP_F6                           ;
        lda     #$FE                            ;
        sta     ZP_F9                           ;
        lda     #0                              ;
        sta     ZP_F4                           ;
        sta     ZP_F7                           ;
        jsr     SUB_26B8                        ;
        inx                                     ;
        stx     ZP_FF                           ;
        jmp     @1                              ;

; ----------------------------------------------------------------------------

        nop                                     ; 0xea (probably not used).

; ----------------------------------------------------------------------------

D43A9:  .byte   $07                             ;

; ----------------------------------------------------------------------------

SUB_43AA:

        lda     #0                              ;
        tax                                     ;
        tay                                     ;
@1:     lda     D2262,x                         ;
        cmp     #$FF                            ;
        bne     @2                              ;
        lda     #$FF                            ; Handle case: $FF
        sta     D3EC0,y                         ;
        jsr     SUB_3FD6                        ;
        rts                                     ;

@2:     cmp     #$FE                            ;
        bne     @3                              ;
        inx                                     ; Handle case: $FE
        stx     D43A9                           ;
        lda     #$FF                            ;
        sta     D3EC0,y                         ;
        jsr     SUB_3FD6                        ;
        ldx     D43A9                           ;
        ldy     #0                              ;
        jmp     @1                              ;

@3:     cmp     #0                              ;
        bne     @4                              ;
        inx                                     ; Handle case: 0
        jmp     @1                              ;

@4:     sta     D3EC0,y                         ; Handle al other cases.
        lda     D2362,x                         ;
        sta     D3F38,y                         ;
        lda     D2462,x                         ;
        sta     D3EFC,y                         ;
        inx                                     ;
        iny                                     ;
        jmp     @1                              ;

; ----------------------------------------------------------------------------

SUB_43F2:                                       ; Called by SAM_SAY_PHONEMES.

        ldx     #0                              ;
@1:     ldy     D2262,x                         ;
        cpy     #$FF                            ;
        bne     @3                              ;
@2:     jmp     @9                              ;

@3:     lda     D265C,y                         ;
        and     #$01                            ;
        bne     @4                              ;
        inx                                     ;
        jmp     @1                              ;

@4:     stx     ZP_FF                           ;
@5:     dex                                     ;
        beq     @2                              ;
        ldy     D2262,x                         ;
        lda     D260E,y                         ;
        and     #$80                            ;
        beq     @5                              ;
@6:     ldy     D2262,x                         ;
        lda     D265C,y                         ;
        and     #$20                            ;
        beq     @7                              ;
        lda     D260E,y                         ;
        and     #$04                            ;
        beq     @8                              ;
@7:     lda     D2362,x                         ;
        sta     ZP_F5                           ;
        lsr     a                               ;
        clc                                     ;
        adc     $F5                             ;
        adc     #1                              ;
        sta     D2362,x                         ;
@8:     inx                                     ;
        cpx     ZP_FF                           ;
        bne     @6                              ;
        inx                                     ;
        jmp     @1                              ;

@9:     ldx     #0                              ;
        stx     ZP_FF                           ;

@10:    ldx     ZP_FF                           ;
        ldy     D2262,x                         ;
        cpy     #$FF                            ;
        bne     @11                             ;
        rts                                     ;

@11:    lda     D260E,y                         ;
        and     #$80                            ;
        bne     @12                             ;
        jmp     @18                             ;

@12:    inx                                     ;
        ldy     D2262,x                         ;
        lda     D260E,y                         ;
        sta     ZP_F5                           ;
        and     #$40                            ;
        beq     @15                             ;
        lda     ZP_F5                           ;
        and     #$04                            ;
        beq     @14                             ;
        dex                                     ;
        lda     D2362,x                         ;
        sta     ZP_F5                           ;
        lsr     a                               ;
        lsr     a                               ;
        clc                                     ;
        adc     ZP_F5                           ;
        adc     #1                              ;
        sta     D2362,x                         ;
@13:    jmp     @25                             ;

@14:    lda     ZP_F5                           ;
        and     #$01                            ;
        beq     @13                             ;
        dex                                     ;
        lda     D2362,x                         ;
        tay                                     ;
        lsr     a                               ;
        lsr     a                               ;
        lsr     a                               ;
        sta     ZP_F5                           ;
        sec                                     ;
        tya                                     ;
        sbc     ZP_F5                           ;
        sta     D2362,x                         ;
        jmp     @25                             ;

@15:    cpy     #$12                            ;
        beq     @17                             ;
        cpy     #$13                            ;
        beq     @17                             ;
@16:    jmp     @25                             ;

@17:    inx                                     ;
        ldy     D2262,x                         ;
        lda     D260E,y                         ;
        and     #$40                            ;
        beq     @16                             ;
        ldx     ZP_FF                           ;
        lda     D2362,x                         ;
        sec                                     ;
        sbc     #1                              ;
        sta     D2362,x                         ;
        jmp     @25                             ;

@18:    lda     D265C,y                         ;
        and     #$08                            ;
        beq     @21                             ;
        inx                                     ;
        ldy     D2262,x                         ;
        lda     D260E,y                         ;
        and     #$02                            ;
        bne     @20                             ;
@19:    jmp     @25                             ;

@20:    lda     #6                              ;
        sta     D2362,x                         ;
        dex                                     ;
        lda     #5                              ;
        sta     D2362,x                         ;
        jmp     @25                             ;

@21:    lda     D260E,y                         ;
        and     #$02                            ;
        beq     @24                             ;
@22:    inx                                     ;
        ldy     D2262,x                         ;
        beq     @22                             ;
        lda     D260E,y                         ;
        and     #$02                            ;
        beq     @19                             ;
        lda     D2362,x                         ;
        lsr     a                               ;
        clc                                     ;
        adc     #1                              ;
        sta     D2362,x                         ;
        ldx     ZP_FF                           ;
        lda     D2362,x                         ;
        lsr     a                               ;
        clc                                     ;
        adc     #1                              ;
        sta     D2362,x                         ;
@23:    jmp     @25                             ;

@24:    lda     D265C,y                         ;
        and     #$10                            ;
        beq     @23                             ;
        dex                                     ;
        ldy     D2262,x                         ;
        lda     D260E,y                         ;
        and     #$02                            ;
        beq     @23                             ;
        inx                                     ;
        lda     D2362,x                         ;
        sec                                     ;
        sbc     #2                              ;
        sta     D2362,x                         ;
@25:    inc     ZP_FF                           ;
        jmp     @10                             ;

; ----------------------------------------------------------------------------

SAM_ERROR_SOUND:

        ; Make error noise.

        lda     #2                              ;
        sta     ZP_CC_TEMP                      ;
@1:     lda     RTCLOK+2                        ; Load LSB of VBLANK counter.
        clc                                     ;
        adc     #8                              ;
        tax                                     ;
@2:     lda     #$FF                            ;
        sta     CONSOL                          ;
        lda     #0                              ;
        ldy     #$F0                            ;
@3:     dey                                     ;
        bne     @3                              ;
        sta     CONSOL                          ;
        ldy     #$F0                            ;
@4:     dey                                     ;
        bne     @4                              ;
        cpx     RTCLOK+2                        ; Compare to LSB of VBLANK counter.
        bne     @2                              ;
        dec     ZP_CC_TEMP                      ;
        beq     @6                              ;
        txa                                     ;
        clc                                     ;
        adc     #5                              ;
        tax                                     ;
@5:     cpx     RTCLOK+2                        ; Compare to LSB of VBLANK counter.
        bne     @5                              ;
        jmp     @1                              ;

@6:     rts                                     ;

; ----------------------------------------------------------------------------

        ; The data below (38 bytes) is probably garbage.

        .byte   $A9
        .res    37,0

; ----------------------------------------------------------------------------

        ; The "MEMLO" variable is reset to here.
        ; The data below (10 bytes) is probably garbage.

D4586:  .byte $00,$00,$42,$01,$78,$03,$00,$00,$00,$00

; ----------------------------------------------------------------------------

D4590:  ; This is where the reciter executable image starts.
        ; The data below (193 bytes) is probably garbage.

        .byte   $41,$81,$92,$00,$00,$00,$30,$2E,$30,$16,$00
        .byte   $00,$14,$27,$2A,$1C,$0E,$40,$01,$00,$00,$00
        .byte   $00,$12,$46,$3A,$80,$2C,$14,$2B,$09,$80,$16

        .res 160, 0

; ----------------------------------------------------------------------------

        .segment "SAM_BLOCK2_HEADER"

        ; This is the Atari executable header for the second block.

        .word   __SAM_BLOCK2_LOAD__
        .word   __SAM_BLOCK2_LOAD__ + __SAM_BLOCK2_SIZE__ - 1

        .segment  "SAM_BLOCK2"

_start: lda     #<D4586                         ;
        sta     MEMLO                           ;
        sta     $864                            ;
        lda     #>D4586                         ;
        sta     MEMLO+1                         ;
        sta     $869                            ;
        lda     #0                              ;
        sta     WARMST                          ;
        jmp     BASIC                           ; Jump into BASIC.

        .res 11, 0                              ; Trailing nonsense.

; ----------------------------------------------------------------------------

        .segment "SAM_BLOCK3_HEADER"

        ; This is the Atari executable header for the third block in the executable file.
        ; It points to the INITAD pointer used by DOS as the initialization address for executable files.

        .word   __SAM_BLOCK3_LOAD__
        .word   __SAM_BLOCK3_LOAD__ + __SAM_BLOCK3_SIZE__ - 1

        .segment "SAM_BLOCK3"

        ; The content of the second block is just the initialization address of the code.

        .word _start ; 0x24de
