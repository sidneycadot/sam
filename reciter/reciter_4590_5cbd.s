
; Source code for SAM reciter.
;
; The "reciter" program performs English-to-Phonemes translation.

        .setcpu "6502"

; ----------------------------------------------------------------------------

SAM_211F        := $211F
SAM_21B7        := $21B7
SAM_3FC0        := $3FC0
SAM_452D        := $452D

; ----------------------------------------------------------------------------

        .segment "BLOCK1_HEADER": absolute

        ; This is the Atari executable header for the first block.

        .word $ffff
        .word $4590
        .word $5cbd

        .segment "BLOCK1": absolute

L4590:  .res 256, 0

        .byte "COPYRIGHT 1982 DON'T ASK"

L46A8:  .res 32, 0

        .byte   $00,$02,$02,$02,$02,$02,$02,$82 ; 46C8 00 02 02 02 02 02 02 82
        .byte   $00,$00,$02,$02,$02,$02,$02,$02 ; 46D0 00 00 02 02 02 02 02 02
        .byte   $03,$03,$03,$03,$03,$03,$03,$03 ; 46D8 03 03 03 03 03 03 03 03
        .byte   $03,$03,$02,$02,$02,$02,$02,$02 ; 46E0 03 03 02 02 02 02 02 02
        .byte   $02,$C0,$A8,$B0,$AC,$C0,$A0,$B8 ; 46E8 02 C0 A8 B0 AC C0 A0 B8
        .byte   $A0,$C0,$BC,$A0,$AC,$A8,$AC,$C0 ; 46F0 A0 C0 BC A0 AC A8 AC C0
        .byte   $A0,$A0,$AC,$B4,$A4,$C0,$A8,$A8 ; 46F8 A0 A0 AC B4 A4 C0 A8 A8
        .byte   $B0,$C0,$BC,$00,$00,$00,$02,$00 ; 4700 B0 C0 BC 00 00 00 02 00

; ----------------------------------------------------------------------------

        jsr     SAM_21B7                        ; Call subroutine in SAM.
        jsr     SAM_3FC0                        ; Call subroutine in SAM.
        lda     #$20                            ;
        sta     L4590                           ;
        ldx     #$01                            ;
        ldy     #$00                            ;
L4717:  lda     $2014,y                         ;
        and     #$7F                            ;
        cmp     #$70                            ;
        bcc     L4725                           ;
        and     #$5F                            ;
        jmp     L472B                           ;

; ----------------------------------------------------------------------------

L4725:  cmp     #$60                            ;
        bcc     L472B                           ;
        and     #$4F                            ;
L472B:  sta     L4590,x                         ;
        inx                                     ;
        iny                                     ;
        cpy     #$FF                            ;
        bne     L4717                           ;
        ldx     #$FF                            ;
        lda     #$1B                            ;
        sta     L4590,x                         ;
        jsr     L4742                           ;
L473E:  jsr     SAM_211F                        ; Call subroutine in SAM.
        rts                                     ;

; ----------------------------------------------------------------------------

L4742:  lda     #$FF                            ;
        sta     $FA                             ;
L4746:  lda     #$FF                            ;
        sta     $F5                             ;
L474A:  inc     $FA                             ;
        ldx     $FA                             ;
        lda     L4590,x                         ;
        sta     $FD                             ;
        cmp     #$1B                            ; Compare to the escape character.
        bne     L4761                           ;
        inc     $F5                             ;
        ldx     $F5                             ;
        lda     #$9B                            ; Load end-of-line character.
        sta     $2014,x                         ;
        rts                                     ;

; ----------------------------------------------------------------------------

L4761:  cmp     #'.'                            ;
        bne     L477D                           ;
        inx                                     ;
        lda     L4590,x                         ;
        tay                                     ;
        lda     L46A8,y                         ;
        and     #$01                            ;
        bne     L477D                           ;
        inc     $F5                             ;
        ldx     $F5                             ;
        lda     #$2E                            ;
        sta     $2014,x                         ;
        jmp     L474A                           ;

; ----------------------------------------------------------------------------

L477D:  lda     $FD                             ;
        tay                                     ;
        lda     L46A8,y                         ;
        sta     $F6                             ;
        and     #$02                            ;
        beq     L4794                           ;
        lda     #<PTAB                          ;
        sta     $FB                             ;
        lda     #>PTAB                          ;
        sta     $FC                             ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4794:  lda     $F6                             ;
        bne     L47C3                           ;
        lda     #$20                            ;
        sta     L4590,x                         ;
        inc     $F5                             ;
        ldx     $F5                             ;
        cpx     #$78                            ;
        bcs     L47AC                           ;
        sta     $2014,x                         ;
        jmp     L474A                           ;

; ----------------------------------------------------------------------------

SAVE_FA: .byte 0                                ; Temporary storage for $FA.

L47AC:  lda     #$9B                            ;
        sta     $2014,x                         ;
        lda     $FA                             ;
        sta     SAVE_FA                         ;
        sta     $CD                             ;
        jsr     L473E                           ;
        lda     SAVE_FA                         ;
        sta     $FA                             ;
        jmp     L4746                           ;

; ----------------------------------------------------------------------------

L47C3:  lda     $F6                             ;
        and     #$80                            ;
        bne     L47CA                           ;
        brk                                     ;
L47CA:  lda     $FD                             ;
        sec                                     ;
        sbc     #'A'                            ;
        tax                                     ;
        lda     PTAB_INDEX_LO,x                 ;
        sta     $FB                             ; 
        lda     PTAB_INDEX_HI,x                 ;
        sta     $FC                             ;

        ; Pattern matching loop.

L47DA:  ldy     #0                              ;
@1:     clc                                     ; Increment pointer $FB by one.
        lda     $FB                             ;
        adc     #<1                             ;
        sta     $FB                             ;
        lda     $FC                             ;
        adc     #>1                             ;
        sta     $FC                             ;
        lda     ($FB),y                         ; load byte.
        bpl     @1                              ; repeat increment until the value has most significant bit.
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
@3:     lda     L4590,x                         ;
        sta     $F6                             ;
        lda     ($FB),y                         ;
        cmp     $F6                             ;
        beq     @4                              ;
        jmp     L47DA                           ;

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
        lda     L46A8,x                         ;
        and     #$80                            ;
        beq     L485F                           ;
        ldx     $F8                             ;
        dex                                     ;
        lda     L4590,x                         ;
        cmp     $F6                             ;
        beq     L485A                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L485A:  stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

L485F:  lda     $F6                             ;
        cmp     #' '                            ;
        bne     @1                              ;
        jmp     L489D                           ;
@1:     cmp     #'#'                            ;
        bne     @2                              ;
        jmp     L48AC                           ;
@2:     cmp     #'.'                            ;
        bne     @3                              ;
        jmp     L48B6                           ;
@3:     cmp     #'&'                            ;
        bne     @4                              ;
        jmp     L48C5                           ;
@4:     cmp     #'@'                            ;
        bne     @5                              ;
        jmp     L48E5                           ;
@5:     cmp     #'^'                            ;
        bne     @6                              ;
        jmp     L490A                           ;
@6:     cmp     #'+'                            ;
        bne     @7                              ;
        jmp     L4919                           ;
@7:     cmp     #':'                            ;
        bne     L4899                           ;
        jmp     L492E                           ;

; ----------------------------------------------------------------------------

L4899:  jsr     SAM_452D                        ; Call subroutine in SAM.
        brk                                     ; Yikes, let's hope we never return.

; ----------------------------------------------------------------------------

L489D:  jsr     L493D                           ;
        and     #$80                            ;
        beq     L48A7                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L48A7:  stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

L48AC:  jsr     L493D                           ;
        and     #$40                            ;
        bne     L48A7                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L48B6:  jsr     L493D                           ;
        and     #$08                            ;
        bne     L48C0                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L48C0:  stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

L48C5:  jsr     L493D                           ;
        and     #$10                            ;
        bne     L48C0                           ;
        lda     L4590,x                         ;
        cmp     #'H'                            ;
        beq     L48D6                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L48D6:  dex                                     ;
        lda     L4590,x                         ;
        cmp     #'C'                            ;
        beq     L48C0                           ;
        cmp     #'S'                            ;
        beq     L48C0                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L48E5:  jsr     L493D                           ;
        and     #$04                            ;
        bne     L48C0                           ;
        lda     L4590,x                         ;
        cmp     #'H'                            ;
        beq     L48F6                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L48F6:  cmp     #'T'                            ;
        beq     L4905                           ;
        cmp     #'C'                            ;
        beq     L4905                           ;
        cmp     #'S'                            ;
        beq     L4905                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4905:  stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

L490A:  jsr     L493D                           ;
        and     #$20                            ;
        bne     L4914                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4914:  stx     $F8                             ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

L4919:  ldx     $F8                             ;
        dex                                     ;
        lda     L4590,x                         ;
        cmp     #'E'                            ;
        beq     L4914                           ;
        cmp     #'I'                            ;
        beq     L4914                           ;
        cmp     #'Y'                            ;
        beq     L4914                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L492E:  jsr     L493D                           ;
        and     #$20                            ;
        bne     L4938                           ;
        jmp     L4835                           ;

; ----------------------------------------------------------------------------

L4938:  stx     $F8                             ;
        jmp     L492E                           ;

; ----------------------------------------------------------------------------

L493D:  ldx     $F8                             ;
        dex                                     ;
        lda     L4590,x                         ;
        tay                                     ;
        lda     L46A8,y                         ;
        rts                                     ;

; ----------------------------------------------------------------------------

L4948:  ldx     $F7                             ;
        inx                                     ;
        lda     L4590,x                         ;
        tay                                     ;
        lda     L46A8,y                         ;
        rts                                     ;

; ----------------------------------------------------------------------------

L4953:  ldx     $F7                             ;
        inx                                     ;
        lda     L4590,x                         ;
        cmp     #'E'                            ;
        bne     L49A3                           ;
        inx                                     ;
        lda     L4590,x                         ;
        tay                                     ;
        dex                                     ;
        lda     L46A8,y                         ;
        and     #$80                            ;
        beq     L4972                           ;
        inx                                     ;
        lda     L4590,x                         ;
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
        lda     L4590,x                         ;
        cmp     #'Y'                            ;
        bne     L49B7                           ;
        beq     L4972                           ;
L498D:  cmp     #'F'                            ;
        bne     L49B7                           ;
        inx                                     ;
        lda     L4590,x                         ;
        cmp     #'U'                            ;
        bne     L49B7                           ;
        inx                                     ;
        lda     L4590,x                         ;
        cmp     #'L'                            ;
        beq     L4972                           ;
        bne     L49B7                           ;
L49A3:  cmp     #'I'                            ;
        bne     L49B7                           ;
        inx                                     ;
        lda     L4590,x                         ;
        cmp     #'N'                            ;
        bne     L49B7                           ;
        inx                                     ;
        lda     L4590,x                         ;
        cmp     #'G'                            ;
        beq     L4972                           ;
L49B7:  jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L49BA:  lda     $F9                             ;
        sta     $F7                             ;
L49BE:  ldy     $FE                             ;
        iny                                     ;
        cpy     $FD                             ;
        bne     L49C8                           ;
        jmp     L4ACD                           ;

; ----------------------------------------------------------------------------

L49C8:  sty     $FE                             ;
        lda     ($FB),y                         ;
        sta     $F6                             ;
        tax                                     ;
        lda     L46A8,x                         ;
        and     #$80                            ;
        beq     L49E8                           ;
        ldx     $F7                             ;
        inx                                     ;
        lda     L4590,x                         ;
        cmp     $F6                             ;
        beq     L49E3                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L49E3:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

L49E8:  lda     $F6                             ;
        cmp     #' '                            ;
        bne     @1                              ;
        jmp     L4A2D                           ;
@1:     cmp     #'#'                            ;
        bne     @2                              ;
        jmp     L4A3C                           ;
@2:     cmp     #'.'                            ;
        bne     @3                              ;
        jmp     L4A46                           ;
@3:     cmp     #'&'                            ;
        bne     @4                              ;
        jmp     L4A55                           ;
@4:     cmp     #'@'                            ;
        bne     @5                              ;
        jmp     L4A75                           ;
@5:      cmp     #'^'                           ;
        bne     @6                              ;
        jmp     L4A9A                           ;
@6:     cmp     #'+'                            ;
        bne     @7                              ;
        jmp     L4AA9                           ;
@7:     cmp     #':'                            ;
        bne     @8                              ;
        jmp     L4ABE                           ;
@8:     cmp     #'%'                            ;
        bne     L4A29                           ;
        jmp     L4953                           ;

; ----------------------------------------------------------------------------

L4A29:  jsr     SAM_452D                        ; Call subroutine in SAM.
        brk                                     ; Yikes, let's hope we never return.

; ----------------------------------------------------------------------------

L4A2D:  jsr     L4948                           ;
        and     #$80                            ;
        beq     L4A37                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4A37:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

L4A3C:  jsr     L4948                           ;
        and     #$40                            ;
        bne     L4A37                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4A46:  jsr     L4948                           ;
        and     #$08                            ;
        bne     L4A50                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4A50:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

L4A55:  jsr     L4948                           ;
        and     #$10                            ;
        bne     L4A50                           ;
        lda     L4590,x                         ;
        cmp     #'H'                            ;
        beq     L4A66                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------
L4A66:  inx                                     ;
        lda     L4590,x                         ;
        cmp     #'C'                            ;
        beq     L4A50                           ;
        cmp     #'S'                            ;
        beq     L4A50                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4A75:  jsr     L4948                           ;
        and     #$04                            ;
        bne     L4A50                           ;
        lda     L4590,x                         ;
        cmp     #'H'                            ;
        beq     L4A86                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4A86:  cmp     #'T'                            ;
        beq     L4A95                           ;
        cmp     #'C'                            ;
        beq     L4A95                           ;
        cmp     #'S'                            ;
        beq     L4A95                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4A95:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

L4A9A:  jsr     L4948                           ;
        and     #$20                            ;
        bne     L4AA4                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4AA4:  stx     $F7                             ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

L4AA9:  ldx     $F7                             ;
        inx                                     ;
        lda     L4590,x                         ;
        cmp     #'E'                            ;
        beq     L4AA4                           ;
        cmp     #'I'                            ;
        beq     L4AA4                           ;
        cmp     #'Y'                            ;
        beq     L4AA4                           ;
        jmp     L47DA                           ;

; ----------------------------------------------------------------------------

L4ABE:  jsr     L4948                           ;
        and     #$20                            ;
        bne     L4AC8                           ;
        jmp     L49BE                           ;

; ----------------------------------------------------------------------------

L4AC8:  stx     $F7                             ;
        jmp     L4ABE                           ;

; ----------------------------------------------------------------------------

L4ACD:  ldy     $FD                             ;
        lda     $F9                             ;
        sta     $FA                             ;
L4AD3:  lda     ($FB),y                         ;
        sta     $F6                             ;
        and     #$7F                            ;
        cmp     #'='                            ;
        beq     L4AE4                           ;
        inc     $F5                             ;
        ldx     $F5                             ;
        sta     $2014,x                         ;
L4AE4:  bit     $F6                             ;
        bpl     L4AEB                           ;
        jmp     L474A                           ;

; ----------------------------------------------------------------------------

L4AEB:  iny                                     ;
        jmp     L4AD3                           ;

; ----------------------------------------------------------------------------

PTAB_INDEX_LO:

        .lobytes   $4CE0,$4E75,$4ED7,$4F6B,$5008,$518E,$51CF,$5247,$5290,$53EF,$5400,$5417,$545A
        .lobytes   $54BA,$551E,$576C,$57CC,$57F2,$5813,$58FC,$5A77,$5B06,$5B23,$5BFE,$5C17,$5CAB

PTAB_INDEX_HI:

        .hibytes   $4CE0,$4E75,$4ED7,$4F6B,$5008,$518E,$51CF,$5247,$5290,$53EF,$5400,$5417,$545A
        .hibytes   $54BA,$551E,$576C,$57CC,$57F2,$5813,$58FC,$5A77,$5B06,$5B23,$5BFE,$5C17,$5CAB

; ----------------------------------------------------------------------------

        ; This is the startup code.
        ; RUNAD will point here after opening the file, so exection starts here.

_start: lda     #<(END_OF_BLOCK1 - 2)
        sta     $2E7
        sta     $864
        lda     #>(END_OF_BLOCK1 - 2)
        sta     $2E8
        sta     $869
        lda     #0
        sta     $08
        rts

; ----------------------------------------------------------------------------

        ; List of the 468 pronunciation rules.

        .macro pronunciation_rule Arg
        .repeat .strlen(Arg) - 1, k
        .byte .strat(Arg, k)
        .endrep
        .byte .strat(Arg, .strlen(Arg) - 1) ^ $80
        .endmacro

PTAB:

        pronunciation_rule    "(A)="
        pronunciation_rule    "(!)=."
        .byte   "(",'"',") =-AH5NKWOWT",'-'+$80   ; ca65 strings cannot contain a double quote (0x22) character, so write out pronunciation rule as bytes.
        .byte   "(",'"',")=KWOW4T",'-'+$80        ; ca65 strings cannot contain a double quote (0x22) character, so write out pronunciation rule as bytes.
        pronunciation_rule    "(#)= NAH4MBER"
        pronunciation_rule    "($)= DAA4LER"
        pronunciation_rule    "(%)= PERSEH4NT"
        pronunciation_rule    "(&)= AEND"
        pronunciation_rule    "(')="
        pronunciation_rule    "(*)= AE4STERIHSK"
        pronunciation_rule    "(+)= PLAH4S"
        pronunciation_rule    "(,)=,"
        pronunciation_rule    " (-) =-"
        pronunciation_rule    "(-)="
        pronunciation_rule    "(.)= POYNT"
        pronunciation_rule    "(/)= SLAE4SH"
        pronunciation_rule    "(0)= ZIY4ROW"
        pronunciation_rule    " (1ST)=FER4ST"
        pronunciation_rule    " (10TH)=TEH4NTH"
        pronunciation_rule    "(1)= WAH4N"
        pronunciation_rule    " (2ND)=SEH4KUND"
        pronunciation_rule    "(2)= TUW4"
        pronunciation_rule    " (3RD)=THER4D"
        pronunciation_rule    "(3)= THRIY4"
        pronunciation_rule    "(4)= FOH4R"
        pronunciation_rule    " (5TH)=FIH4FTH"
        pronunciation_rule    "(5)= FAY4V"
        pronunciation_rule    "(6)= SIH4KS"
        pronunciation_rule    "(7)= SEH4VUN"
        pronunciation_rule    " (8TH)=EY4TH"
        pronunciation_rule    "(8)= EY4T"
        pronunciation_rule    "(9)= NAY4N"
        pronunciation_rule    "(:)=."
        pronunciation_rule    "(;)=."
        pronunciation_rule    "(<)= LEH4S DHAEN"
        pronunciation_rule    "(=)= IY4KWULZ"
        pronunciation_rule    "(>)= GREY4TER DHAEN"
        pronunciation_rule    "(?)=."
        pronunciation_rule    "(@)= AE6T"
        pronunciation_rule    "(^)= KAE4RIXT"
        pronunciation_rule    "]A"
        pronunciation_rule    " (A.)=EH4Y. "
        pronunciation_rule    "(A) =AH"
        pronunciation_rule    " (ARE) =AAR"
        pronunciation_rule    " (AR)O=AXR"
        pronunciation_rule    "(AR)#=EH4R"
        pronunciation_rule    " ^(AS)#=EY4S"
        pronunciation_rule    "(A)WA=AX"
        pronunciation_rule    "(AW)=AO5"
        pronunciation_rule    " :(ANY)=EH4NIY"
        pronunciation_rule    "(A)^+#=EY5"
        pronunciation_rule    "#:(ALLY)=ULIY"
        pronunciation_rule    " (AL)#=UL"
        pronunciation_rule    "(AGAIN)=AXGEH4N"
        pronunciation_rule    "#:(AG)E=IHJ"
        pronunciation_rule    "(A)^%=EY"
        pronunciation_rule    "(A)^+:#=AE"
        pronunciation_rule    " :(A)^+ =EY4"
        pronunciation_rule    " (ARR)=AXR"
        pronunciation_rule    "(ARR)=AE4R"
        pronunciation_rule    " ^(AR) =AA5R"
        pronunciation_rule    "(AR)=AA5R"
        pronunciation_rule    "(AIR)=EH4R"
        pronunciation_rule    "(AI)=EY4"
        pronunciation_rule    "(AY)=EY5"
        pronunciation_rule    "(AU)=AO4"
        pronunciation_rule    "#:(AL) =UL"
        pronunciation_rule    "#:(ALS) =ULZ"
        pronunciation_rule    "(ALK)=AO4K"
        pronunciation_rule    "(AL)^=AOL"
        pronunciation_rule    " :(ABLE)=EY4BUL"
        pronunciation_rule    "(ABLE)=AXBUL"
        pronunciation_rule    "(A)VO=EY4"
        pronunciation_rule    "(ANG)+=EY4NJ"
        pronunciation_rule    "(ATARI)=AHTAA4RIY"
        pronunciation_rule    "(A)TOM=AE"
P2:     pronunciation_rule    "(A)TTI=AE"
        pronunciation_rule    " (AT) =AET"
        pronunciation_rule    " (A)T=AH"
        pronunciation_rule    "(A)=AE"
        pronunciation_rule    "]B"
        pronunciation_rule    " (B) =BIY4"
        pronunciation_rule    " (BE)^#=BIH"
        pronunciation_rule    "(BEING)=BIY4IHNX"
        pronunciation_rule    " (BOTH) =BOW4TH"
        pronunciation_rule    " (BUS)#=BIH4Z"
        pronunciation_rule    "(BREAK)=BREY5K"
        pronunciation_rule    "(BUIL)=BIH4L"
        pronunciation_rule    "(B)=B"
        pronunciation_rule    "]C"
        pronunciation_rule    " (C) =SIY4"
        pronunciation_rule    " (CH)^=K"
        pronunciation_rule    "^E(CH)=K"
        pronunciation_rule    "(CHA)R#=KEH5"
        pronunciation_rule    "(CH)=CH"
        pronunciation_rule    " S(CI)#=SAY4"
        pronunciation_rule    "(CI)A=SH"
        pronunciation_rule    "(CI)O=SH"
        pronunciation_rule    "(CI)EN=SH"
        pronunciation_rule    "(CITY)=SIHTIY"
        pronunciation_rule    "(C)+=S"
        pronunciation_rule    "(CK)=K"
        pronunciation_rule    "(COM)=KAHM"
        pronunciation_rule    "(CUIT)=KIHT"
        pronunciation_rule    "(CREA)=KRIYEY"
        pronunciation_rule    "(C)=K"
        pronunciation_rule    "]D"
        pronunciation_rule    " (D) =DIY4"
        pronunciation_rule    " (DR.) =DAA4KTER"
        pronunciation_rule    "#:(DED) =DIHD"
        pronunciation_rule    ".E(D) =D"
        pronunciation_rule    "#:^E(D) =T"
        pronunciation_rule    " (DE)^#=DIH"
        pronunciation_rule    " (DO) =DUW"
        pronunciation_rule    " (DOES)=DAHZ"
        pronunciation_rule    "(DONE) =DAH5N"
        pronunciation_rule    "(DOING)=DUW4IHNX"
        pronunciation_rule    " (DOW)=DAW"
        pronunciation_rule    "#(DU)A=JUW"
        pronunciation_rule    "#(DU)^#=JAX"
        pronunciation_rule    "(D)=D"
        pronunciation_rule    "]E"
        pronunciation_rule    " (E) =IYIY4"
        pronunciation_rule    "#:(E) ="
        pronunciation_rule    "':^(E) ="
        pronunciation_rule    " :(E) =IY"
        pronunciation_rule    "#(ED) =D"
        pronunciation_rule    "#:(E)D ="
        pronunciation_rule    "(EV)ER=EH4V"
        pronunciation_rule    "(E)^%=IY4"
        pronunciation_rule    "(ERI)#=IY4RIY"
        pronunciation_rule    "(ERI)=EH4RIH"
        pronunciation_rule    "#:(ER)#=ER"
        pronunciation_rule    "(ERROR)=EH4ROHR"
        pronunciation_rule    "(ERASE)=IHREY5S"
        pronunciation_rule    "(ER)#=EHR"
        pronunciation_rule    "(ER)=ER"
        pronunciation_rule    " (EVEN)=IYVEHN"
        pronunciation_rule    "#:(E)W="
        pronunciation_rule    "@(EW)=UW"
        pronunciation_rule    "(EW)=YUW"
        pronunciation_rule    "(E)O=IY"
        pronunciation_rule    "#:&(ES) =IHZ"
        pronunciation_rule    "#:(E)S ="
        pronunciation_rule    "#:(ELY) =LIY"
        pronunciation_rule    "#:(EMENT)=MEHNT"
        pronunciation_rule    "(EFUL)=FUHL"
        pronunciation_rule    "(EE)=IY4"
        pronunciation_rule    "(EARN)=ER5N"
        pronunciation_rule    " (EAR)^=ER5"
        pronunciation_rule    "(EAD)=EHD"
        pronunciation_rule    "#:(EA) =IYAX"
        pronunciation_rule    "(EA)SU=EH5"
        pronunciation_rule    "(EA)=IY5"
        pronunciation_rule    "(EIGH)=EY4"
        pronunciation_rule    "(EI)=IY4"
        pronunciation_rule    " (EYE)=AY4"
        pronunciation_rule    "(EY)=IY"
        pronunciation_rule    "(EU)=YUW5"
        pronunciation_rule    "(EQUAL)=IY4KWUL"
        pronunciation_rule    "(E)=EH"
        pronunciation_rule    "]F"
        pronunciation_rule    " (F) =EH4F"
        pronunciation_rule    "(FUL)=FUHL"
        pronunciation_rule    "(FRIEND)=FREH5ND"
        pronunciation_rule    "(FATHER)=FAA4DHER"
        pronunciation_rule    "(F)F="
        pronunciation_rule    "(F)=F"
        pronunciation_rule    "]G"
        pronunciation_rule    " (G) =JIY4"
        pronunciation_rule    "(GIV)=GIH5V"
        pronunciation_rule    " (G)I^=G"
        pronunciation_rule    "(GE)T=GEH5"
        pronunciation_rule    "SU(GGES)=GJEH4S"
        pronunciation_rule    "(GG)=G"
        pronunciation_rule    " B#(G)=G"
        pronunciation_rule    "(G)+=J"
        pronunciation_rule    "(GREAT)=GREY4T"
        pronunciation_rule    "(GON)E=GAO5N"
        pronunciation_rule    "#(GH)="
        pronunciation_rule    " (GN)=N"
        pronunciation_rule    "(G)=G"
        pronunciation_rule    "]H"
        pronunciation_rule    " (H) =EY4CH"
        pronunciation_rule    " (HAV)=/HAE6V"
        pronunciation_rule    " (HERE)=/HIYR"
        pronunciation_rule    " (HOUR)=AW5ER"
        pronunciation_rule    "(HOW)=/HAW"
        pronunciation_rule    "(H)#=/H"
        pronunciation_rule    "(H)="
        pronunciation_rule    "]I"
        pronunciation_rule    " (IN)=IHN"
        pronunciation_rule    " (I) =AY4"
        pronunciation_rule    "(I) =AY"
        pronunciation_rule    "(IN)D=AY5N"
        pronunciation_rule    "SEM(I)=IY"
        pronunciation_rule    " ANT(I)=AY"
        pronunciation_rule    "(IER)=IYER"
        pronunciation_rule    "#:R(IED) =IYD"
        pronunciation_rule    "(IED) =AY5D"
        pronunciation_rule    "(IEN)=IYEHN"
        pronunciation_rule    "(IE)T=AY4EH"
        pronunciation_rule    "(I')=AY5"
        pronunciation_rule    " :(I)^%=AY5"
        pronunciation_rule    " :(IE) =AY4"
        pronunciation_rule    "(I)%=IY"
        pronunciation_rule    "(IE)=IY4"
        pronunciation_rule    " (IDEA)=AYDIY5AH"
        pronunciation_rule    "(I)^+:#=IH"
        pronunciation_rule    "(IR)#=AYR"
        pronunciation_rule    "(IZ)%=AYZ"
        pronunciation_rule    "(IS)%=AYZ"
        pronunciation_rule    "I^(I)^#=IH"
        pronunciation_rule    "+^(I)^+=AY"
        pronunciation_rule    "#:^(I)^+=IH"
        pronunciation_rule    "(I)^+=AY"
        pronunciation_rule    "(IR)=ER"
        pronunciation_rule    "(IGH)=AY4"
        pronunciation_rule    "(ILD)=AY5LD"
        pronunciation_rule    " (IGN)=IHGN"
        pronunciation_rule    "(IGN) =AY4N"
        pronunciation_rule    "(IGN)^=AY4N"
        pronunciation_rule    "(IGN)%=AY4N"
        pronunciation_rule    "(ICRO)=AY4KROH"
        pronunciation_rule    "(IQUE)=IY4K"
        pronunciation_rule    "(I)=IH"
        pronunciation_rule    "]J"
        pronunciation_rule    " (J) =JEY4"
        pronunciation_rule    "(J)=J"
        pronunciation_rule    "]K"
        pronunciation_rule    " (K) =KEY4"
        pronunciation_rule    " (K)N="
        pronunciation_rule    "(K)=K"
        pronunciation_rule    "]L"
        pronunciation_rule    " (L) =EH4L"
        pronunciation_rule    "(LO)C#=LOW"
        pronunciation_rule    "L(L)="
        pronunciation_rule    "#:^(L)%=UL"
        pronunciation_rule    "(LEAD)=LIYD"
        pronunciation_rule    " (LAUGH)=LAE4F"
        pronunciation_rule    "(L)=L"
        pronunciation_rule    "]M"
        pronunciation_rule    " (M) =EH4M"
        pronunciation_rule    " (MR.) =MIH4STER"
        pronunciation_rule    " (MS.)=MIH5Z"
        pronunciation_rule    " (MRS.) =MIH4SIXZ"
        pronunciation_rule    "(MOV)=MUW4V"
        pronunciation_rule    "(MACHIN)=MAHSHIY5N"
        pronunciation_rule    "M(M)="
        pronunciation_rule    "(M)=M"
        pronunciation_rule    "]N"
        pronunciation_rule    " (N) =EH4N"
        pronunciation_rule    "E(NG)+=NJ"
        pronunciation_rule    "(NG)R=NXG"
        pronunciation_rule    "(NG)#=NXG"
        pronunciation_rule    "(NGL)%=NXGUL"
        pronunciation_rule    "(NG)=NX"
        pronunciation_rule    "(NK)=NXK"
        pronunciation_rule    " (NOW) =NAW4"
        pronunciation_rule    "N(N)="
        pronunciation_rule    "(NON)E=NAH4N"
        pronunciation_rule    "(N)=N"
        pronunciation_rule    "]O"
        pronunciation_rule    " (O) =OH4W"
        pronunciation_rule    "(OF) =AHV"
        pronunciation_rule    " (OH) =OW5"
        pronunciation_rule    "(OROUGH)=ER4OW"
        pronunciation_rule    "#:(OR) =ER"
        pronunciation_rule    "#:(ORS) =ERZ"
        pronunciation_rule    "(OR)=AOR"
        pronunciation_rule    " (ONE)=WAHN"
        pronunciation_rule    "#(ONE) =WAHN"
        pronunciation_rule    "(OW)=OW"
        pronunciation_rule    " (OVER)=OW5VER"
        pronunciation_rule    "PR(O)V=UW4"
        pronunciation_rule    "(OV)=AH4V"
        pronunciation_rule    "(O)^%=OW5"
        pronunciation_rule    "(O)^EN=OW"
        pronunciation_rule    "(O)^I#=OW5"
        pronunciation_rule    "(OL)D=OW4L"
        pronunciation_rule    "(OUGHT)=AO5T"
        pronunciation_rule    "(OUGH)=AH5F"
        pronunciation_rule    " (OU)=AW"
        pronunciation_rule    "H(OU)S#=AW4"
        pronunciation_rule    "(OUS)=AXS"
        pronunciation_rule    "(OUR)=OHR"
        pronunciation_rule    "(OULD)=UH5D"
        pronunciation_rule    "(OU)^L=AH5"
        pronunciation_rule    "(OUP)=UW5P"
        pronunciation_rule    "(OU)=AW"
        pronunciation_rule    "(OY)=OY"
        pronunciation_rule    "(OING)=OW4IHNX"
        pronunciation_rule    "(OI)=OY5"
        pronunciation_rule    "(OOR)=OH5R"
        pronunciation_rule    "(OOK)=UH5K"
        pronunciation_rule    "F(OOD)=UW5D"
        pronunciation_rule    "L(OOD)=AH5D"
        pronunciation_rule    "M(OOD)=UW5D"
        pronunciation_rule    "(OOD)=UH5D"
        pronunciation_rule    "F(OOT)=UH5T"
        pronunciation_rule    "(OO)=UW5"
        pronunciation_rule    "(O')=OH"
        pronunciation_rule    "(O)E=OW"
        pronunciation_rule    "(O) =OW"
        pronunciation_rule    "(OA)=OW4"
        pronunciation_rule    " (ONLY)=OW4NLIY"
        pronunciation_rule    " (ONCE)=WAH4NS"
        pronunciation_rule    "(ON'T)=OW4NT"
        pronunciation_rule    "C(O)N=AA"
        pronunciation_rule    "(O)NG=AO"
        pronunciation_rule    " :^(O)N=AH"
        pronunciation_rule    "I(ON)=UN"
        pronunciation_rule    "#:(ON) =UN"
        pronunciation_rule    "#^(ON)=UN"
        pronunciation_rule    "(O)ST =OW"
        pronunciation_rule    "(OF)^=AO4F"
        pronunciation_rule    "(OTHER)=AH5DHER"
        pronunciation_rule    "R(O)B=RAA"
        pronunciation_rule    "^R(O):#=OW5"
        pronunciation_rule    "(OSS) =AO5S"
        pronunciation_rule    "#:^(OM)=AHM"
        pronunciation_rule    "(O)=AA"
        pronunciation_rule    "]P"
        pronunciation_rule    " (P) =PIY4"
        pronunciation_rule    "(PH)=F"
        pronunciation_rule    "(PEOPL)=PIY5PUL"
        pronunciation_rule    "(POW)=PAW4"
        pronunciation_rule    "(PUT) =PUHT"
        pronunciation_rule    "(P)P="
        pronunciation_rule    " (P)S="
        pronunciation_rule    " (P)N="
        pronunciation_rule    " (PROF.)=PROHFEH4SER"
        pronunciation_rule    "(P)=P"
        pronunciation_rule    "]Q"
        pronunciation_rule    " (Q) =KYUW4"
        pronunciation_rule    "(QUAR)=KWOH5R"
        pronunciation_rule    "(QU)=KW"
        pronunciation_rule    "(Q)=K"
        pronunciation_rule    "]R"
        pronunciation_rule    " (R) =AA5R"
        pronunciation_rule    " (RE)^#=RIY"
        pronunciation_rule    "(R)R="
        pronunciation_rule    "(R)=R"
        pronunciation_rule    "]S"
        pronunciation_rule    " (S) =EH4S"
        pronunciation_rule    "(SH)=SH"
        pronunciation_rule    "#(SION)=ZHUN"
        pronunciation_rule    "(SOME)=SAHM"
        pronunciation_rule    "#(SUR)#=ZHER"
        pronunciation_rule    "(SUR)#=SHER"
        pronunciation_rule    "#(SU)#=ZHUW"
        pronunciation_rule    "#(SSU)#=SHUW"
        pronunciation_rule    "#(SED) =ZD"
        pronunciation_rule    "#(S)#=Z"
        pronunciation_rule    "(SAID)=SEHD"
        pronunciation_rule    "^(SION)=SHUN"
        pronunciation_rule    "(S)S="
        pronunciation_rule    ".(S) =Z"
        pronunciation_rule    "#:.E(S) =Z"
        pronunciation_rule    "#:^#(S) =S"
        pronunciation_rule    "U(S) =S"
        pronunciation_rule    " :#(S) =Z"
        pronunciation_rule    "##(S) =Z"
        pronunciation_rule    " (SCH)=SK"
        pronunciation_rule    "(S)C+="
        pronunciation_rule    "#(SM)=ZUM"
        pronunciation_rule    "#(SN)'=ZUN"
        pronunciation_rule    "(STLE)=SUL"
        pronunciation_rule    "(S)=S"
        pronunciation_rule    "]T"
        pronunciation_rule    " (T) =TIY4"
        pronunciation_rule    " (THE) #=DHIY"
        pronunciation_rule    " (THE) =DHAX"
        pronunciation_rule    "(TO) =TUX"
        pronunciation_rule    " (THAT)=DHAET"
        pronunciation_rule    " (THIS) =DHIHS"
        pronunciation_rule    " (THEY)=DHEY"
        pronunciation_rule    " (THERE)=DHEHR"
        pronunciation_rule    "(THER)=DHER"
        pronunciation_rule    "(THEIR)=DHEHR"
        pronunciation_rule    " (THAN) =DHAEN"
        pronunciation_rule    " (THEM) =DHEHM"
        pronunciation_rule    "(THESE) =DHIYZ"
        pronunciation_rule    " (THEN)=DHEHN"
        pronunciation_rule    "(THROUGH)=THRUW4"
        pronunciation_rule    "(THOSE)=DHOHZ"
        pronunciation_rule    "(THOUGH) =DHOW"
        pronunciation_rule    "(TODAY)=TUXDEY"
        pronunciation_rule    "(TOMO)RROW=TUMAA5"
        pronunciation_rule    "(TO)TAL=TOW5"
        pronunciation_rule    " (THUS)=DHAH4S"
        pronunciation_rule    "(TH)=TH"
        pronunciation_rule    "#:(TED) =TIXD"
        pronunciation_rule    "S(TI)#N=CH"
        pronunciation_rule    "(TI)O=SH"
        pronunciation_rule    "(TI)A=SH"
        pronunciation_rule    "(TIEN)=SHUN"
        pronunciation_rule    "(TUR)#=CHER"
        pronunciation_rule    "(TU)A=CHUW"
        pronunciation_rule    " (TWO)=TUW"
        pronunciation_rule    "&(T)EN ="
        pronunciation_rule    "(T)=T"
        pronunciation_rule    "]U"
        pronunciation_rule    " (U) =YUW4"
        pronunciation_rule    " (UN)I=YUWN"
        pronunciation_rule    " (UN)=AHN"
        pronunciation_rule    " (UPON)=AXPAON"
        pronunciation_rule    "@(UR)#=UH4R"
        pronunciation_rule    "(UR)#=YUH4R"
        pronunciation_rule    "(UR)=ER"
        pronunciation_rule    "(U)^ =AH"
        pronunciation_rule    "(U)^^=AH5"
        pronunciation_rule    "(UY)=AY5"
        pronunciation_rule    " G(U)#="
        pronunciation_rule    "G(U)%="
        pronunciation_rule    "G(U)#=W"
        pronunciation_rule    "#N(U)=YUW"
        pronunciation_rule    "@(U)=UW"
        pronunciation_rule    "(U)=YUW"
        pronunciation_rule    "]V"
        pronunciation_rule    " (V) =VIY4"
        pronunciation_rule    "(VIEW)=VYUW5"
        pronunciation_rule    "(V)=V"
        pronunciation_rule    "]W"
        pronunciation_rule    " (W) =DAH4BULYUW"
        pronunciation_rule    " (WERE)=WER"
        pronunciation_rule    "(WA)SH=WAA"
        pronunciation_rule    "(WA)ST=WEY"
        pronunciation_rule    "(WA)S=WAH"
        pronunciation_rule    "(WA)T=WAA"
        pronunciation_rule    "(WHERE)=WHEHR"
        pronunciation_rule    "(WHAT)=WHAHT"
        pronunciation_rule    "(WHOL)=/HOWL"
        pronunciation_rule    "(WHO)=/HUW"
        pronunciation_rule    "(WH)=WH"
        pronunciation_rule    "(WAR)#=WEHR"
        pronunciation_rule    "(WAR)=WAOR"
        pronunciation_rule    "(WOR)^=WER"
        pronunciation_rule    "(WR)=R"
        pronunciation_rule    "(WOM)A=WUHM"
        pronunciation_rule    "(WOM)E=WIHM"
        pronunciation_rule    "(WEA)R=WEH"
        pronunciation_rule    "(WANT)=WAA5NT"
        pronunciation_rule    "ANS(WER)=ER"
        pronunciation_rule    "(W)=W"
        pronunciation_rule    "]X"
        pronunciation_rule    " (X) =EH4KS"
        pronunciation_rule    " (X)=Z"
        pronunciation_rule    "(X)=KS"
        pronunciation_rule    "]Y"
        pronunciation_rule    " (Y) =WAY4"
        pronunciation_rule    "(YOUNG)=YAHNX"
        pronunciation_rule    " (YOUR)=YOHR"
        pronunciation_rule    " (YOU)=YUW"
        pronunciation_rule    " (YES)=YEHS"
        pronunciation_rule    " (Y)=Y"
        pronunciation_rule    "F(Y)=AY"
        pronunciation_rule    "PS(YCH)=AYK"
        pronunciation_rule    "#:^(Y) =IY"
        pronunciation_rule    "#:^(Y)I=IY"
        pronunciation_rule    " :(Y) =AY"
        pronunciation_rule    " :(Y)#=AY"
        pronunciation_rule    " :(Y)^+:#=IH"
        pronunciation_rule    " :(Y)^#=AY"
        pronunciation_rule    "(Y)=IH"
        pronunciation_rule    "]Z"
        pronunciation_rule    " (Z) =ZIY4"
        pronunciation_rule    "(Z)=Z"

        ; Trailing bytes.
        ; TODO: found out their purpose (if there is any).

        .byte   $EA,$A0

        END_OF_BLOCK1 = *

        .segment "BLOCK2_HEADER": absolute

        ; This is the Atari executable header for the second block in the executable file.
        ; It points to the two-byte RUNAD value used by DOS as the run address for executable files.

        .word $2e2,$2e3

        .segment "BLOCK2": absolute

        ; The content of the second block is just the run address of the code.

        .word _start ; 0x4b23
