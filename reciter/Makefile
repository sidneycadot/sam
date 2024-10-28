
.PHONY : default check

check :reciter.bin
	@md5sum -c MD5SUM

reciter.bin : reciter.o
	ld65 -C reciter.lnk reciter.o -o $@

reciter.o : reciter.s
	ca65 $< -o $@

clean :
	$(RM) reciter.bin reciter.o
