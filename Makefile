
.PHONY : default check

check : MD5SUM sam.xex reciter.xex
	md5sum -c MD5SUM

sam.xex reciter.xex : sam_and_reciter.lnk reciter.o sam.o atari.o
	ld65 -C sam_and_reciter.lnk reciter.o sam.o atari.o

sam.o : sam.s
	ca65 $< -o $@

reciter.o : reciter.s
	ca65 $< -o $@

atari.o : atari.s
	ca65 $< -o $@

clean :
	$(RM) sam.xex sam.o reciter.xex reciter.o atari.o *~
