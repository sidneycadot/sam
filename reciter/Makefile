
.PHONY : default check

check :reciter.xex MD5SUM
	@md5sum -c MD5SUM

reciter.xex : reciter.o
	ld65 -C reciter.lnk reciter.o -o $@

reciter.o : reciter.s
	ca65 $< -o $@

clean :
	$(RM) reciter.xex reciter.o
