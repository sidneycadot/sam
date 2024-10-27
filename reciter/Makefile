
.PHONY : default check

check :reciter_4590_5cbd.bin
	@md5sum -c MD5SUM

reciter_4590_5cbd.bin : reciter_4590_5cbd.o
	ld65 -C reciter.lnk reciter_4590_5cbd.o -o $@

reciter_4590_5cbd.o : reciter_4590_5cbd.s
	ca65 $< -o $@

clean :
	$(RM) reciter_4590_5cbd.o
