SUBDIRS = pru/lib/src/rpmsg_lib pru/lib/src/pru_support_lib  pru/lib/src/msgpack_lib pru/0 pru/1

all: $(SUBDIRS)

$(SUBDIRS):
	# env | grep -i -e nerves -e cgt | sort
	$(MAKE) -C $@

clean:
	@for d in $(SUBDIRS); do (cd $$d; $(MAKE) clean ); done

.PHONY: $(SUBDIRS)
