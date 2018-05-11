SUBDIRS = pru/0 pru/1

#------------------------------------

export GEN_DIR=gen
#------------------------------------
#Common compiler and linker flags (Defined in 'PRU Optimizing C/C++ Compiler User's Guide)
export CFLAGS=-v3 -O2 --display_error_number --endian=little --hardware_mac=on --obj_directory=$(GEN_DIR) --pp_directory=$(GEN_DIR) -ppd -ppa
export LFLAGS=--reread_libs --warn_sections --stack_size=$(STACK_SIZE) --heap_size=$(HEAP_SIZE)
#------------------------------------
export LIBS=--library=$(PRU_LIB)/pru/rpmsg.lib
export SYS_INCLUDE=-i$(PRU_CGT)/lib -i$(PRU_CGT)/include
export INCLUDE=--include_path=$(PRU_LIB)/pru/include --include_path=$(PRU_LIB)/pru/include --include_path=$(PRU_LIB)/pru/include/am335x
#------------------------------------
export STACK_SIZE=0x100
export HEAP_SIZE=0x100
#------------------------------------

all: clean $(SUBDIRS)

$(SUBDIRS):
	@echo "Entering: " $@
	@echo PRU_CGT: $(PRU_CGT)
	@echo PRU_LIB: $(PRU_LIB)
	@echo ""
	$(MAKE) -C $@

clean:
	@for d in $(SUBDIRS); do (cd $$d; PRU_CGT="/dev/null" $(MAKE) clean ); done
	@echo "**************** Done Cleaning *********************"

.PHONY: $(SUBDIRS)

