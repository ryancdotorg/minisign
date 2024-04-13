MAKEFLAGS += --no-builtin-rules
export LANG=C LC_ALL=C

CC ?= gcc
AS ?= gcc
PP ?= cpp
LD ?= ld

WITH_PTHREADS ?= 1
override LDFLAGS += -lsodium
ifneq ($(WITH_PTHREADS),0)
	override LDFLAGS += -lpthread
endif

CFLAGS ?= -O2
override CFLAGS += -std=gnu17 -Wall -Wextra -pedantic \
	-D_ALL_SOURCE -D_GNU_SOURCE \
	-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64

COMPILE = $(CC) $(CPPFLAGS) $(CFLAGS)
#OBJECTS = $(patsubst src/%.c,obj/%.o,$(wildcard src/*.c))
OBJ_COMMON = $(patsubst %,obj/%.o,base64 helpers)
OBJ_VERIFY = $(OBJ_COMMON) $(patsubst %,obj/%_verify.o,get_line minisign)
OBJ_FULL   = $(OBJ_COMMON) $(patsubst %,obj/%.o,get_line minisign)

.PHONY: all clean _clean _nop

all: bin/minisign

bin/minisign: $(OBJ_FULL)
	@mkdir -p $(@D)
	$(COMPILE) $^ $(LDFLAGS) -o $@

bin/miniverify: $(OBJ_VERIFY)
	@mkdir -p $(@D)
	$(COMPILE) $^ $(LDFLAGS) -o $@

obj/miniverify_main.o: src/minisign.c src/minisign.h
	@mkdir -p $(@D)
	$(COMPILE) -DMINISIGN_MAIN=miniverify_main -DVERIFY_ONLY -c $< -o $@

obj/miniverify_multicall.o: $(OBJ_COMMON) obj/miniverify_main.o obj/get_line_verify.o
	@mkdir -p $(@D)
	$(COMPILE) -r $^ -o $@

obj/minisign_main.o: src/minisign.c src/minisign.h
	@mkdir -p $(@D)
	$(COMPILE) -DMINISIGN_MAIN=minisign_main -DVERIFY_ONLY -c $< -o $@

obj/minisign_multicall.o: $(OBJ_COMMON) obj/minisign_main.o obj/get_line.o
	@mkdir -p $(@D)
	$(COMPILE) -r $^ -o $@

obj/%_verify.o: src/%.c src/%.h
	@mkdir -p $(@D)
	$(COMPILE) -DVERIFY_ONLY -c $< -o $@

obj/%_verify.o: src/%.c
	@mkdir -p $(@D)
	$(COMPILE) -DVERIFY_ONLY -c $< -o $@

# generic build rules
obj/%.o: src/%.c src/%.h
	@mkdir -p $(@D)
	$(COMPILE) -c $< -o $@

obj/%.o: src/%.c
	@mkdir -p $(@D)
	$(COMPILE) -c $< -o $@

# hack to force clean to run first *to completion* even for parallel builds
# note that $(info ...) prints everything on one line 
clean: _nop $(foreach _,$(filter clean,$(MAKECMDGOALS)),$(info $(shell $(MAKE) _clean)))
_clean:
	rm -rf obj bin || /bin/true
_nop:
	@true
