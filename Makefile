MAKEFLAGS += -s
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

define USAGE
make clean     - Remove untracked git files
make cleanall  - Like clean but also removes docker image
make build     - Build the tooling container
make run       - Run the tooling container
endef

all:
	$(info $(USAGE))

clean:
	@rm -rf build/*
	@git clean -fXd

cleanall: clean
	@docker rmi -f ducksauz/esp-matter-dev 2>/dev/null

build:
	@docker build -t ducksauz/esp-matter-dev \
	-f Dockerfile .

run:
	@docker run --rm -it -v $(shell pwd):/workspaces ducksauz/esp-matter-dev

.PHONY: all clean cleanall build run
