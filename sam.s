
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
ZP_FA := $FA                                    ;
ZP_FB := $FB                                    ;
ZP_FC := $FC                                    ;
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

        ; When we get here, it is expected that SAM_SAVE_ZP_ADDRESSES has been called
        ; previously to save addresses $E1..$FF.

SAM_SAY_PHONEMES:                               ; Render phonemes in SAM_BUFFER as sound.

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

        lda     #0                              ; Init hardware.
        sta     NMIEN                           ; Disable NMI interrupts.
        sta     IRQEN                           ; Disable IRQ interrupts.

        lda     LIGHTS                          ; Select mode #0 (normal) or mode #1 (debug?)
        beq     @lights_off                     ;

        lda     #1                              ; Lights on: Initialize self-modifying code values.
        sta     SMC42DF                         ;
        sta     SMC4210                         ;
        sta     SMC42B0                         ;
        lda     PITCH_L1                        ;
        sta     SMC_PITCH                       ;
        lda     SPEED_L1                        ;
        sta     SMC_SPEED                       ;
        jmp     @join                           ;

@lights_off:

        lda     #0                              ; Initialize lights off (default) mode.
        sta     DMACTL                          ; Disable DMA (Antic)
        lda     #16                             ; Initialize self-modifying code values.
        sta     SMC4210                         ;
        lda     #13                             ;
        sta     SMC42B0                         ;
        lda     #12                             ;
        sta     SMC42DF                         ;
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
        lda     #$FF                            ;
        sta     D2360                           ;
        jsr     SUB_43AA                        ;

        ldx     #0                              ; All done. Should we restore the DMA and interrupt state?
        cpx     SAM_ZP_CD                       ;
        stx     SAM_ZP_CD                       ;
        beq     @5                              ;
        rts                                     ;

@5:     jsr     SAM_RESTORE_ZP_ADDRESSES        ; Restore zero page addresses.
        lda     #$FF                            ;
        sta     NMIEN                           ; Enable NMI interrupts.
        lda     POKMSK                          ; Load shadow IRQ enabled mask.
        sta     IRQEN                           ; Restore IRQ interrupts.
        rts                                     ;

; ----------------------------------------------------------------------------

SAM_COPY_BASIC_SAM_STRING:

        ; This subroutine searches the BASIC string variable named "SAM$", and copies its contents
        ; into the SAM_BUFFER.
        ;
        ; This routine is called as the first thing when SAM is called directly from BASIC.
        ; It is also called from the RECITER.
        ;
        ; Note that the code matches any BASIC string the name of which ends with "SAM$",
        ;   which is probably not intentional.
        ;
        ; If found, it copies the string's content into SAM_BUFFER.

        lda     #0                              ; Initialize ZP_CB_PTR and ZP_CD to zero.
        sta     ZP_CB_PTR_LO                    ; ZP_CB_PTR holds the variable index.
        sta     ZP_CB_PTR_HI                    ;
        sta     SAM_ZP_CD                       ;

        lda     VNTP                            ; Copy variable name table pointer VNTP to ZP_CE_PTR.
        sta     ZP_CE_PTR_LO                    ;
        lda     VNTP+1                          ;
        sta     ZP_CE_PTR_HI                    ;

        lda     STARP                           ; Copy string and array pointer STARP to ZP_D0_PTR.
        sta     ZP_D0_PTR_LO                    ;
        lda     STARP+1                         ;
        sta     ZP_D0_PTR_HI                    ;

@check_variable:

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
        cmp     #'$' + $80                      ;
        bne     @not_found_here                 ;
        jmp     @found_sam_string_variable      ; If found, proceed to @found_sam_string_variable.

@not_found_here:

        lda     ZP_CE_PTR_LO                    ; Check if pointer ($CE, $CF) is identical to ($84, $85), which
        cmp     VNTD                            ; is the end of BASIC variable memory.
        bne     @continue_search                ;
        lda     ZP_CE_PTR_HI                    ; If not equal, proceed at @3.
        cmp     VNTD+1                          ; If equal, we've reached the end of the BASIC program; go to @end.
        beq     @report_error                   ; Variable not found.

@continue_search:

        ldy     #0                              ;
        lda     (ZP_CE_PTR),y                   ;
        bpl     @4                              ;
        inc     ZP_CB_PTR_LO                    ; Increment variable index whenever we pass through a character with its most significant bit set.
@4:     inc     ZP_CE_PTR_LO                    ; Increment ZP_CE_PTR.
        bne     @5                              ;
        inc     ZP_CE_PTR_HI                    ;
@5:     jmp     @check_variable                 ; Proceed to check the next variable.

@found_sam_string_variable:

        clc                                     ; Multiply ZP_CB_PTR by 8.
        asl     ZP_CB_PTR_LO                    ;
        rol     ZP_CB_PTR_HI                    ;
        asl     ZP_CB_PTR_LO                    ;
        rol     ZP_CB_PTR_HI                    ;
        asl     ZP_CB_PTR_LO                    ;
        rol     ZP_CB_PTR_HI                    ;

        clc                                     ; Make ZP_CB_PTR an address into the Atari Basic varianble value table.
        lda     ZP_CB_PTR_LO                    ;
        adc     VVTP                            ;
        sta     ZP_CB_PTR_LO                    ;
        lda     ZP_CB_PTR_HI                    ;
        adc     VVTP+1                          ;
        sta     ZP_CB_PTR_HI                    ;

        ldy     #5                              ; If size of string exceeds 255, report error.
        lda     (ZP_CB_PTR),y                   ;
        bne     @report_error                   ;
        dey                                     ; Copy string size into SAM_ZP_CD.
        lda     (ZP_CB_PTR),y                   ;
        sta     SAM_ZP_CD                       ;

        ldy     #2                              ; Prepare ZP_D0_PTR to point at the beginning of the content of SAM$.
        lda     (ZP_CB_PTR),y                   ;
        clc                                     ;
        adc     ZP_D0_PTR_LO                    ;
        sta     ZP_D0_PTR_LO                    ;
        ldy     #3                              ;
        lda     (ZP_CB_PTR),y                   ;
        adc     ZP_D0_PTR_HI                    ;
        sta     ZP_D0_PTR_HI                    ;

        ldy     #0                              ; Copy content of SAM$ into SAM_BUFFER.
@copy:  lda     (ZP_D0_PTR),y                   ;
        sta     SAM_BUFFER,y                    ;
        iny                                     ;
        cpy     SAM_ZP_CD                       ; Equal to string size?
        bne     @copy                           ;

        lda     #$9B                            ; Append closing $9B character.
        sta     SAM_BUFFER,y                    ;

        lda     #0                              ;
        sta     ZP_CB_SAM_STRING_RESULT         ; Use address $CB now to report back the result code. Report success.
        sta     SAM_ZP_CD                       ; Set $CD to zero.

        rts                                     ; Return succesfully.

@report_error:

        jsr     SAM_ERROR_SOUND                 ; Sound an error.
        lda     #1                              ;
        sta     ZP_CB_SAM_STRING_RESULT         ; Use address $CB now to report back the result code. Report error.
        rts                                     ; Done.

; ----------------------------------------------------------------------------

D2262:  .byte   $24,$07,$13,$34,$14,$01,$FE,$00 ; 2262 24 07 13 34 14 01 FE 00  $..4....
        .byte   $1B,$31,$15,$00,$1C,$30,$15,$1B ; 226A 1B 31 15 00 1C 30 15 1B  .1...0..
        .byte   $00,$06,$26,$00,$20,$08,$1B,$01 ; 2272 00 06 26 00 20 08 1B 01  ..&. ...
        .byte   $FE,$00,$31,$15,$00,$08,$1B,$00 ; 227A FE 00 31 15 00 08 1B 00  ..1.....
        .byte   $0A,$00,$00,$20,$36,$37,$38,$05 ; 2282 0A 00 00 20 36 37 38 05  ... 678.
        .byte   $2A,$2B,$00,$20,$06,$1C,$23,$0A ; 228A 2A 2B 00 20 06 1C 23 0A  *+. ..#.
        .byte   $20,$31,$15,$26,$0F,$04,$FE,$09 ; 2292 20 31 15 26 0F 04 FE 09   1.&....
        .byte   $1C,$00,$0A,$00,$39,$3A,$3B,$06 ; 229A 1C 00 0A 00 39 3A 3B 06  ....9:;.
        .byte   $20,$3F,$40,$41,$01,$FE,$FF,$08 ; 22A2 20 3F 40 41 01 FE FF 08   ?@A....
        .byte   $1B,$00,$0A,$00,$00,$20,$36,$37 ; 22AA 1B 00 0A 00 00 20 36 37  ..... 67
        .byte   $38,$05,$2A,$2B,$00,$20,$06,$1C ; 22B2 38 05 2A 2B 00 20 06 1C  8.*+. ..
        .byte   $23,$0A,$20,$31,$15,$26,$0F,$04 ; 22BA 23 0A 20 31 15 26 0F 04  #. 1.&..
        .byte   $FE,$09,$1C,$00,$0A,$00,$39,$3A ; 22C2 FE 09 1C 00 0A 00 39 3A  ......9:
        .byte   $3B,$06,$20,$3F,$40,$41,$01,$FE ; 22CA 3B 06 20 3F 40 41 01 FE  ;. ?@A..
        .byte   $FF,$00,$00,$00,$00,$00,$00,$00 ; 22D2 FF 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 22DA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 22E2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 22EA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 22F2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 22FA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2302 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 230A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2312 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 231A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2322 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 232A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2332 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 233A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2342 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 234A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2352 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00         ; 235A 00 00 00 00 00 00        ......
D2360:  .byte   $FF,$00                         ; 2360 FF 00                    ..

D2362:  .byte   $02,$0B,$09,$0E,$0D,$12,$02,$00 ; 2362 02 0B 09 0E 0D 12 02 00  ........
        .byte   $08,$0F,$08,$00,$07,$0D,$09,$07 ; 236A 08 0F 08 00 07 0D 09 07  ........
        .byte   $00,$0B,$06,$00,$02,$1C,$0B,$12 ; 2372 00 0B 06 00 02 1C 0B 12  ........
        .byte   $02,$00,$0F,$08,$00,$0B,$07,$00 ; 237A 02 00 0F 08 00 0B 07 00  ........
        .byte   $06,$00,$00,$02,$08,$01,$02,$0B ; 2382 06 00 00 02 08 01 02 0B  ........
        .byte   $06,$02,$00,$02,$0C,$07,$02,$06 ; 238A 06 02 00 02 0C 07 02 06  ........
        .byte   $02,$0C,$09,$06,$11,$08,$02,$13 ; 2392 02 0C 09 06 11 08 02 13  ........
        .byte   $07,$00,$06,$00,$07,$01,$01,$0E ; 239A 07 00 06 00 07 01 01 0E  ........
        .byte   $02,$0A,$01,$02,$12,$02,$00,$0B ; 23A2 02 0A 01 02 12 02 00 0B  ........
        .byte   $07,$00,$06,$00,$00,$02,$08,$01 ; 23AA 07 00 06 00 00 02 08 01  ........
        .byte   $02,$0B,$06,$02,$00,$02,$0C,$07 ; 23B2 02 0B 06 02 00 02 0C 07  ........
        .byte   $02,$06,$02,$0C,$09,$06,$11,$08 ; 23BA 02 06 02 0C 09 06 11 08  ........
        .byte   $02,$13,$07,$00,$06,$00,$07,$01 ; 23C2 02 13 07 00 06 00 07 01  ........
        .byte   $01,$0E,$02,$0A,$01,$02,$12,$02 ; 23CA 01 0E 02 0A 01 02 12 02  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 23D2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 23DA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 23E2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 23EA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 23F2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 23FA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2402 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 240A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2412 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 241A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2422 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 242A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2432 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 243A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2442 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 244A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2452 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 245A 00 00 00 00 00 00 00 00  ........

D2462:  .byte   $04,$03,$00,$00,$00,$00,$00,$00 ; 2462 04 03 00 00 00 00 00 00  ........
        .byte   $04,$03,$03,$00,$00,$00,$00,$00 ; 246A 04 03 03 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$05,$04,$00,$00 ; 2472 00 00 00 00 05 04 00 00  ........
        .byte   $00,$00,$03,$03,$00,$00,$00,$00 ; 247A 00 00 03 03 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$05,$05,$05,$04 ; 2482 00 00 00 00 05 05 05 04  ........
        .byte   $00,$00,$00,$05,$04,$00,$00,$00 ; 248A 00 00 00 05 04 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$05 ; 2492 00 00 00 00 00 00 00 05  ........
        .byte   $00,$00,$00,$00,$03,$03,$03,$02 ; 249A 00 00 00 00 03 03 03 02  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24A2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24AA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24B2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24BA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24C2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24CA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24D2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24DA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24E2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24EA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24F2 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 24FA 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2502 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 250A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2512 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 251A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2522 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 252A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2532 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 253A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2542 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 254A 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2552 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 255A 00 00 00 00 00 00 00 00  ........

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

D260E:  .byte   $00,$00,$00,$00,$00,$A4,$A4,$A4 ; 260E 00 00 00 00 00 A4 A4 A4  ........
        .byte   $A4,$A4,$A4,$84,$84,$A4,$A4,$84 ; 2616 A4 A4 A4 84 84 A4 A4 84  ........
        .byte   $84,$84,$84,$84,$84,$84,$44,$44 ; 261E 84 84 84 84 84 84 44 44  ......DD
        .byte   $44,$44,$44,$4C,$4C,$4C,$48,$4C ; 2626 44 44 44 4C 4C 4C 48 4C  DDDLLLHL
        .byte   $40,$40,$40,$40,$40,$40,$44,$44 ; 262E 40 40 40 40 40 40 44 44  @@@@@@DD
        .byte   $44,$44,$48,$40,$4C,$44,$00,$00 ; 2636 44 44 48 40 4C 44 00 00  DDH@LD..
        .byte   $B4,$B4,$B4,$94,$94,$94,$4E,$4E ; 263E B4 B4 B4 94 94 94 4E 4E  ......NN
        .byte   $4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E ; 2646 4E 4E 4E 4E 4E 4E 4E 4E  NNNNNNNN
        .byte   $4E,$4E,$4B,$4B,$4B,$4B,$4B,$4B ; 264E 4E 4E 4B 4B 4B 4B 4B 4B  NNKKKKKK
        .byte   $4B,$4B,$4B,$4B,$4B,$4B         ; 2656 4B 4B 4B 4B 4B 4B        KKKKKK
D265C:  .byte   $80,$C1,$C1,$C1,$C1,$00,$00,$00 ; 265C 80 C1 C1 C1 C1 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2664 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$10 ; 266C 00 00 00 00 00 00 00 10  ........
        .byte   $10,$10,$10,$08,$0C,$08,$04,$40 ; 2674 10 10 10 08 0C 08 04 40  .......@
        .byte   $24,$20,$20,$24,$00,$00,$24,$20 ; 267C 24 20 20 24 00 00 24 20  $  $..$ 
        .byte   $20,$24,$20,$20,$00,$20,$00,$00 ; 2684 20 24 20 20 00 20 00 00   $  . ..
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 268C 00 00 00 00 00 00 00 00  ........
        .byte   $00,$04,$04,$04,$00,$00,$00,$00 ; 2694 00 04 04 04 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$04,$04,$04 ; 269C 00 00 00 00 00 04 04 04  ........
        .byte   $00,$00,$00,$00,$00,$00         ; 26A4 00 00 00 00 00 00        ......

; ----------------------------------------------------------------------------

SUB_26AA:

        sta     ZP_FC                           ;
        stx     ZP_FB                           ;
        sty     ZP_FA                           ;
        rts                                     ;

; ----------------------------------------------------------------------------

SUB_26B1:

        lda     ZP_FC                           ;
        ldx     ZP_FB                           ;
        ldy     ZP_FA                           ;
        rts                                     ;

; ----------------------------------------------------------------------------

SUB_26B8:

        jsr     SUB_26AA                        ;
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
        jsr     SUB_26B1                        ;
        rts                                     ;

; ----------------------------------------------------------------------------

SUB_26EA:                                       ; First subroutine called by SAM_SAY_PHONEMES.

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

        sta     ZP_FE                           ; Copy 2-byte phoneme to ZP_FE,ZP_FD.
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

        ; Area for saving zero page values from $E1..$FF.

D2A4F:  .byte   $00,$82,$09,$00,$00,$00,$EB,$37
        .byte   $A2,$31,$30,$00,$20,$11,$00,$80
        .byte   $02,$04,$04,$80,$05,$00,$00,$20
        .byte   $00,$06,$66,$00,$FE,$9B,$2E,$2C

; ----------------------------------------------------------------------------

D2A6F:  .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2A6F 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2A77 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2A7F 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2A87 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2A8F 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2A97 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2A9F 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2AA7 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2AAF 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2AB7 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2ABF 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2AC7 00 00 00 00 00 00 00 00  ........
        .byte   $00                             ; 2ACF 00                       .

; ----------------------------------------------------------------------------

L2AD0:  sta     D2A6F,x                         ;
        dex                                     ;
        bmi     @1                              ;
        jmp     L2AD0                           ;

@1:     rts                                     ;

; ----------------------------------------------------------------------------

        .byte   "COPYRIGHT 1982 DON'T ASK - ALL RIGHTS "

; ----------------------------------------------------------------------------

D2B00:  .byte   $00,$00,$00,$10,$10,$10,$10,$10 ; 2B00 00 00 00 10 10 10 10 10  ........
        .byte   $10,$20,$20,$20,$20,$20,$20,$30 ; 2B08 10 20 20 20 20 20 20 30  .      0
        .byte   $30,$30,$30,$30,$30,$30,$40,$40 ; 2B10 30 30 30 30 30 30 40 40  000000@@
        .byte   $40,$40,$40,$40,$40,$50,$50,$50 ; 2B18 40 40 40 40 40 50 50 50  @@@@@PPP
        .byte   $50,$50,$50,$50,$50,$60,$60,$60 ; 2B20 50 50 50 50 50 60 60 60  PPPPP```
        .byte   $60,$60,$60,$60,$60,$60,$60,$60 ; 2B28 60 60 60 60 60 60 60 60  ````````
        .byte   $60,$70,$70,$70,$70,$70,$70,$70 ; 2B30 60 70 70 70 70 70 70 70  `ppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2B38 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2B40 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2B48 70 70 70 70 70 70 70 70  pppppppp
        .byte   $60,$60,$60,$60,$60,$60,$60,$60 ; 2B50 60 60 60 60 60 60 60 60  ````````
        .byte   $60,$60,$60,$60,$50,$50,$50,$50 ; 2B58 60 60 60 60 50 50 50 50  ````PPPP
        .byte   $50,$50,$50,$50,$40,$40,$40,$40 ; 2B60 50 50 50 50 40 40 40 40  PPPP@@@@
        .byte   $40,$40,$40,$30,$30,$30,$30,$30 ; 2B68 40 40 40 30 30 30 30 30  @@@00000
        .byte   $30,$30,$20,$20,$20,$20,$20,$20 ; 2B70 30 30 20 20 20 20 20 20  00      
        .byte   $10,$10,$10,$10,$10,$10,$00,$00 ; 2B78 10 10 10 10 10 10 00 00  ........
        .byte   $00,$00,$00,$F0,$F0,$F0,$F0,$F0 ; 2B80 00 00 00 F0 F0 F0 F0 F0  ........
        .byte   $F0,$E0,$E0,$E0,$E0,$E0,$E0,$D0 ; 2B88 F0 E0 E0 E0 E0 E0 E0 D0  ........
        .byte   $D0,$D0,$D0,$D0,$D0,$D0,$C0,$C0 ; 2B90 D0 D0 D0 D0 D0 D0 C0 C0  ........
        .byte   $C0,$C0,$C0,$C0,$C0,$B0,$B0,$B0 ; 2B98 C0 C0 C0 C0 C0 B0 B0 B0  ........
        .byte   $B0,$B0,$B0,$B0,$B0,$A0,$A0,$A0 ; 2BA0 B0 B0 B0 B0 B0 A0 A0 A0  ........
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0 ; 2BA8 A0 A0 A0 A0 A0 A0 A0 A0  ........
        .byte   $A0,$90,$90,$90,$90,$90,$90,$90 ; 2BB0 A0 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2BB8 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2BC0 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2BC8 90 90 90 90 90 90 90 90  ........
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0 ; 2BD0 A0 A0 A0 A0 A0 A0 A0 A0  ........
        .byte   $A0,$A0,$A0,$A0,$B0,$B0,$B0,$B0 ; 2BD8 A0 A0 A0 A0 B0 B0 B0 B0  ........
        .byte   $B0,$B0,$B0,$B0,$C0,$C0,$C0,$C0 ; 2BE0 B0 B0 B0 B0 C0 C0 C0 C0  ........
        .byte   $C0,$C0,$C0,$D0,$D0,$D0,$D0,$D0 ; 2BE8 C0 C0 C0 D0 D0 D0 D0 D0  ........
        .byte   $D0,$D0,$E0,$E0,$E0,$E0,$E0,$E0 ; 2BF0 D0 D0 E0 E0 E0 E0 E0 E0  ........
        .byte   $F0,$F0,$F0,$F0,$F0,$F0,$00,$00 ; 2BF8 F0 F0 F0 F0 F0 F0 00 00  ........

; ----------------------------------------------------------------------------

D2C00:  .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C00 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C08 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C10 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C18 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C20 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C28 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C30 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C38 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C40 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C48 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C50 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C58 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C60 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C68 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C70 90 90 90 90 90 90 90 90  ........
        .byte   $90,$90,$90,$90,$90,$90,$90,$90 ; 2C78 90 90 90 90 90 90 90 90  ........
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2C80 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2C88 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2C90 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2C98 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CA0 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CA8 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CB0 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CB8 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CC0 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CC8 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CD0 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CD8 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CE0 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CE8 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CF0 70 70 70 70 70 70 70 70  pppppppp
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; 2CF8 70 70 70 70 70 70 70 70  pppppppp

; ----------------------------------------------------------------------------

D2D00:  .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2D00 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2D08 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$01,$01,$02,$02,$03,$03 ; 2D10 00 00 01 01 02 02 03 03  ........
        .byte   $04,$04,$05,$05,$06,$06,$07,$07 ; 2D18 04 04 05 05 06 06 07 07  ........
        .byte   $00,$01,$02,$03,$04,$05,$06,$07 ; 2D20 00 01 02 03 04 05 06 07  ........
        .byte   $08,$09,$0A,$0B,$0C,$0D,$0E,$0F ; 2D28 08 09 0A 0B 0C 0D 0E 0F  ........
        .byte   $00,$01,$03,$04,$06,$07,$09,$0A ; 2D30 00 01 03 04 06 07 09 0A  ........
        .byte   $0C,$0D,$0F,$10,$12,$13,$15,$16 ; 2D38 0C 0D 0F 10 12 13 15 16  ........
        .byte   $00,$02,$04,$06,$08,$0A,$0C,$0E ; 2D40 00 02 04 06 08 0A 0C 0E  ........
        .byte   $10,$12,$14,$16,$18,$1A,$1C,$1E ; 2D48 10 12 14 16 18 1A 1C 1E  ........
        .byte   $00,$02,$05,$07,$0A,$0C,$0F,$11 ; 2D50 00 02 05 07 0A 0C 0F 11  ........
        .byte   $14,$16,$19,$1B,$1E,$20,$23,$25 ; 2D58 14 16 19 1B 1E 20 23 25  ..... #%
        .byte   $00,$03,$06,$09,$0C,$0F,$12,$15 ; 2D60 00 03 06 09 0C 0F 12 15  ........
        .byte   $18,$1B,$1E,$21,$24,$27,$2A,$2D ; 2D68 18 1B 1E 21 24 27 2A 2D  ...!$'*-
        .byte   $00,$03,$07,$0A,$0E,$11,$15,$18 ; 2D70 00 03 07 0A 0E 11 15 18  ........
        .byte   $1C,$1F,$23,$26,$2A,$2D,$31,$34 ; 2D78 1C 1F 23 26 2A 2D 31 34  ..#&*-14
        .byte   $00,$FC,$F8,$F4,$F0,$EC,$E8,$E4 ; 2D80 00 FC F8 F4 F0 EC E8 E4  ........
        .byte   $E0,$DC,$D8,$D4,$D0,$CC,$C8,$C4 ; 2D88 E0 DC D8 D4 D0 CC C8 C4  ........
        .byte   $00,$FC,$F9,$F5,$F2,$EE,$EB,$E7 ; 2D90 00 FC F9 F5 F2 EE EB E7  ........
        .byte   $E4,$E0,$DD,$D9,$D6,$D2,$CF,$CB ; 2D98 E4 E0 DD D9 D6 D2 CF CB  ........
        .byte   $00,$FD,$FA,$F7,$F4,$F1,$EE,$EB ; 2DA0 00 FD FA F7 F4 F1 EE EB  ........
        .byte   $E8,$E5,$E2,$DF,$DC,$D9,$D6,$D3 ; 2DA8 E8 E5 E2 DF DC D9 D6 D3  ........
        .byte   $00,$FD,$FB,$F8,$F6,$F3,$F1,$EE ; 2DB0 00 FD FB F8 F6 F3 F1 EE  ........
        .byte   $EC,$E9,$E7,$E4,$E2,$DF,$DD,$DA ; 2DB8 EC E9 E7 E4 E2 DF DD DA  ........
        .byte   $00,$FE,$FC,$FA,$F8,$F6,$F4,$F2 ; 2DC0 00 FE FC FA F8 F6 F4 F2  ........
        .byte   $F0,$EE,$EC,$EA,$E8,$E6,$E4,$E2 ; 2DC8 F0 EE EC EA E8 E6 E4 E2  ........
        .byte   $00,$FE,$FD,$FB,$FA,$F8,$F7,$F5 ; 2DD0 00 FE FD FB FA F8 F7 F5  ........
        .byte   $F4,$F2,$F1,$EF,$EE,$EC,$EB,$E9 ; 2DD8 F4 F2 F1 EF EE EC EB E9  ........
        .byte   $00,$FF,$FE,$FD,$FC,$FB,$FA,$F9 ; 2DE0 00 FF FE FD FC FB FA F9  ........
        .byte   $F8,$F7,$F6,$F5,$F4,$F3,$F2,$F1 ; 2DE8 F8 F7 F6 F5 F4 F3 F2 F1  ........
        .byte   $00,$FF,$FF,$FE,$FE,$FD,$FD,$FC ; 2DF0 00 FF FF FE FE FD FD FC  ........
        .byte   $FC,$FB,$FB,$FA,$FA,$F9,$F9,$F8 ; 2DF8 FC FB FB FA FA F9 F9 F8  ........

; ----------------------------------------------------------------------------

D2E00:  .byte   $2C,$2C,$2A,$28,$27,$26,$25,$23 ; 2E00 2C 2C 2A 28 27 26 25 23  ,,*('&%#
        .byte   $23,$25,$27,$29,$2B,$2E,$31,$33 ; 2E08 23 25 27 29 2B 2E 31 33  #%')+.13
        .byte   $35,$38,$38,$39,$3A,$3B,$3C,$3D ; 2E10 35 38 38 39 3A 3B 3C 3D  5889:;<=
        .byte   $3E,$3E,$3F,$40,$41,$42,$43,$44 ; 2E18 3E 3E 3F 40 41 42 43 44  >>?@ABCD
        .byte   $45,$46,$48,$49,$4A,$4C,$4D,$4E ; 2E20 45 46 48 49 4A 4C 4D 4E  EFHIJLMN
        .byte   $50,$51,$52,$53,$52,$50,$4E,$4D ; 2E28 50 51 52 53 52 50 4E 4D  PQRSRPNM
        .byte   $4A,$47,$46,$43,$41,$40,$3E,$3C ; 2E30 4A 47 46 43 41 40 3E 3C  JGFCA@><
        .byte   $3B,$39,$37,$37,$37,$37,$37,$37 ; 2E38 3B 39 37 37 37 37 37 37  ;9777777
        .byte   $37,$37,$37,$2D,$2E,$26,$13,$09 ; 2E40 37 37 37 2D 2E 26 13 09  777-.&..
        .byte   $F6,$F5,$F4,$F3,$F2,$F1,$F0,$EF ; 2E48 F6 F5 F4 F3 F2 F1 F0 EF  ........
        .byte   $EF,$EF,$EF,$EF,$EF,$EF,$EF,$EF ; 2E50 EF EF EF EF EF EF EF EF  ........
        .byte   $EE,$EF,$F1,$F2,$FE,$13,$1F,$20 ; 2E58 EE EF F1 F2 FE 13 1F 20  ....... 
        .byte   $22,$22,$22,$22,$22,$22,$0E,$FA ; 2E60 22 22 22 22 22 22 0E FA  """"""..
        .byte   $E6,$D2,$E6,$FA,$0E,$22,$0E,$F0 ; 2E68 E6 D2 E6 FA 0E 22 0E F0  ....."..
        .byte   $DC,$BE,$BE,$BE,$BE,$BE,$BE,$BE ; 2E70 DC BE BE BE BE BE BE BE  ........
        .byte   $C8,$D2,$DC,$DC,$E6,$F0,$FA,$FA ; 2E78 C8 D2 DC DC E6 F0 FA FA  ........
        .byte   $FA,$FA,$04,$04,$0E,$18,$18,$18 ; 2E80 FA FA 04 04 0E 18 18 18  ........
        .byte   $0E,$04,$FA,$F0,$E6,$E6,$E6,$E6 ; 2E88 0E 04 FA F0 E6 E6 E6 E6  ........
        .byte   $E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6 ; 2E90 E6 E6 E6 E6 E6 E6 E6 E6  ........
        .byte   $E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6 ; 2E98 E6 E6 E6 E6 E6 E6 E6 E6  ........
        .byte   $E6,$E6,$00,$00,$00,$00,$00,$00 ; 2EA0 E6 E6 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2EA8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2EB0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2EB8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2EC0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2EC8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2ED0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2ED8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2EE0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2EE8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2EF0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2EF8 00 00 00 00 00 00 00 00  ........

; ----------------------------------------------------------------------------

D2F00:  .byte   $0E,$0E,$10,$13,$13,$13,$13,$13 ; 2F00 0E 0E 10 13 13 13 13 13  ........
        .byte   $13,$13,$13,$13,$12,$12,$11,$10 ; 2F08 13 13 13 13 12 12 11 10  ........
        .byte   $10,$10,$10,$10,$10,$10,$10,$11 ; 2F10 10 10 10 10 10 10 10 11  ........
        .byte   $11,$12,$12,$12,$12,$12,$12,$12 ; 2F18 11 12 12 12 12 12 12 12  ........
        .byte   $12,$12,$11,$11,$10,$0F,$0F,$0E ; 2F20 12 12 11 11 10 0F 0F 0E  ........
        .byte   $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D ; 2F28 0D 0D 0D 0D 0D 0D 0D 0D  ........
        .byte   $0E,$10,$11,$13,$13,$13,$13,$13 ; 2F30 0E 10 11 13 13 13 13 13  ........
        .byte   $13,$13,$13,$13,$13,$13,$13,$13 ; 2F38 13 13 13 13 13 13 13 13  ........
        .byte   $13,$13,$13,$06,$06,$09,$0C,$0F ; 2F40 13 13 13 06 06 09 0C 0F  ........
        .byte   $13,$13,$13,$13,$13,$13,$13,$13 ; 2F48 13 13 13 13 13 13 13 13  ........
        .byte   $13,$13,$13,$13,$13,$13,$13,$13 ; 2F50 13 13 13 13 13 13 13 13  ........
        .byte   $0E,$0E,$0E,$0E,$0C,$09,$06,$06 ; 2F58 0E 0E 0E 0E 0C 09 06 06  ........
        .byte   $06,$06,$06,$06,$06,$06,$0A,$0E ; 2F60 06 06 06 06 06 06 0A 0E  ........
        .byte   $12,$17,$13,$0F,$0B,$06,$0B,$10 ; 2F68 12 17 13 0F 0B 06 0B 10  ........
        .byte   $15,$1B,$1B,$1B,$1B,$1B,$1B,$1A ; 2F70 15 1B 1B 1B 1B 1B 1B 1A  ........
        .byte   $18,$17,$15,$14,$12,$11,$0F,$0F ; 2F78 18 17 15 14 12 11 0F 0F  ........
        .byte   $0F,$0E,$0D,$0C,$0B,$09,$09,$09 ; 2F80 0F 0E 0D 0C 0B 09 09 09  ........
        .byte   $0A,$0C,$0E,$10,$12,$12,$12,$12 ; 2F88 0A 0C 0E 10 12 12 12 12  ........
        .byte   $12,$12,$12,$12,$12,$12,$12,$12 ; 2F90 12 12 12 12 12 12 12 12  ........
        .byte   $12,$12,$12,$12,$13,$13,$13,$13 ; 2F98 12 12 12 12 13 13 13 13  ........
        .byte   $13,$13,$00,$00,$00,$00,$00,$00 ; 2FA0 13 13 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FA8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FB0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FB8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FC0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FC8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FD0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FD8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FE0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FE8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FF0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 2FF8 00 00 00 00 00 00 00 00  ........

; ----------------------------------------------------------------------------

D3000:  .byte   $49,$49,$46,$43,$43,$43,$43,$43 ; 3000 49 49 46 43 43 43 43 43  IIFCCCCC
        .byte   $43,$43,$43,$3D,$37,$31,$2B,$25 ; 3008 43 43 43 3D 37 31 2B 25  CCC=71+%
        .byte   $25,$25,$25,$25,$25,$24,$23,$21 ; 3010 25 25 25 25 25 24 23 21  %%%%%$#!
        .byte   $20,$1E,$1E,$1E,$1E,$1E,$1E,$1E ; 3018 20 1E 1E 1E 1E 1E 1E 1E   .......
        .byte   $1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E ; 3020 1E 1E 1E 1E 1E 1E 1E 1E  ........
        .byte   $1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D ; 3028 1D 1D 1D 1D 1D 1D 1D 1D  ........
        .byte   $26,$30,$39,$43,$43,$43,$43,$43 ; 3030 26 30 39 43 43 43 43 43  &09CCCCC
        .byte   $43,$43,$43,$43,$43,$43,$43,$43 ; 3038 43 43 43 43 43 43 43 43  CCCCCCCC
        .byte   $43,$43,$43,$54,$54,$50,$4C,$48 ; 3040 43 43 43 54 54 50 4C 48  CCCTTPLH
        .byte   $43,$43,$43,$43,$43,$43,$43,$43 ; 3048 43 43 43 43 43 43 43 43  CCCCCCCC
        .byte   $43,$43,$43,$43,$43,$43,$43,$43 ; 3050 43 43 43 43 43 43 43 43  CCCCCCCC
        .byte   $49,$49,$49,$49,$43,$3D,$36,$36 ; 3058 49 49 49 49 43 3D 36 36  IIIIC=66
        .byte   $36,$36,$39,$3C,$3F,$42,$3D,$37 ; 3060 36 36 39 3C 3F 42 3D 37  669<?B=7
        .byte   $32,$2C,$33,$3A,$41,$49,$41,$38 ; 3068 32 2C 33 3A 41 49 41 38  2,3:AIA8
        .byte   $30,$27,$27,$27,$27,$27,$27,$2A ; 3070 30 27 27 27 27 27 27 2A  0''''''*
        .byte   $2E,$32,$36,$39,$3D,$41,$45,$45 ; 3078 2E 32 36 39 3D 41 45 45  .269=AEE
        .byte   $45,$42,$3E,$3B,$37,$33,$33,$33 ; 3080 45 42 3E 3B 37 33 33 33  EB>;7333
        .byte   $33,$33,$32,$32,$31,$31,$31,$31 ; 3088 33 33 32 32 31 31 31 31  33221111
        .byte   $31,$31,$31,$31,$31,$31,$31,$31 ; 3090 31 31 31 31 31 31 31 31  11111111
        .byte   $31,$35,$3A,$3E,$43,$43,$43,$43 ; 3098 31 35 3A 3E 43 43 43 43  15:>CCCC
        .byte   $43,$43,$00,$00,$00,$00,$00,$00 ; 30A0 43 43 00 00 00 00 00 00  CC......
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30A8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30B0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30B8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30C0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30C8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30D0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30D8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30E0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30E8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30F0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 30F8 00 00 00 00 00 00 00 00  ........

; ----------------------------------------------------------------------------

D3100:  .byte   $5D,$5D,$5C,$5B,$5B,$5B,$5B,$5B ; 3100 5D 5D 5C 5B 5B 5B 5B 5B  ]]\[[[[[
        .byte   $5B,$5B,$5B,$5E,$62,$66,$6A,$6E ; 3108 5B 5B 5B 5E 62 66 6A 6E  [[[^bfjn
        .byte   $6E,$6E,$6E,$6E,$6E,$6A,$66,$61 ; 3110 6E 6E 6E 6E 6E 6A 66 61  nnnnnjfa
        .byte   $5D,$58,$58,$58,$58,$58,$58,$58 ; 3118 5D 58 58 58 58 58 58 58  ]XXXXXXX
        .byte   $58,$57,$56,$55,$54,$53,$52,$51 ; 3120 58 57 56 55 54 53 52 51  XWVUTSRQ
        .byte   $50,$50,$50,$50,$50,$50,$50,$50 ; 3128 50 50 50 50 50 50 50 50  PPPPPPPP
        .byte   $52,$55,$58,$5B,$5B,$5B,$5B,$5B ; 3130 52 55 58 5B 5B 5B 5B 5B  RUX[[[[[
        .byte   $5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B ; 3138 5B 5B 5B 5B 5B 5B 5B 5B  [[[[[[[[
        .byte   $5B,$5B,$5B,$5E,$5E,$5E,$5D,$5C ; 3140 5B 5B 5B 5E 5E 5E 5D 5C  [[[^^^]\
        .byte   $5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B ; 3148 5B 5B 5B 5B 5B 5B 5B 5B  [[[[[[[[
        .byte   $5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B ; 3150 5B 5B 5B 5B 5B 5B 5B 5B  [[[[[[[[
        .byte   $5D,$5D,$5D,$5D,$66,$6F,$79,$79 ; 3158 5D 5D 5D 5D 66 6F 79 79  ]]]]foyy
        .byte   $79,$79,$79,$79,$79,$79,$71,$68 ; 3160 79 79 79 79 79 79 71 68  yyyyyyqh
        .byte   $60,$57,$5A,$5D,$60,$63,$61,$5E ; 3168 60 57 5A 5D 60 63 61 5E  `WZ]`ca^
        .byte   $5B,$58,$58,$58,$58,$58,$58,$58 ; 3170 5B 58 58 58 58 58 58 58  [XXXXXXX
        .byte   $59,$59,$5A,$5B,$5B,$5C,$5D,$5D ; 3178 59 59 5A 5B 5B 5C 5D 5D  YYZ[[\]]
        .byte   $5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D ; 3180 5D 5D 5D 5D 5D 5D 5D 5D  ]]]]]]]]
        .byte   $57,$51,$4B,$45,$3E,$3E,$3E,$3E ; 3188 57 51 4B 45 3E 3E 3E 3E  WQKE>>>>
        .byte   $3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E ; 3190 3E 3E 3E 3E 3E 3E 3E 3E  >>>>>>>>
        .byte   $3E,$45,$4C,$53,$5B,$5B,$5B,$5B ; 3198 3E 45 4C 53 5B 5B 5B 5B  >ELS[[[[
        .byte   $5B,$5B,$00,$00,$00,$00,$00,$00 ; 31A0 5B 5B 00 00 00 00 00 00  [[......
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31A8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31B0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31B8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31C0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31C8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31D0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31D8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31E0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31E8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31F0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 31F8 00 00 00 00 00 00 00 00  ........

; ----------------------------------------------------------------------------

        ; D3200 .. D34FF hold the 768 samples of four bits each (>)

D3200:  .byte   $00,$00,$04,$0D,$0D,$0D,$0D,$0D ; 3200 00 00 04 0D 0D 0D 0D 0D  ........
        .byte   $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0B ; 3208 0D 0D 0D 0D 0D 0D 0D 0B  ........
        .byte   $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0D ; 3210 0B 0B 0B 0B 0B 0B 0B 0D  ........
        .byte   $0D,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; 3218 0D 0F 0F 0F 0F 0F 0F 0F  ........
        .byte   $0F,$0F,$0F,$0F,$0D,$0D,$0D,$0D ; 3220 0F 0F 0F 0F 0D 0D 0D 0D  ........
        .byte   $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B ; 3228 0B 0B 0B 0B 0B 0B 0B 0B  ........
        .byte   $06,$04,$02,$00,$00,$00,$00,$00 ; 3230 06 04 02 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3238 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$02,$00,$00,$00,$00 ; 3240 00 00 00 02 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3248 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3250 00 00 00 00 00 00 00 00  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3258 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$00,$02,$02 ; 3260 02 02 02 02 02 00 02 02  ........
        .byte   $02,$0F,$02,$02,$02,$00,$02,$02 ; 3268 02 0F 02 02 02 00 02 02  ........
        .byte   $02,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; 3270 02 0F 0F 0F 0F 0F 0F 0F  ........
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$02,$02 ; 3278 0F 0F 0F 0F 0F 0F 02 02  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3280 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3288 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3290 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$00,$00,$00,$00 ; 3298 02 02 02 02 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32A0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32A8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32B0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32B8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32C0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32C8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32D0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32D8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32E0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32E8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32F0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 32F8 00 00 00 00 00 00 00 00  ........

; ----------------------------------------------------------------------------

D3300:  .byte   $00,$00,$03,$0B,$0B,$0B,$0B,$0B ; 3300 00 00 03 0B 0B 0B 0B 0B  ........
        .byte   $0B,$0B,$0B,$09,$08,$06,$05,$04 ; 3308 0B 0B 0B 09 08 06 05 04  ........
        .byte   $04,$04,$04,$04,$04,$04,$05,$06 ; 3310 04 04 04 04 04 04 05 06  ........
        .byte   $08,$09,$09,$09,$09,$09,$09,$09 ; 3318 08 09 09 09 09 09 09 09  ........
        .byte   $09,$09,$08,$08,$06,$06,$05,$05 ; 3320 09 09 08 08 06 06 05 05  ........
        .byte   $04,$04,$04,$04,$04,$04,$04,$04 ; 3328 04 04 04 04 04 04 04 04  ........
        .byte   $03,$02,$02,$00,$00,$00,$00,$00 ; 3330 03 02 02 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3338 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$01,$00,$00,$00,$00 ; 3340 00 00 00 01 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3348 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3350 00 00 00 00 00 00 00 00  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3358 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$00,$02,$02 ; 3360 02 02 02 02 02 00 02 02  ........
        .byte   $02,$02,$02,$02,$02,$00,$02,$02 ; 3368 02 02 02 02 02 00 02 02  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3370 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3378 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3380 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3388 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3390 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$00,$00,$00,$00 ; 3398 02 02 02 02 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33A0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33A8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33B0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33B8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33C0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33C8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33D0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33D8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33E0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33E8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33F0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 33F8 00 00 00 00 00 00 00 00  ........

; ----------------------------------------------------------------------------

D3400:  .byte   $00,$00,$02,$04,$04,$04,$04,$04 ; 3400 00 00 02 04 04 04 04 04  ........
        .byte   $04,$04,$04,$04,$03,$02,$02,$01 ; 3408 04 04 04 04 03 02 02 01  ........
        .byte   $01,$01,$01,$01,$01,$01,$01,$01 ; 3410 01 01 01 01 01 01 01 01  ........
        .byte   $01,$00,$00,$00,$00,$00,$00,$00 ; 3418 01 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3420 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3428 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3430 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3438 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3440 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3448 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3450 00 00 00 00 00 00 00 00  ........
        .byte   $02,$02,$02,$02,$02,$02,$00,$00 ; 3458 02 02 02 02 02 02 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3460 00 00 00 00 00 00 00 00  ........
        .byte   $00,$01,$01,$01,$01,$00,$00,$00 ; 3468 00 01 01 01 01 00 00 00  ........
        .byte   $00,$01,$01,$01,$01,$01,$01,$01 ; 3470 00 01 01 01 01 01 01 01  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3478 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$00,$00,$00 ; 3480 02 02 02 02 02 00 00 00  ........
        .byte   $01,$02,$02,$02,$02,$02,$02,$02 ; 3488 01 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$02,$02,$02 ; 3490 02 02 02 02 02 02 02 02  ........
        .byte   $02,$02,$02,$02,$00,$00,$00,$00 ; 3498 02 02 02 02 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34A0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34A8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34B0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34B8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34C0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34C8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34D0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34D8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34E0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34E8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34F0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 34F8 00 00 00 00 00 00 00 00  ........

; ----------------------------------------------------------------------------

D3500:  .byte   $7C,$7C,$00,$00,$00,$00,$00,$00 ; 3500 7C 7C 00 00 00 00 00 00  ||......
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3508 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3510 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3518 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3520 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3528 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3530 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3538 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3540 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3548 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3550 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3558 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$BB,$BB,$00,$00 ; 3560 00 00 00 00 BB BB 00 00  ........
        .byte   $00,$00,$00,$00,$F1,$F1,$00,$00 ; 3568 00 00 00 00 F1 F1 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3570 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3578 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$01,$01,$01,$01,$01 ; 3580 00 00 00 01 01 01 01 01  ........
        .byte   $01,$00,$00,$00,$00,$00,$00,$00 ; 3588 01 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3590 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3598 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35A0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35A8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35B0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35B8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35C0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35C8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35D0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35D8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35E0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35E8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35F0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 35F8 00 00 00 00 00 00 00 00  ........

; ----------------------------------------------------------------------------

D3600:  .byte   $00,$13,$13,$13,$13,$0A,$0E,$13 ; 3600 00 13 13 13 13 0A 0E 13  ........
        .byte   $18,$1B,$17,$15,$10,$14,$0E,$12 ; 3608 18 1B 17 15 10 14 0E 12  ........
        .byte   $0E,$12,$12,$10,$0D,$0F,$0B,$12 ; 3610 0E 12 12 10 0D 0F 0B 12  ........
        .byte   $0E,$0B,$09,$06,$06,$06,$06,$11 ; 3618 0E 0B 09 06 06 06 06 11  ........
        .byte   $06,$06,$06,$06,$0E,$10,$09,$0A ; 3620 06 06 06 06 0E 10 09 0A  ........
        .byte   $08,$0A,$06,$06,$06,$05,$06,$00 ; 3628 08 0A 06 06 06 05 06 00  ........
        .byte   $13,$1B,$15,$1B,$12,$0D,$06,$06 ; 3630 13 1B 15 1B 12 0D 06 06  ........
        .byte   $06,$06,$06,$06,$06,$06,$06,$06 ; 3638 06 06 06 06 06 06 06 06  ........
        .byte   $06,$06,$06,$06,$06,$06,$06,$06 ; 3640 06 06 06 06 06 06 06 06  ........
        .byte   $06,$0A,$0A,$06,$06,$06,$2C,$13 ; 3648 06 0A 0A 06 06 06 2C 13  ......,.
D3650:  .byte   $00,$43,$43,$43,$43,$54,$49,$43 ; 3650 00 43 43 43 43 54 49 43  .CCCCTIC
        .byte   $3F,$28,$2C,$1F,$25,$2D,$49,$31 ; 3658 3F 28 2C 1F 25 2D 49 31  ?(,.%-I1
        .byte   $24,$1E,$33,$25,$1D,$45,$18,$32 ; 3660 24 1E 33 25 1D 45 18 32  $.3%.E.2
        .byte   $1E,$18,$53,$2E,$36,$56,$36,$43 ; 3668 1E 18 53 2E 36 56 36 43  ..S.6V6C
        .byte   $49,$4F,$1A,$42,$49,$25,$33,$42 ; 3670 49 4F 1A 42 49 25 33 42  IO.BI%3B
        .byte   $28,$2F,$4F,$4F,$42,$4F,$6E,$00 ; 3678 28 2F 4F 4F 42 4F 6E 00  (/OOBOn.
        .byte   $48,$27,$1F,$2B,$1E,$22,$1A,$1A ; 3680 48 27 1F 2B 1E 22 1A 1A  H'.+."..
        .byte   $1A,$42,$42,$42,$6E,$6E,$6E,$54 ; 3688 1A 42 42 42 6E 6E 6E 54  .BBBnnnT
        .byte   $54,$54,$1A,$1A,$1A,$42,$42,$42 ; 3690 54 54 1A 1A 1A 42 42 42  TT...BBB
        .byte   $6D,$56,$6D,$54,$54,$54,$7F,$7F ; 3698 6D 56 6D 54 54 54 7F 7F  mVmTTT..
D36A0:  .byte   $00,$5B,$5B,$5B,$5B,$6E,$5D,$5B ; 36A0 00 5B 5B 5B 5B 6E 5D 5B  .[[[[n][
        .byte   $58,$59,$57,$58,$52,$59,$5D,$3E ; 36A8 58 59 57 58 52 59 5D 3E  XYWXRY]>
        .byte   $52,$58,$3E,$6E,$50,$5D,$5A,$3C ; 36B0 52 58 3E 6E 50 5D 5A 3C  RX>nP]Z<
        .byte   $6E,$5A,$6E,$51,$79,$65,$79,$5B ; 36B8 6E 5A 6E 51 79 65 79 5B  nZnQyey[
        .byte   $63,$6A,$51,$79,$5D,$52,$5D,$67 ; 36C0 63 6A 51 79 5D 52 5D 67  cjQy]R]g
        .byte   $4C,$5D,$65,$65,$79,$65,$79,$00 ; 36C8 4C 5D 65 65 79 65 79 00  L]eeyey.
        .byte   $5A,$58,$58,$58,$58,$52,$51,$51 ; 36D0 5A 58 58 58 58 52 51 51  ZXXXXRQQ
        .byte   $51,$79,$79,$79,$70,$6E,$6E,$5E ; 36D8 51 79 79 79 70 6E 6E 5E  Qyyypnn^
        .byte   $5E,$5E,$51,$51,$51,$79,$79,$79 ; 36E0 5E 5E 51 51 51 79 79 79  ^^QQQyyy
        .byte   $65,$65,$70,$5E,$5E,$5E,$08,$01 ; 36E8 65 65 70 5E 5E 5E 08 01  eep^^^..
D36F0:  .byte   $00,$00,$00,$00,$00,$0D,$0D,$0E ; 36F0 00 00 00 00 00 0D 0D 0E  ........
        .byte   $0F,$0F,$0F,$0F,$0F,$0C,$0D,$0C ; 36F8 0F 0F 0F 0F 0F 0C 0D 0C  ........
        .byte   $0F,$0F,$0D,$0D,$0D,$0E,$0D,$0C ; 3700 0F 0F 0D 0D 0D 0E 0D 0C  ........
        .byte   $0D,$0D,$0D,$0C,$09,$09,$00,$00 ; 3708 0D 0D 0D 0C 09 09 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$0B,$0B ; 3710 00 00 00 00 00 00 0B 0B  ........
        .byte   $0B,$0B,$00,$00,$01,$0B,$00,$02 ; 3718 0B 0B 00 00 01 0B 00 02  ........
        .byte   $0E,$0F,$0F,$0F,$0F,$0D,$02,$04 ; 3720 0E 0F 0F 0F 0F 0D 02 04  ........
        .byte   $00,$02,$04,$00,$01,$04,$00,$01 ; 3728 00 02 04 00 01 04 00 01  ........
        .byte   $04,$00,$00,$00,$00,$00,$00,$00 ; 3730 04 00 00 00 00 00 00 00  ........
        .byte   $00,$0C,$00,$00,$00,$00,$0F,$0F ; 3738 00 0C 00 00 00 00 0F 0F  ........
D3740:  .byte   $00,$00,$00,$00,$00,$0A,$0B,$0D ; 3740 00 00 00 00 00 0A 0B 0D  ........
        .byte   $0E,$0D,$0C,$0C,$0B,$09,$0B,$0B ; 3748 0E 0D 0C 0C 0B 09 0B 0B  ........
        .byte   $0C,$0C,$0C,$08,$08,$0C,$08,$0A ; 3750 0C 0C 0C 08 08 0C 08 0A  ........
        .byte   $08,$08,$0A,$03,$09,$06,$00,$00 ; 3758 08 08 0A 03 09 06 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$03,$05 ; 3760 00 00 00 00 00 00 03 05  ........
        .byte   $03,$04,$00,$00,$00,$05,$0A,$02 ; 3768 03 04 00 00 00 05 0A 02  ........
        .byte   $0E,$0D,$0C,$0D,$0C,$08,$00,$01 ; 3770 0E 0D 0C 0D 0C 08 00 01  ........
        .byte   $00,$00,$01,$00,$00,$01,$00,$00 ; 3778 00 00 01 00 00 01 00 00  ........
        .byte   $01,$00,$00,$00,$00,$00,$00,$00 ; 3780 01 00 00 00 00 00 00 00  ........
        .byte   $00,$0A,$00,$00,$0A,$00,$00,$00 ; 3788 00 0A 00 00 0A 00 00 00  ........
D3790:  .byte   $00,$00,$00,$00,$00,$08,$07,$08 ; 3790 00 00 00 00 00 08 07 08  ........
        .byte   $08,$01,$01,$00,$01,$00,$07,$05 ; 3798 08 01 01 00 01 00 07 05  ........
        .byte   $01,$00,$06,$01,$00,$07,$00,$05 ; 37A0 01 00 06 01 00 07 00 05  ........
        .byte   $01,$00,$08,$00,$00,$03,$00,$00 ; 37A8 01 00 08 00 00 03 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$01 ; 37B0 00 00 00 00 00 00 00 01  ........
        .byte   $00,$00,$00,$00,$00,$01,$0E,$01 ; 37B8 00 00 00 00 00 01 0E 01  ........
        .byte   $09,$01,$00,$01,$00,$00,$00,$00 ; 37C0 09 01 00 01 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 37C8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 37D0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$07,$00,$00,$05,$00,$13,$10 ; 37D8 00 07 00 00 05 00 13 10  ........
D37E0:  .byte   $00,$12,$12,$12,$08,$0B,$09,$0B ; 37E0 00 12 12 12 08 0B 09 0B  ........
        .byte   $0E,$0F,$0B,$10,$0C,$06,$06,$0E ; 37E8 0E 0F 0B 10 0C 06 06 0E  ........
        .byte   $0C,$0E,$0C,$0B,$08,$08,$0B,$0A ; 37F0 0C 0E 0C 0B 08 08 0B 0A  ........
        .byte   $09,$08,$08,$08,$08,$08,$03,$05 ; 37F8 09 08 08 08 08 08 03 05  ........
        .byte   $02,$02,$02,$02,$02,$02,$06,$06 ; 3800 02 02 02 02 02 02 06 06  ........
        .byte   $08,$06,$06,$02,$09,$04,$02,$01 ; 3808 08 06 06 02 09 04 02 01  ........
        .byte   $0E,$0F,$0F,$0F,$0E,$0E,$08,$02 ; 3810 0E 0F 0F 0F 0E 0E 08 02  ........
        .byte   $02,$07,$02,$01,$07,$02,$02,$07 ; 3818 02 07 02 01 07 02 02 07  ........
        .byte   $02,$02,$08,$02,$02,$06,$02,$02 ; 3820 02 02 08 02 02 06 02 02  ........
        .byte   $07,$02,$04,$07,$01,$04,$05,$05 ; 3828 07 02 04 07 01 04 05 05  ........
D3830:  .byte   $00,$12,$12,$12,$08,$08,$08,$08 ; 3830 00 12 12 12 08 08 08 08  ........
        .byte   $08,$0B,$06,$0C,$0A,$05,$05,$0B ; 3838 08 0B 06 0C 0A 05 05 0B  ........
        .byte   $0A,$0A,$0A,$09,$08,$07,$09,$07 ; 3840 0A 0A 0A 09 08 07 09 07  ........
        .byte   $06,$08,$06,$07,$07,$07,$02,$05 ; 3848 06 08 06 07 07 07 02 05  ........
        .byte   $02,$02,$02,$02,$02,$02,$06,$06 ; 3850 02 02 02 02 02 02 06 06  ........
        .byte   $07,$06,$06,$02,$08,$03,$01,$1E ; 3858 07 06 06 02 08 03 01 1E  ........
        .byte   $0D,$0C,$0C,$0C,$0E,$09,$06,$01 ; 3860 0D 0C 0C 0C 0E 09 06 01  ........
        .byte   $02,$05,$01,$01,$06,$01,$02,$06 ; 3868 02 05 01 01 06 01 02 06  ........
        .byte   $01,$02,$08,$02,$02,$04,$02,$02 ; 3870 01 02 08 02 02 04 02 02  ........
        .byte   $06,$01,$04,$06,$01,$04,$C7,$FF ; 3878 06 01 04 06 01 04 C7 FF  ........
D3880:  .byte   $00,$02,$02,$02,$02,$04,$04,$04 ; 3880 00 02 02 02 02 04 04 04  ........
        .byte   $04,$04,$04,$04,$04,$04,$04,$04 ; 3888 04 04 04 04 04 04 04 04  ........
        .byte   $04,$04,$03,$02,$04,$04,$02,$02 ; 3890 04 04 03 02 04 04 02 02  ........
        .byte   $02,$02,$02,$01,$01,$01,$01,$01 ; 3898 02 02 02 01 01 01 01 01  ........
        .byte   $01,$01,$01,$01,$01,$01,$02,$02 ; 38A0 01 01 01 01 01 01 02 02  ........
        .byte   $02,$01,$00,$01,$00,$01,$00,$05 ; 38A8 02 01 00 01 00 01 00 05  ........
        .byte   $05,$05,$05,$05,$04,$04,$02,$00 ; 38B0 05 05 05 05 04 04 02 00  ........
        .byte   $01,$02,$00,$01,$02,$00,$01,$02 ; 38B8 01 02 00 01 02 00 01 02  ........
        .byte   $00,$01,$02,$00,$02,$02,$00,$01 ; 38C0 00 01 02 00 02 02 00 01  ........
        .byte   $03,$00,$02,$03,$00,$02,$A0,$A0 ; 38C8 03 00 02 03 00 02 A0 A0  ........
D38D0:  .byte   $00,$02,$02,$02,$02,$04,$04,$04 ; 38D0 00 02 02 02 02 04 04 04  ........
        .byte   $04,$04,$04,$04,$04,$04,$04,$04 ; 38D8 04 04 04 04 04 04 04 04  ........
        .byte   $04,$04,$03,$03,$04,$04,$03,$03 ; 38E0 04 04 03 03 04 04 03 03  ........
        .byte   $03,$03,$03,$01,$02,$03,$02,$01 ; 38E8 03 03 03 01 02 03 02 01  ........
        .byte   $03,$03,$03,$03,$01,$01,$03,$03 ; 38F0 03 03 03 03 01 01 03 03  ........
        .byte   $03,$02,$02,$03,$02,$03,$00,$00 ; 38F8 03 02 02 03 02 03 00 00  ........
        .byte   $05,$05,$05,$05,$04,$04,$02,$00 ; 3900 05 05 05 05 04 04 02 00  ........
        .byte   $02,$02,$00,$03,$02,$00,$04,$02 ; 3908 02 02 00 03 02 00 04 02  ........
        .byte   $00,$03,$02,$00,$02,$02,$00,$02 ; 3910 00 03 02 00 02 02 00 02  ........
        .byte   $03,$00,$03,$03,$00,$03,$B0,$A0 ; 3918 03 00 03 03 00 03 B0 A0  ........
D3920:  .byte   $00,$1F,$1F,$1F,$1F,$02,$02,$02 ; 3920 00 1F 1F 1F 1F 02 02 02  ........
        .byte   $02,$02,$02,$02,$02,$02,$05,$05 ; 3928 02 02 02 02 02 02 05 05  ........
        .byte   $02,$0A,$02,$08,$05,$05,$0B,$0A ; 3930 02 0A 02 08 05 05 0B 0A  ........
        .byte   $09,$08,$08,$A0,$08,$08,$17,$1F ; 3938 09 08 08 A0 08 08 17 1F  ........
        .byte   $12,$12,$12,$12,$1E,$1E,$14,$14 ; 3940 12 12 12 12 1E 1E 14 14  ........
        .byte   $14,$14,$17,$17,$1A,$1A,$1D,$1D ; 3948 14 14 17 17 1A 1A 1D 1D  ........
        .byte   $02,$02,$02,$02,$02,$02,$1A,$1D ; 3950 02 02 02 02 02 02 1A 1D  ........
        .byte   $1B,$1A,$1D,$1B,$1A,$1D,$1B,$1A ; 3958 1B 1A 1D 1B 1A 1D 1B 1A  ........
        .byte   $1D,$1B,$17,$1D,$17,$17,$1D,$17 ; 3960 1D 1B 17 1D 17 17 1D 17  ........
        .byte   $17,$1D,$17,$17,$1D,$17,$17,$17 ; 3968 17 1D 17 17 1D 17 17 17  ........
D3970:  .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3970 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3978 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3980 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3988 00 00 00 00 00 00 00 00  ........
        .byte   $F1,$E2,$D3,$BB,$7C,$95,$01,$02 ; 3990 F1 E2 D3 BB 7C 95 01 02  ....|...
        .byte   $03,$03,$00,$72,$00,$02,$00,$00 ; 3998 03 03 00 72 00 02 00 00  ...r....
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 39A0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 39A8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$1B,$00,$00,$19,$00 ; 39B0 00 00 00 1B 00 00 19 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 39B8 00 00 00 00 00 00 00 00  ........
        .byte   $38,$84,$6B,$19,$C6,$63,$18,$86 ; 39C0 38 84 6B 19 C6 63 18 86  8.k..c..
        .byte   $73,$98,$C6,$B1,$1C,$CA,$31,$8C ; 39C8 73 98 C6 B1 1C CA 31 8C  s.....1.
        .byte   $C7,$31,$88,$C2,$30,$98,$46,$31 ; 39D0 C7 31 88 C2 30 98 46 31  .1..0.F1
        .byte   $18,$C6,$35,$0C,$CA,$31,$0C,$C6 ; 39D8 18 C6 35 0C CA 31 0C C6  ..5..1..
        .byte   $21,$10,$24,$69,$12,$C2,$31,$14 ; 39E0 21 10 24 69 12 C2 31 14  !.$i..1.
        .byte   $C4,$71,$08,$4A,$22,$49,$AB,$6A ; 39E8 C4 71 08 4A 22 49 AB 6A  .q.J"I.j
        .byte   $A8,$AC,$49,$51,$32,$D5,$52,$88 ; 39F0 A8 AC 49 51 32 D5 52 88  ..IQ2.R.
        .byte   $93,$6C,$94,$22,$15,$54,$D2,$25 ; 39F8 93 6C 94 22 15 54 D2 25  .l.".T.%
        .byte   $96,$D4,$50,$A5,$46,$21,$08,$85 ; 3A00 96 D4 50 A5 46 21 08 85  ..P.F!..
        .byte   $6B,$18,$C4,$63,$10,$CE,$6B,$18 ; 3A08 6B 18 C4 63 10 CE 6B 18  k..c..k.
        .byte   $8C,$71,$19,$8C,$63,$35,$0C,$C6 ; 3A10 8C 71 19 8C 63 35 0C C6  .q..c5..
        .byte   $33,$99,$CC,$6C,$B5,$4E,$A2,$99 ; 3A18 33 99 CC 6C B5 4E A2 99  3..l.N..
        .byte   $46,$21,$28,$82,$95,$2E,$E3,$30 ; 3A20 46 21 28 82 95 2E E3 30  F!(....0
        .byte   $9C,$C5,$30,$9C,$A2,$B1,$9C,$67 ; 3A28 9C C5 30 9C A2 B1 9C 67  ..0....g
        .byte   $31,$88,$66,$59,$2C,$53,$18,$84 ; 3A30 31 88 66 59 2C 53 18 84  1.fY,S..
        .byte   $67,$50,$CA,$E3,$0A,$AC,$AB,$30 ; 3A38 67 50 CA E3 0A AC AB 30  gP.....0
        .byte   $AC,$62,$30,$8C,$63,$10,$94,$62 ; 3A40 AC 62 30 8C 63 10 94 62  .b0.c..b
        .byte   $B1,$8C,$82,$28,$96,$33,$98,$D6 ; 3A48 B1 8C 82 28 96 33 98 D6  ...(.3..
        .byte   $B5,$4C,$62,$29,$A5,$4A,$B5,$9C ; 3A50 B5 4C 62 29 A5 4A B5 9C  .Lb).J..
        .byte   $C6,$31,$14,$D6,$38,$9C,$4B,$B4 ; 3A58 C6 31 14 D6 38 9C 4B B4  .1..8.K.
        .byte   $86,$65,$18,$AE,$67,$1C,$A6,$63 ; 3A60 86 65 18 AE 67 1C A6 63  .e..g..c
        .byte   $19,$96,$23,$19,$84,$13,$08,$A6 ; 3A68 19 96 23 19 84 13 08 A6  ..#.....
        .byte   $52,$AC,$CA,$22,$89,$6E,$AB,$19 ; 3A70 52 AC CA 22 89 6E AB 19  R..".n..
        .byte   $8C,$62,$34,$C4,$62,$19,$86,$63 ; 3A78 8C 62 34 C4 62 19 86 63  .b4.b..c
        .byte   $18,$C4,$23,$58,$D6,$A3,$50,$42 ; 3A80 18 C4 23 58 D6 A3 50 42  ..#X..PB
        .byte   $54,$4A,$AD,$4A,$25,$11,$6B,$64 ; 3A88 54 4A AD 4A 25 11 6B 64  TJ.J%.kd
        .byte   $89,$4A,$63,$39,$8A,$23,$31,$2A ; 3A90 89 4A 63 39 8A 23 31 2A  .Jc9.#1*
        .byte   $EA,$A2,$A9,$44,$C5,$12,$CD,$42 ; 3A98 EA A2 A9 44 C5 12 CD 42  ...D...B
        .byte   $34,$8C,$62,$18,$8C,$63,$11,$48 ; 3AA0 34 8C 62 18 8C 63 11 48  4.b..c.H
        .byte   $66,$31,$9D,$44,$33,$1D,$46,$31 ; 3AA8 66 31 9D 44 33 1D 46 31  f1.D3.F1
        .byte   $9C,$C6,$B1,$0C,$CD,$32,$88,$C4 ; 3AB0 9C C6 B1 0C CD 32 88 C4  .....2..
        .byte   $73,$18,$86,$73,$08,$D6,$63,$58 ; 3AB8 73 18 86 73 08 D6 63 58  s..s..cX
        .byte   $07,$81,$E0,$F0,$3C,$07,$87,$90 ; 3AC0 07 81 E0 F0 3C 07 87 90  ....<...
        .byte   $3C,$7C,$0F,$C7,$C0,$C0,$F0,$7C ; 3AC8 3C 7C 0F C7 C0 C0 F0 7C  <|.....|
        .byte   $1E,$07,$80,$80,$00,$1C,$78,$70 ; 3AD0 1E 07 80 80 00 1C 78 70  ......xp
        .byte   $F1,$C7,$1F,$C0,$0C,$FE,$1C,$1F ; 3AD8 F1 C7 1F C0 0C FE 1C 1F  ........
        .byte   $1F,$0E,$0A,$7A,$C0,$71,$F2,$83 ; 3AE0 1F 0E 0A 7A C0 71 F2 83  ...z.q..
        .byte   $8F,$03,$0F,$0F,$0C,$00,$79,$F8 ; 3AE8 8F 03 0F 0F 0C 00 79 F8  ......y.
        .byte   $61,$E0,$43,$0F,$83,$E7,$18,$F9 ; 3AF0 61 E0 43 0F 83 E7 18 F9  a.C.....
        .byte   $C1,$13,$DA,$E9,$63,$8F,$0F,$83 ; 3AF8 C1 13 DA E9 63 8F 0F 83  ....c...
        .byte   $83,$87,$C3,$1F,$3C,$70,$F0,$E1 ; 3B00 83 87 C3 1F 3C 70 F0 E1  ....<p..
        .byte   $E1,$E3,$87,$B8,$71,$0E,$20,$E3 ; 3B08 E1 E3 87 B8 71 0E 20 E3  ....q. .
        .byte   $8D,$48,$78,$1C,$93,$87,$30,$E1 ; 3B10 8D 48 78 1C 93 87 30 E1  .Hx...0.
        .byte   $C1,$C1,$E4,$78,$21,$83,$83,$C3 ; 3B18 C1 C1 E4 78 21 83 83 C3  ...x!...
        .byte   $87,$06,$39,$E5,$C3,$87,$07,$0E ; 3B20 87 06 39 E5 C3 87 07 0E  ..9.....
        .byte   $1C,$1C,$70,$F4,$71,$9C,$60,$36 ; 3B28 1C 1C 70 F4 71 9C 60 36  ..p.q.`6
        .byte   $32,$C3,$1E,$3C,$F3,$8F,$0E,$3C ; 3B30 32 C3 1E 3C F3 8F 0E 3C  2..<...<
        .byte   $70,$E3,$C7,$8F,$0F,$0F,$0E,$3C ; 3B38 70 E3 C7 8F 0F 0F 0E 3C  p......<
        .byte   $78,$F0,$E3,$87,$06,$F0,$E3,$07 ; 3B40 78 F0 E3 87 06 F0 E3 07  x.......
        .byte   $C1,$99,$87,$0F,$18,$78,$70,$70 ; 3B48 C1 99 87 0F 18 78 70 70  .....xpp
        .byte   $FC,$F3,$10,$B1,$8C,$8C,$31,$7C ; 3B50 FC F3 10 B1 8C 8C 31 7C  ......1|
        .byte   $70,$E1,$86,$3C,$64,$6C,$B0,$E1 ; 3B58 70 E1 86 3C 64 6C B0 E1  p..<dl..
        .byte   $E3,$0F,$23,$8F,$0F,$1E,$3E,$38 ; 3B60 E3 0F 23 8F 0F 1E 3E 38  ..#...>8
        .byte   $3C,$38,$7B,$8F,$07,$0E,$3C,$F4 ; 3B68 3C 38 7B 8F 07 0E 3C F4  <8{...<.
        .byte   $17,$1E,$3C,$78,$F2,$9E,$72,$49 ; 3B70 17 1E 3C 78 F2 9E 72 49  ..<x..rI
        .byte   $E3,$25,$36,$38,$58,$39,$E2,$DE ; 3B78 E3 25 36 38 58 39 E2 DE  .%68X9..
        .byte   $3C,$78,$78,$E1,$C7,$61,$E1,$E1 ; 3B80 3C 78 78 E1 C7 61 E1 E1  <xx..a..
        .byte   $B0,$F0,$F0,$C3,$C7,$0E,$38,$C0 ; 3B88 B0 F0 F0 C3 C7 0E 38 C0  ......8.
        .byte   $F0,$CE,$73,$73,$18,$34,$B0,$E1 ; 3B90 F0 CE 73 73 18 34 B0 E1  ..ss.4..
        .byte   $C7,$8E,$1C,$3C,$F8,$38,$F0,$E1 ; 3B98 C7 8E 1C 3C F8 38 F0 E1  ...<.8..
        .byte   $C1,$8B,$86,$8F,$1C,$78,$70,$F0 ; 3BA0 C1 8B 86 8F 1C 78 70 F0  .....xp.
        .byte   $78,$AC,$B1,$8F,$39,$31,$DB,$38 ; 3BA8 78 AC B1 8F 39 31 DB 38  x...91.8
        .byte   $61,$C3,$0E,$0E,$38,$78,$73,$17 ; 3BB0 61 C3 0E 0E 38 78 73 17  a...8xs.
        .byte   $1E,$39,$1E,$38,$64,$E1,$F1,$C1 ; 3BB8 1E 39 1E 38 64 E1 F1 C1  .9.8d...
        .byte   $4E,$0F,$40,$A2,$02,$C5,$8F,$81 ; 3BC0 4E 0F 40 A2 02 C5 8F 81  N.@.....
        .byte   $A1,$FC,$12,$08,$64,$E0,$3C,$22 ; 3BC8 A1 FC 12 08 64 E0 3C 22  ....d.<"
        .byte   $E0,$45,$07,$8E,$0C,$32,$90,$F0 ; 3BD0 E0 45 07 8E 0C 32 90 F0  .E...2..
        .byte   $1F,$20,$49,$E0,$F8,$0C,$60,$F0 ; 3BD8 1F 20 49 E0 F8 0C 60 F0  . I...`.
        .byte   $17,$1A,$41,$AA,$A4,$D0,$8D,$12 ; 3BE0 17 1A 41 AA A4 D0 8D 12  ..A.....
        .byte   $82,$1E,$1E,$03,$F8,$3E,$03,$0C ; 3BE8 82 1E 1E 03 F8 3E 03 0C  .....>..
        .byte   $73,$80,$70,$44,$26,$03,$24,$E1 ; 3BF0 73 80 70 44 26 03 24 E1  s.pD&.$.
        .byte   $3E,$04,$4E,$04,$1C,$C1,$09,$CC ; 3BF8 3E 04 4E 04 1C C1 09 CC  >.N.....
        .byte   $9E,$90,$21,$07,$90,$43,$64,$C0 ; 3C00 9E 90 21 07 90 43 64 C0  ..!..Cd.
        .byte   $0F,$C6,$90,$9C,$C1,$5B,$03,$E2 ; 3C08 0F C6 90 9C C1 5B 03 E2  .....[..
        .byte   $1D,$81,$E0,$5E,$1D,$03,$84,$B8 ; 3C10 1D 81 E0 5E 1D 03 84 B8  ...^....
        .byte   $2C,$0F,$80,$B1,$83,$E0,$30,$41 ; 3C18 2C 0F 80 B1 83 E0 30 41  ,.....0A
        .byte   $1E,$43,$89,$83,$50,$FC,$24,$2E ; 3C20 1E 43 89 83 50 FC 24 2E  .C..P.$.
        .byte   $13,$83,$F1,$7C,$4C,$2C,$C9,$0D ; 3C28 13 83 F1 7C 4C 2C C9 0D  ...|L,..
        .byte   $83,$B0,$B5,$82,$E4,$E8,$06,$9C ; 3C30 83 B0 B5 82 E4 E8 06 9C  ........
        .byte   $07,$A0,$99,$1D,$07,$3E,$82,$8F ; 3C38 07 A0 99 1D 07 3E 82 8F  .....>..
        .byte   $70,$30,$74,$40,$CA,$10,$E4,$E8 ; 3C40 70 30 74 40 CA 10 E4 E8  p0t@....
        .byte   $0F,$92,$14,$3F,$06,$F8,$84,$88 ; 3C48 0F 92 14 3F 06 F8 84 88  ...?....
        .byte   $43,$81,$0A,$34,$39,$41,$C6,$E3 ; 3C50 43 81 0A 34 39 41 C6 E3  C..49A..
        .byte   $1C,$47,$03,$B0,$B8,$13,$0A,$C2 ; 3C58 1C 47 03 B0 B8 13 0A C2  .G......
        .byte   $64,$F8,$18,$F9,$60,$B3,$C0,$65 ; 3C60 64 F8 18 F9 60 B3 C0 65  d...`..e
        .byte   $20,$60,$A6,$8C,$C3,$81,$20,$30 ; 3C68 20 60 A6 8C C3 81 20 30   `.... 0
        .byte   $26,$1E,$1C,$38,$D3,$01,$B0,$26 ; 3C70 26 1E 1C 38 D3 01 B0 26  &..8...&
        .byte   $40,$F4,$0B,$C3,$42,$1F,$85,$32 ; 3C78 40 F4 0B C3 42 1F 85 32  @...B..2
        .byte   $26,$60,$40,$C9,$CB,$01,$EC,$11 ; 3C80 26 60 40 C9 CB 01 EC 11  &`@.....
        .byte   $28,$40,$FA,$04,$34,$E0,$70,$4C ; 3C88 28 40 FA 04 34 E0 70 4C  (@..4.pL
        .byte   $8C,$1D,$07,$69,$03,$16,$C8,$04 ; 3C90 8C 1D 07 69 03 16 C8 04  ...i....
        .byte   $23,$E8,$C6,$9A,$0B,$1A,$03,$E0 ; 3C98 23 E8 C6 9A 0B 1A 03 E0  #.......
        .byte   $76,$06,$05,$CF,$1E,$BC,$58,$31 ; 3CA0 76 06 05 CF 1E BC 58 31  v.....X1
        .byte   $71,$66,$00,$F8,$3F,$04,$FC,$0C ; 3CA8 71 66 00 F8 3F 04 FC 0C  qf..?...
        .byte   $74,$27,$8A,$80,$71,$C2,$3A,$26 ; 3CB0 74 27 8A 80 71 C2 3A 26  t'..q.:&
        .byte   $06,$C0,$1F,$05,$0F,$98,$40,$AE ; 3CB8 06 C0 1F 05 0F 98 40 AE  ......@.
        .byte   $01,$7F,$C0,$07,$FF,$00,$0E,$FE ; 3CC0 01 7F C0 07 FF 00 0E FE  ........
        .byte   $00,$03,$DF,$80,$03,$EF,$80,$1B ; 3CC8 00 03 DF 80 03 EF 80 1B  ........
        .byte   $F1,$C2,$00,$E7,$E0,$18,$FC,$E0 ; 3CD0 F1 C2 00 E7 E0 18 FC E0  ........
        .byte   $21,$FC,$80,$3C,$FC,$40,$0E,$7E ; 3CD8 21 FC 80 3C FC 40 0E 7E  !..<.@.~
        .byte   $00,$3F,$3E,$00,$0F,$FE,$00,$1F ; 3CE0 00 3F 3E 00 0F FE 00 1F  .?>.....
        .byte   $FF,$00,$3E,$F0,$07,$FC,$00,$7E ; 3CE8 FF 00 3E F0 07 FC 00 7E  ..>....~
        .byte   $10,$3F,$FF,$00,$3F,$38,$0E,$7C ; 3CF0 10 3F FF 00 3F 38 0E 7C  .?..?8.|
        .byte   $01,$87,$0C,$FC,$C7,$00,$3E,$04 ; 3CF8 01 87 0C FC C7 00 3E 04  ......>.
        .byte   $0F,$3E,$1F,$0F,$0F,$1F,$0F,$02 ; 3D00 0F 3E 1F 0F 0F 1F 0F 02  .>......
        .byte   $83,$87,$CF,$03,$87,$0F,$3F,$C0 ; 3D08 83 87 CF 03 87 0F 3F C0  ......?.
        .byte   $07,$9E,$60,$3F,$C0,$03,$FE,$00 ; 3D10 07 9E 60 3F C0 03 FE 00  ..`?....
        .byte   $3F,$E0,$77,$E1,$C0,$FE,$E0,$C3 ; 3D18 3F E0 77 E1 C0 FE E0 C3  ?.w.....
        .byte   $E0,$01,$DF,$F8,$03,$07,$00,$7E ; 3D20 E0 01 DF F8 03 07 00 7E  .......~
        .byte   $70,$00,$7C,$38,$18,$FE,$0C,$1E ; 3D28 70 00 7C 38 18 FE 0C 1E  p.|8....
        .byte   $78,$1C,$7C,$3E,$0E,$1F,$1E,$1E ; 3D30 78 1C 7C 3E 0E 1F 1E 1E  x.|>....
        .byte   $3E,$00,$7F,$83,$07,$DB,$87,$83 ; 3D38 3E 00 7F 83 07 DB 87 83  >.......
        .byte   $07,$C7,$07,$10,$71,$FF,$00,$3F ; 3D40 07 C7 07 10 71 FF 00 3F  ....q..?
        .byte   $E2,$01,$E0,$C1,$C3,$E1,$00,$7F ; 3D48 E2 01 E0 C1 C3 E1 00 7F  ........
        .byte   $C0,$05,$F0,$20,$F8,$F0,$70,$FE ; 3D50 C0 05 F0 20 F8 F0 70 FE  ... ..p.
        .byte   $78,$79,$F8,$02,$3F,$0C,$8F,$03 ; 3D58 78 79 F8 02 3F 0C 8F 03  xy..?...
        .byte   $0F,$9F,$E0,$C1,$C7,$87,$03,$C3 ; 3D60 0F 9F E0 C1 C7 87 03 C3  ........
        .byte   $C3,$B0,$E1,$E1,$C1,$E3,$E0,$71 ; 3D68 C3 B0 E1 E1 C1 E3 E0 71  .......q
        .byte   $F0,$00,$FC,$70,$7C,$0C,$3E,$38 ; 3D70 F0 00 FC 70 7C 0C 3E 38  ...p|.>8
        .byte   $0E,$1C,$70,$C3,$C7,$03,$81,$C1 ; 3D78 0E 1C 70 C3 C7 03 81 C1  ..p.....
        .byte   $C7,$E7,$00,$0F,$C7,$87,$19,$09 ; 3D80 C7 E7 00 0F C7 87 19 09  ........
        .byte   $EF,$C4,$33,$E0,$C1,$FC,$F8,$70 ; 3D88 EF C4 33 E0 C1 FC F8 70  ..3....p
        .byte   $F0,$78,$F8,$F0,$61,$C7,$00,$1F ; 3D90 F0 78 F8 F0 61 C7 00 1F  .x..a...
        .byte   $F8,$01,$7C,$F8,$F0,$78,$70,$3C ; 3D98 F8 01 7C F8 F0 78 70 3C  ..|..xp<
        .byte   $7C,$CE,$0E,$21,$83,$CF,$08,$07 ; 3DA0 7C CE 0E 21 83 CF 08 07  |..!....
        .byte   $8F,$08,$C1,$87,$8F,$80,$C7,$E3 ; 3DA8 8F 08 C1 87 8F 80 C7 E3  ........
        .byte   $00,$07,$F8,$E0,$EF,$00,$39,$F7 ; 3DB0 00 07 F8 E0 EF 00 39 F7  ......9.
        .byte   $80,$0E,$F8,$E1,$E3,$F8,$21,$9F ; 3DB8 80 0E F8 E1 E3 F8 21 9F  ......!.
        .byte   $C0,$FF,$03,$F8,$07,$C0,$1F,$F8 ; 3DC0 C0 FF 03 F8 07 C0 1F F8  ........
        .byte   $C4,$04,$FC,$C4,$C1,$BC,$87,$F0 ; 3DC8 C4 04 FC C4 C1 BC 87 F0  ........
        .byte   $0F,$C0,$7F,$05,$E0,$25,$EC,$C0 ; 3DD0 0F C0 7F 05 E0 25 EC C0  .....%..
        .byte   $3E,$84,$47,$F0,$8E,$03,$F8,$03 ; 3DD8 3E 84 47 F0 8E 03 F8 03  >.G.....
        .byte   $FB,$C0,$19,$F8,$07,$9C,$0C,$17 ; 3DE0 FB C0 19 F8 07 9C 0C 17  ........
        .byte   $F8,$07,$E0,$1F,$A1,$FC,$0F,$FC ; 3DE8 F8 07 E0 1F A1 FC 0F FC  ........
        .byte   $01,$F0,$3F,$00,$FE,$03,$F0,$1F ; 3DF0 01 F0 3F 00 FE 03 F0 1F  ..?.....
        .byte   $00,$FD,$00,$FF,$88,$0D,$F9,$01 ; 3DF8 00 FD 00 FF 88 0D F9 01  ........
        .byte   $FF,$00,$70,$07,$C0,$3E,$42,$F3 ; 3E00 FF 00 70 07 C0 3E 42 F3  ..p..>B.
        .byte   $0D,$C4,$7F,$80,$FC,$07,$F0,$5E ; 3E08 0D C4 7F 80 FC 07 F0 5E  .......^
        .byte   $C0,$3F,$00,$78,$3F,$81,$FF,$01 ; 3E10 C0 3F 00 78 3F 81 FF 01  .?.x?...
        .byte   $F8,$01,$C3,$E8,$0C,$E4,$64,$8F ; 3E18 F8 01 C3 E8 0C E4 64 8F  ......d.
        .byte   $E4,$0F,$F0,$07,$F0,$C2,$1F,$00 ; 3E20 E4 0F F0 07 F0 C2 1F 00  ........
        .byte   $7F,$C0,$6F,$80,$7E,$03,$F8,$07 ; 3E28 7F C0 6F 80 7E 03 F8 07  ..o.~...
        .byte   $F0,$3F,$C0,$78,$0F,$82,$07,$FE ; 3E30 F0 3F C0 78 0F 82 07 FE  .?.x....
        .byte   $22,$77,$70,$02,$76,$03,$FE,$00 ; 3E38 22 77 70 02 76 03 FE 00  "wp.v...
        .byte   $FE,$67,$00,$7C,$C7,$F1,$8E,$C6 ; 3E40 FE 67 00 7C C7 F1 8E C6  .g.|....
        .byte   $3B,$E0,$3F,$84,$F3,$19,$D8,$03 ; 3E48 3B E0 3F 84 F3 19 D8 03  ;.?.....
        .byte   $99,$FC,$09,$B8,$0F,$F8,$00,$9D ; 3E50 99 FC 09 B8 0F F8 00 9D  ........
        .byte   $24,$61,$F9,$0D,$00,$FD,$03,$F0 ; 3E58 24 61 F9 0D 00 FD 03 F0  $a......
        .byte   $1F,$90,$3F,$01,$F8,$1F,$D0,$0F ; 3E60 1F 90 3F 01 F8 1F D0 0F  ..?.....
        .byte   $F8,$37,$01,$F8,$07,$F0,$0F,$C0 ; 3E68 F8 37 01 F8 07 F0 0F C0  .7......
        .byte   $3F,$00,$FE,$03,$F8,$0F,$C0,$3F ; 3E70 3F 00 FE 03 F8 0F C0 3F  ?......?
        .byte   $00,$FA,$03,$F0,$0F,$80,$FF,$01 ; 3E78 00 FA 03 F0 0F 80 FF 01  ........
        .byte   $B8,$07,$F0,$01,$FC,$01,$BC,$80 ; 3E80 B8 07 F0 01 FC 01 BC 80  ........
        .byte   $13,$1E,$00,$7F,$E1,$40,$7F,$A0 ; 3E88 13 1E 00 7F E1 40 7F A0  .....@..
        .byte   $7F,$B0,$00,$3F,$C0,$1F,$C0,$38 ; 3E90 7F B0 00 3F C0 1F C0 38  ...?...8
        .byte   $0F,$F0,$1F,$80,$FF,$01,$FC,$03 ; 3E98 0F F0 1F 80 FF 01 FC 03  ........
        .byte   $F1,$7E,$01,$FE,$01,$F0,$FF,$00 ; 3EA0 F1 7E 01 FE 01 F0 FF 00  .~......
        .byte   $7F,$C0,$1D,$07,$F0,$0F,$C0,$7E ; 3EA8 7F C0 1D 07 F0 0F C0 7E  .......~
        .byte   $06,$E0,$07,$E0,$0F,$F8,$06,$C1 ; 3EB0 06 E0 07 E0 0F F8 06 C1  ........
        .byte   $FE,$01,$FC,$03,$E0,$0F,$00,$FC ; 3EB8 FE 01 FC 03 E0 0F 00 FC  ........
D3EC0:  .byte   $24,$07,$13,$34,$14,$01,$FF,$38 ; 3EC0 24 07 13 34 14 01 FF 38  $..4...8
        .byte   $17,$07,$21,$0A,$1C,$1C,$FF,$23 ; 3EC8 17 07 21 0A 1C 1C FF 23  ..!....#
        .byte   $0A,$20,$31,$15,$26,$0F,$04,$FF ; 3ED0 0A 20 31 15 26 0F 04 FF  . 1.&...
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3ED8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3EE0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3EE8 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3EF0 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00                 ; 3EF8 00 00 00 00              ....
D3EFC:  .byte   $04,$03,$00,$00,$00,$00,$00,$00 ; 3EFC 04 03 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3F04 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3F0C 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3F14 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3F1C 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3F24 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3F2C 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00                 ; 3F34 00 00 00 00              ....
D3F38:  .byte   $02,$0B,$09,$0E,$0D,$12,$01,$02 ; 3F38 02 0B 09 0E 0D 12 01 02  ........
        .byte   $05,$08,$02,$08,$07,$05,$07,$02 ; 3F40 05 08 02 08 07 05 07 02  ........
        .byte   $06,$02,$0C,$09,$06,$11,$08,$00 ; 3F48 06 02 0C 09 06 11 08 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3F50 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3F58 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3F60 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 3F68 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00                 ; 3F70 00 00 00 00              ....

D3F74_GAIN:  .byte   0,1,2,2,2,3,3,4,4,5,6,8,9,11,13,15 ; 4-bit sample gain curve.

D3F84:  .byte   $00,$00,$E0,$E6,$EC,$F3,$F9,$00 ; 3F84 00 00 E0 E6 EC F3 F9 00  ........
        .byte   $06,$0C,$06                     ; 3F8C 06 0C 06                 ...

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

SMC4210 := * + 1                                ; Self-modifying code: argument of ldx #imm below.

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
        lda     #$39                            ;
        adc     ZP_F5                           ; SIDNEY
        sta     ZP_EB_PTR_HI                    ;
        lda     #$C0                            ;
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

SMC42B0 := * + 1                                ; Self-modifying code: argument of ldx #imm below.

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

SMC42DF := * + 1                                ; Self-modifying code: argument of ldx #imm below.

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

        ; Seems unused. Probably garbage.

        .byte   $A9,$00,$00,$00,$00,$00,$00,$00 ; 4560 A9 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 4568 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 4570 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; 4578 00 00 00 00 00 00 00 00  ........
        .byte   $00,$00,$00,$00,$00,$00         ; 4580 00 00 00 00 00 00        ......

; ----------------------------------------------------------------------------

        ; The "MEMLO" variable is reset to here.
        ; Whatever follows is probably garbage.

D4586:  .byte                           $00,$00 ; 4586                   00 00        ..
        .byte   $42,$01,$78,$03,$00,$00,$00,$00 ; 4588 42 01 78 03 00 00 00 00  B.x.....

; ----------------------------------------------------------------------------

D4590:  ; This is where the reciter executable image starts.
        ; The data below is probably garbage.

        .byte   $41,$81,$92,$00,$00,$00,$30,$2E
        .byte   $30,$16,$00,$00,$14,$27,$2A,$1C
        .byte   $0E,$40,$01,$00,$00,$00,$00,$12
        .byte   $46,$3A,$80,$2C,$14,$2B,$09,$80
        .byte   $16

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
