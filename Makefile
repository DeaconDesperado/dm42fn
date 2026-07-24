SOURCES := $(wildcard */*.hp42s)
RAW_FILES := $(SOURCES:%.hp42s=%.hp42s.raw)

.PHONY: all raw help clean

all: raw help

raw: $(RAW_FILES)

%.hp42s.raw: %.hp42s
	txt2raw $<

help: help/dm42fnhelp.htm

help/dm42fnhelp.htm: $(SOURCES)
	@mkdir -p help
	@./scripts/gen-help.sh $^ > $@
	@echo "Generated $@"

clean:
	rm -f $(RAW_FILES) help/dm42fnhelp.htm
