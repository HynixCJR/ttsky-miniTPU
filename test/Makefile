# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
# FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src

TIMESTAMP = $(shell TZ=US/Eastern date +%Y%m%d_%H:%M:%S)

PROJECT_SOURCES = tt_um_4x4TPU.sv \
				  IO_Interface.v \
				  output_buffer.sv \
				  control_fsm.v \
				  systolic_array.sv \
				  systolic_array_mux.sv \
				  systolic_array_fsm.sv \
				  PE.v

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
# VERILOG_SOURCES += $(wildcard $(SRC_DIR)/*.sv) $(wildcard $(SRC_DIR)/*.v) 
else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

WAVES ?= 1

.PHONY: test-tpu test-systolic test-control test-mux test-io

all: 
	$(MAKE) test-tpu
	$(MAKE) test-systolic
	$(MAKE) test-control
	$(MAKE) test-mux
	$(MAKE) test-io

test-tpu:
	$(MAKE) clean
	$(MAKE) sim \
		TOPLEVEL=tb \
		MODULE=test_tpu \
		PYTHONPATH=$(PWD)/4x4TPU \
		SIM_BUILD=$(PWD)/4x4TPU/test_result \


test-control:
	$(MAKE) clean
	$(MAKE) sim \
		TOPLEVEL=tb \
		MODULE=test_systolic_fsm \
		PYTHONPATH=$(PWD)/systolic_fsm \
		SIM_BUILD=$(PWD)/systolic_fsm/test_result \

test-systolic:
	$(MAKE) clean
	$(MAKE) sim \
        TOPLEVEL=tb \
		MODULE=test_systolic_array \
		PYTHONPATH=$(PWD)/systolic_array \
		SIM_BUILD=$(PWD)/systolic_array/test_result \

test-mux:
	$(MAKE) clean
	$(MAKE) sim \
		TOPLEVEL=tb \
		MODULE=test_systolic_mux \
		PYTHONPATH=$(PWD)/systolic_mux \
		SIM_BUILD=$(PWD)/systolic_mux/test_result \

test-io:
	$(MAKE) clean
	$(MAKE) sim \
		TOPLEVEL=tb \
		MODULE=test_IO_Interface \
		PYTHONPATH=$(PWD)/IO_Interface \
		SIM_BUILD=$(PWD)/IO_Interface/test_result \



# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim


##
