
.PHONY : default check

check :sam.xex MD5SUM
	@md5sum -c MD5SUM

sam.xex : sam.o
	ld65 -C sam.lnk sam.o -o $@

sam.o : sam.s
	ca65 $< -o $@

clean :
	$(RM) sam.xex sam.o
