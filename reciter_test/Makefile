
TEST_INPUT_FILES=$(wildcard tests/test_*.txt)

TEST_OUTPUT_FILES=$(TEST_INPUT_FILES:%.txt=%.out)

.PHONY : clean default test interactive

default : interactive

interactive : reciter_test
	@echo
	@echo "Enter lines and they will be rendered by the SAM Reciter."
	@echo "Press CTRL-D to stop."
	@echo
	@sim65 reciter_test
	@echo

test : tests/MD5SUM
	cd tests && md5sum -c MD5SUM

tests/MD5SUM: $(TEST_OUTPUT_FILES)
	cd tests && md5sum $(TEST_OUTPUT_FILES:tests/%=%) > MD5SUM

%.out : %.txt reciter_test
	sim65 reciter_test < $< > $@

reciter_test : reciter_test.c reciter_modded.s
	cl65 -t sim6502 $^ -o $@

clean :
	$(RM) *.o reciter_test $(TEST_OUTPUT_FILES) tests/MD5SUM
