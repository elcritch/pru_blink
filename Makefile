SUBDIRS = pru/lib/src/rpmsg_lib pru/0 pru/1

all: $(SUBDIRS)

$(SUBDIRS):
	env | sort | grep -i -e nerves -e cc
	$(MAKE) -C $@

clean:
	@for d in $(SUBDIRS); do (cd $$d; $(MAKE) clean ); done

.PHONY: $(SUBDIRS)
