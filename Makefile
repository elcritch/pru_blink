SUBDIRS = pru/0 pru/1

#------------------------------------
export PRU_LIB=$(shell mix nerves.path.dep nerves_pru_support | tail -n 1)/priv/pru/
#export PRU_CGT=$(shell mix nerves.path.artifact nerves_pru_icss | tail -n1)/ti-cgt-pru

export GEN_DIR=gen
#------------------------------------
#Common compiler and linker flags (Defined in 'PRU Optimizing C/C++ Compiler User's Guide)
export CFLAGS=-v3 -O2 --display_error_number --endian=little --hardware_mac=on --obj_directory=$(GEN_DIR) --pp_directory=$(GEN_DIR) -ppd -ppa
export LFLAGS=--reread_libs --warn_sections --stack_size=$(STACK_SIZE) --heap_size=$(HEAP_SIZE)
#------------------------------------
export LIBS=--library=$(PRU_LIB)/rpmsg.lib
export SYS_INCLUDE=-i$(PRU_CGT)/lib -i$(PRU_CGT)/include
export INCLUDE=--include_path=$(PRU_LIB)/include --include_path=$(PRU_LIB)/include/am335x
#------------------------------------
export STACK_SIZE=0x100
export HEAP_SIZE=0x100
#------------------------------------

all: $(SUBDIRS)

$(SUBDIRS):
	@echo PRU_CGT: $(PRU_CGT)
	@echo PRU_LIB: $(PRU_LIB)
	$(MAKE) -C $@

clean:
	@for d in $(SUBDIRS); do (cd $$d; $(MAKE) clean ); done

.PHONY: $(SUBDIRS)
