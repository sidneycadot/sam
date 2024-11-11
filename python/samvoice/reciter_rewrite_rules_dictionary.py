"""This module provides the ReciterRewriteRule class, including matching functionality."""

from __future__ import annotations

import re
import textwrap
from typing import Optional

from .reciter_rewrite_rule import ReciterRewriteRule

type ReciterRewriteRulesDictionary = dict[Optional[str], list[ReciterRewriteRule]]


def parse_rewrite_rules_dictionary(rule_lines: str) -> ReciterRewriteRulesDictionary:
    """Parse string file containing SAM Reciter rewrite rules and return them as a key-indexed dictionary."""

    # Prepare empty rules dictionary with all keys (None and A..Z), but no rules.
    rules_dictionary: ReciterRewriteRulesDictionary = {None: []}
    for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        rules_dictionary[letter] = []

    key = None  # Start processing rules with key value: None.

    # A "key" entry is a right-angle-bracket character (']') followed by a capital letter A..Z.
    key_regexp = re.compile(r"]([A-Z])")

    # A "rule" entry is a line of the form: "prefix(stem)suffix=replacement".
    rule_regexp = re.compile(r"(.*)\((.*)\)(.*)=(.*)")

    # Process all lines in the file. They are either 'key' lines or 'rule' lines.
    for line in rule_lines.splitlines():

        # Empty lines are ignored.
        if len(line) == 0:
            continue

        # The rules file may optionally contain underscores; they are converted to spaces.
        line = line.replace("_", " ")

        # Check if it is a "key" line. if yes, switch to the specified key.
        match = key_regexp.fullmatch(line)
        if match is not None:
            key = match.group(1)
            continue

        # Check if it is a "rule" line. if yes, add the rule using the currently active key.
        match = rule_regexp.fullmatch(line)
        if match is not None:
            (prefix, stem, suffix, replacement) = match.groups()
            rule = ReciterRewriteRule(prefix, stem, suffix, replacement)
            rules_dictionary[key].append(rule)
            continue

        # The line is neither a key nor a rule. This is a fatal error.
        raise RuntimeError(f"Badly formatted rules dictionary line: {line!r}")

    return rules_dictionary


def read_rewrite_rules_dictionary_from_file(filename: str) -> ReciterRewriteRulesDictionary:
    """Utility class to read a file containing SAM Reciter rewrite rules and return them as a key-indexed dictionary."""

    # Read the entire file.
    with open(filename, "r", encoding="ascii") as fi:
        rule_lines = fi.read()

    return parse_rewrite_rules_dictionary(rule_lines)


def get_default_rewrite_rules_dictionary() -> ReciterRewriteRulesDictionary:
    """Return the default rewrite-rule dictionary as used by the SAM Reciter.

    This is a verbatim list of the English-language rules as used in the assembly version of the Reciter.
    """

    rule_lines = textwrap.dedent("""
    (A)=
    (!)=.
    (")_=-AH5NKWOWT-
    (")=KWOW4T-
    (#)=_NAH4MBER
    ($)=_DAA4LER
    (%)=_PERSEH4NT
    (&)=_AEND
    (')=
    (*)=_AE4STERIHSK
    (+)=_PLAH4S
    (,)=,
    _(-)_=-
    (-)=
    (.)=_POYNT
    (/)=_SLAE4SH
    (0)=_ZIY4ROW
    _(1ST)=FER4ST
    _(10TH)=TEH4NTH
    (1)=_WAH4N
    _(2ND)=SEH4KUND
    (2)=_TUW4
    _(3RD)=THER4D
    (3)=_THRIY4
    (4)=_FOH4R
    _(5TH)=FIH4FTH
    (5)=_FAY4V
    (6)=_SIH4KS
    (7)=_SEH4VUN
    _(8TH)=EY4TH
    (8)=_EY4T
    (9)=_NAY4N
    (:)=.
    (;)=.
    (<)=_LEH4S_DHAEN
    (=)=_IY4KWULZ
    (>)=_GREY4TER_DHAEN
    (?)=.
    (@)=_AE6T
    (^)=_KAE4RIXT
    ]A
    _(A.)=EH4Y._
    (A)_=AH
    _(ARE)_=AAR
    _(AR)O=AXR
    (AR)#=EH4R
    _^(AS)#=EY4S
    (A)WA=AX
    (AW)=AO5
    _:(ANY)=EH4NIY
    (A)^+#=EY5
    #:(ALLY)=ULIY
    _(AL)#=UL
    (AGAIN)=AXGEH4N
    #:(AG)E=IHJ
    (A)^%=EY
    (A)^+:#=AE
    _:(A)^+_=EY4
    _(ARR)=AXR
    (ARR)=AE4R
    _^(AR)_=AA5R
    (AR)=AA5R
    (AIR)=EH4R
    (AI)=EY4
    (AY)=EY5
    (AU)=AO4
    #:(AL)_=UL
    #:(ALS)_=ULZ
    (ALK)=AO4K
    (AL)^=AOL
    _:(ABLE)=EY4BUL
    (ABLE)=AXBUL
    (A)VO=EY4
    (ANG)+=EY4NJ
    (ATARI)=AHTAA4RIY
    (A)TOM=AE
    (A)TTI=AE
    _(AT)_=AET
    _(A)T=AH
    (A)=AE
    ]B
    _(B)_=BIY4
    _(BE)^#=BIH
    (BEING)=BIY4IHNX
    _(BOTH)_=BOW4TH
    _(BUS)#=BIH4Z
    (BREAK)=BREY5K
    (BUIL)=BIH4L
    (B)=B
    ]C
    _(C)_=SIY4
    _(CH)^=K
    ^E(CH)=K
    (CHA)R#=KEH5
    (CH)=CH
    _S(CI)#=SAY4
    (CI)A=SH
    (CI)O=SH
    (CI)EN=SH
    (CITY)=SIHTIY
    (C)+=S
    (CK)=K
    (COM)=KAHM
    (CUIT)=KIHT
    (CREA)=KRIYEY
    (C)=K
    ]D
    _(D)_=DIY4
    _(DR.)_=DAA4KTER
    #:(DED)_=DIHD
    .E(D)_=D
    #:^E(D)_=T
    _(DE)^#=DIH
    _(DO)_=DUW
    _(DOES)=DAHZ
    (DONE)_=DAH5N
    (DOING)=DUW4IHNX
    _(DOW)=DAW
    #(DU)A=JUW
    #(DU)^#=JAX
    (D)=D
    ]E
    _(E)_=IYIY4
    #:(E)_=
    ':^(E)_=
    _:(E)_=IY
    #(ED)_=D
    #:(E)D_=
    (EV)ER=EH4V
    (E)^%=IY4
    (ERI)#=IY4RIY
    (ERI)=EH4RIH
    #:(ER)#=ER
    (ERROR)=EH4ROHR
    (ERASE)=IHREY5S
    (ER)#=EHR
    (ER)=ER
    _(EVEN)=IYVEHN
    #:(E)W=
    @(EW)=UW
    (EW)=YUW
    (E)O=IY
    #:&(ES)_=IHZ
    #:(E)S_=
    #:(ELY)_=LIY
    #:(EMENT)=MEHNT
    (EFUL)=FUHL
    (EE)=IY4
    (EARN)=ER5N
    _(EAR)^=ER5
    (EAD)=EHD
    #:(EA)_=IYAX
    (EA)SU=EH5
    (EA)=IY5
    (EIGH)=EY4
    (EI)=IY4
    _(EYE)=AY4
    (EY)=IY
    (EU)=YUW5
    (EQUAL)=IY4KWUL
    (E)=EH
    ]F
    _(F)_=EH4F
    (FUL)=FUHL
    (FRIEND)=FREH5ND
    (FATHER)=FAA4DHER
    (F)F=
    (F)=F
    ]G
    _(G)_=JIY4
    (GIV)=GIH5V
    _(G)I^=G
    (GE)T=GEH5
    SU(GGES)=GJEH4S
    (GG)=G
    _B#(G)=G
    (G)+=J
    (GREAT)=GREY4T
    (GON)E=GAO5N
    #(GH)=
    _(GN)=N
    (G)=G
    ]H
    _(H)_=EY4CH
    _(HAV)=/HAE6V
    _(HERE)=/HIYR
    _(HOUR)=AW5ER
    (HOW)=/HAW
    (H)#=/H
    (H)=
    ]I
    _(IN)=IHN
    _(I)_=AY4
    (I)_=AY
    (IN)D=AY5N
    SEM(I)=IY
    _ANT(I)=AY
    (IER)=IYER
    #:R(IED)_=IYD
    (IED)_=AY5D
    (IEN)=IYEHN
    (IE)T=AY4EH
    (I')=AY5
    _:(I)^%=AY5
    _:(IE)_=AY4
    (I)%=IY
    (IE)=IY4
    _(IDEA)=AYDIY5AH
    (I)^+:#=IH
    (IR)#=AYR
    (IZ)%=AYZ
    (IS)%=AYZ
    I^(I)^#=IH
    +^(I)^+=AY
    #:^(I)^+=IH
    (I)^+=AY
    (IR)=ER
    (IGH)=AY4
    (ILD)=AY5LD
    _(IGN)=IHGN
    (IGN)_=AY4N
    (IGN)^=AY4N
    (IGN)%=AY4N
    (ICRO)=AY4KROH
    (IQUE)=IY4K
    (I)=IH
    ]J
    _(J)_=JEY4
    (J)=J
    ]K
    _(K)_=KEY4
    _(K)N=
    (K)=K
    ]L
    _(L)_=EH4L
    (LO)C#=LOW
    L(L)=
    #:^(L)%=UL
    (LEAD)=LIYD
    _(LAUGH)=LAE4F
    (L)=L
    ]M
    _(M)_=EH4M
    _(MR.)_=MIH4STER
    _(MS.)=MIH5Z
    _(MRS.)_=MIH4SIXZ
    (MOV)=MUW4V
    (MACHIN)=MAHSHIY5N
    M(M)=
    (M)=M
    ]N
    _(N)_=EH4N
    E(NG)+=NJ
    (NG)R=NXG
    (NG)#=NXG
    (NGL)%=NXGUL
    (NG)=NX
    (NK)=NXK
    _(NOW)_=NAW4
    N(N)=
    (NON)E=NAH4N
    (N)=N
    ]O
    _(O)_=OH4W
    (OF)_=AHV
    _(OH)_=OW5
    (OROUGH)=ER4OW
    #:(OR)_=ER
    #:(ORS)_=ERZ
    (OR)=AOR
    _(ONE)=WAHN
    #(ONE)_=WAHN
    (OW)=OW
    _(OVER)=OW5VER
    PR(O)V=UW4
    (OV)=AH4V
    (O)^%=OW5
    (O)^EN=OW
    (O)^I#=OW5
    (OL)D=OW4L
    (OUGHT)=AO5T
    (OUGH)=AH5F
    _(OU)=AW
    H(OU)S#=AW4
    (OUS)=AXS
    (OUR)=OHR
    (OULD)=UH5D
    (OU)^L=AH5
    (OUP)=UW5P
    (OU)=AW
    (OY)=OY
    (OING)=OW4IHNX
    (OI)=OY5
    (OOR)=OH5R
    (OOK)=UH5K
    F(OOD)=UW5D
    L(OOD)=AH5D
    M(OOD)=UW5D
    (OOD)=UH5D
    F(OOT)=UH5T
    (OO)=UW5
    (O')=OH
    (O)E=OW
    (O)_=OW
    (OA)=OW4
    _(ONLY)=OW4NLIY
    _(ONCE)=WAH4NS
    (ON'T)=OW4NT
    C(O)N=AA
    (O)NG=AO
    _:^(O)N=AH
    I(ON)=UN
    #:(ON)_=UN
    #^(ON)=UN
    (O)ST_=OW
    (OF)^=AO4F
    (OTHER)=AH5DHER
    R(O)B=RAA
    ^R(O):#=OW5
    (OSS)_=AO5S
    #:^(OM)=AHM
    (O)=AA
    ]P
    _(P)_=PIY4
    (PH)=F
    (PEOPL)=PIY5PUL
    (POW)=PAW4
    (PUT)_=PUHT
    (P)P=
    _(P)S=
    _(P)N=
    _(PROF.)=PROHFEH4SER
    (P)=P
    ]Q
    _(Q)_=KYUW4
    (QUAR)=KWOH5R
    (QU)=KW
    (Q)=K
    ]R
    _(R)_=AA5R
    _(RE)^#=RIY
    (R)R=
    (R)=R
    ]S
    _(S)_=EH4S
    (SH)=SH
    #(SION)=ZHUN
    (SOME)=SAHM
    #(SUR)#=ZHER
    (SUR)#=SHER
    #(SU)#=ZHUW
    #(SSU)#=SHUW
    #(SED)_=ZD
    #(S)#=Z
    (SAID)=SEHD
    ^(SION)=SHUN
    (S)S=
    .(S)_=Z
    #:.E(S)_=Z
    #:^#(S)_=S
    U(S)_=S
    _:#(S)_=Z
    ##(S)_=Z
    _(SCH)=SK
    (S)C+=
    #(SM)=ZUM
    #(SN)'=ZUN
    (STLE)=SUL
    (S)=S
    ]T
    _(T)_=TIY4
    _(THE)_#=DHIY
    _(THE)_=DHAX
    (TO)_=TUX
    _(THAT)=DHAET
    _(THIS)_=DHIHS
    _(THEY)=DHEY
    _(THERE)=DHEHR
    (THER)=DHER
    (THEIR)=DHEHR
    _(THAN)_=DHAEN
    _(THEM)_=DHEHM
    (THESE)_=DHIYZ
    _(THEN)=DHEHN
    (THROUGH)=THRUW4
    (THOSE)=DHOHZ
    (THOUGH)_=DHOW
    (TODAY)=TUXDEY
    (TOMO)RROW=TUMAA5
    (TO)TAL=TOW5
    _(THUS)=DHAH4S
    (TH)=TH
    #:(TED)_=TIXD
    S(TI)#N=CH
    (TI)O=SH
    (TI)A=SH
    (TIEN)=SHUN
    (TUR)#=CHER
    (TU)A=CHUW
    _(TWO)=TUW
    &(T)EN_=
    (T)=T
    ]U
    _(U)_=YUW4
    _(UN)I=YUWN
    _(UN)=AHN
    _(UPON)=AXPAON
    @(UR)#=UH4R
    (UR)#=YUH4R
    (UR)=ER
    (U)^_=AH
    (U)^^=AH5
    (UY)=AY5
    _G(U)#=
    G(U)%=
    G(U)#=W
    #N(U)=YUW
    @(U)=UW
    (U)=YUW
    ]V
    _(V)_=VIY4
    (VIEW)=VYUW5
    (V)=V
    ]W
    _(W)_=DAH4BULYUW
    _(WERE)=WER
    (WA)SH=WAA
    (WA)ST=WEY
    (WA)S=WAH
    (WA)T=WAA
    (WHERE)=WHEHR
    (WHAT)=WHAHT
    (WHOL)=/HOWL
    (WHO)=/HUW
    (WH)=WH
    (WAR)#=WEHR
    (WAR)=WAOR
    (WOR)^=WER
    (WR)=R
    (WOM)A=WUHM
    (WOM)E=WIHM
    (WEA)R=WEH
    (WANT)=WAA5NT
    ANS(WER)=ER
    (W)=W
    ]X
    _(X)_=EH4KS
    _(X)=Z
    (X)=KS
    ]Y
    _(Y)_=WAY4
    (YOUNG)=YAHNX
    _(YOUR)=YOHR
    _(YOU)=YUW
    _(YES)=YEHS
    _(Y)=Y
    F(Y)=AY
    PS(YCH)=AYK
    #:^(Y)_=IY
    #:^(Y)I=IY
    _:(Y)_=AY
    _:(Y)#=AY
    _:(Y)^+:#=IH
    _:(Y)^#=AY
    (Y)=IH
    ]Z
    _(Z)_=ZIY4
    (Z)=Z
    """)

    return parse_rewrite_rules_dictionary(rule_lines)
