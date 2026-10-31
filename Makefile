.PHONY: all linux qnx clean clean-linux clean-qnx

all: linux qnx

linux:
	$(MAKE) -C linux

qnx:
	$(MAKE) -C qnx

clean: clean-linux clean-qnx

clean-linux:
	$(MAKE) -C linux clean

clean-qnx:
	$(MAKE) -C qnx clean

# make <component>-<target> runs <target> from that component's Makefile,
# e.g. linux-shell, linux-build MC=qemu, qnx-run-qemu, qnx-inspect.
linux-%:
	$(MAKE) -C linux $*

qnx-%:
	$(MAKE) -C qnx $*
