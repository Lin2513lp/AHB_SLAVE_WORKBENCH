SHELL := /bin/bash
.DEFAULT_GOAL := all

VCS       ?= vcs
VERDI     ?= verdi

# The Synopsys license server is local to this VM. Keep a known-good default
# while allowing command-line overrides for a different installation.
SCL_HOME       ?= /home/yian/Synopsys/scl/2024.06
LICENSE_SERVER ?= 27000@localhost.localdomain
LICENSE_FILE   ?= $(SCL_HOME)/admin/license/synopsys.lic
LMUTIL         ?= $(SCL_HOME)/linux64/bin/lmutil
LMGRD          ?= $(SCL_HOME)/linux64/bin/lmgrd
LICENSE_WAIT_SECONDS ?= 20

SNPSLMD_LICENSE_FILE ?= $(LICENSE_SERVER)
LM_LICENSE_FILE      ?= $(LICENSE_SERVER)
export SNPSLMD_LICENSE_FILE LM_LICENSE_FILE

# Select the default test below: keep exactly one ACTIVE_TEST line uncommented.
#ACTIVE_TEST := main
# ACTIVE_TEST := continuous_write
# ACTIVE_TEST := continuous_read
 ACTIVE_TEST := error

# A command-line TEST value temporarily overrides ACTIVE_TEST, for example:
# make all TEST=error
TEST ?= $(ACTIVE_TEST)

# Friendly aliases: make verdi TEST=write/read/error
ifeq ($(TEST),write)
override TEST := continuous_write
else ifeq ($(TEST),read)
override TEST := continuous_read
endif

TESTS := main continuous_write continuous_read error

TB_main                 := tb_ahb_slave.sv
TB_continuous_write     := tb_ahb_slave_continuous_write.sv
TB_continuous_read      := tb_ahb_slave_continuous_read.sv
TB_error                := tb_ahb_slave_error.sv
TOP_main                := tb_ahb_slave
TOP_continuous_write    := tb_ahb_slave_continuous_write
TOP_continuous_read     := tb_ahb_slave_continuous_read
TOP_error               := tb_ahb_slave_error

PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# VMware hgfs shared folders generally cannot create the symbolic links used
# by VCS.  Keep all generated products on the VM's local Linux filesystem.
# Override RUN_ROOT only if the chosen filesystem supports symbolic links.
RUN_ROOT ?= $(HOME)/ahb_slave_runs/AHB_SLAVE

BUILD_DIR  = $(RUN_ROOT)/build/$(TEST)
LOG_DIR    = $(RUN_ROOT)/logs
WAVE_DIR   = $(RUN_ROOT)/waves
SIMV       = $(BUILD_DIR)/simv
COMPILE_LOG = $(LOG_DIR)/$(TEST)_compile.log
RUN_LOG     = $(LOG_DIR)/$(TEST)_run.log
FSDB_FILE   = $(WAVE_DIR)/$(TEST).fsdb
LICENSE_LOG = $(LOG_DIR)/synopsys_lmgrd.log

TB_FILE     = $(TB_$(TEST))
TB_TOP      = $(TOP_$(TEST))

RTL_FILE := $(PROJECT_ROOT)/ahb_slave.sv

VERDI_BIN := $(shell command -v "$(VERDI)" 2>/dev/null)
VERDI_RESOLVED := $(shell readlink -f "$(VERDI_BIN)" 2>/dev/null)
VERDI_REAL := $(or $(strip $(VERDI_RESOLVED)),$(strip $(VERDI_BIN)))
VERDI_BIN_DIR := $(patsubst %/,%,$(dir $(VERDI_REAL)))
VERDI_AUTO_ROOT := $(patsubst %/,%,$(dir $(VERDI_BIN_DIR)))
VERDI_ROOT := $(or $(strip $(VERDI_HOME)),$(strip $(NOVAS_HOME)),$(strip $(VERDI_AUTO_ROOT)))
FSDB_TAB   := $(VERDI_ROOT)/share/PLI/VCS/LINUX64/novas.tab
FSDB_LIB   := $(VERDI_ROOT)/share/PLI/VCS/LINUX64/pli.a

VCS_COMMON ?= -full64 -sverilog -timescale=1ns/1ps -licqueue
VCS_DEBUG  ?= -kdb -debug_access+all
SIM_ARGS   ?=
FAIL_PATTERN := FAIL:|Assertion([^[:alnum:]]+)?(error|fail)|(^|[[:space:]])(\*\*[[:space:]]+)?(Error|Fatal)(:|-[[:alnum:]_-]+)|%Error|UVM_(ERROR|FATAL)

.PHONY: all regress compile run verdi wave summary help env dirs license \
        check-test check-sources check-vcs check-verdi check-fsdb \
        check-license-tools clean

# Compile/run only the selected ACTIVE_TEST (or command-line TEST override).
all: run

# Explicit full regression: compile/run all four tests and generate four FSDBs.
regress:
	@status=0; \
	for test in $(TESTS); do \
	  echo "============================================================"; \
	  echo "[REGRESS] $$test"; \
	  if ! $(MAKE) --no-print-directory TEST=$$test run; then status=1; fi; \
	done; \
	if ! $(MAKE) --no-print-directory summary; then status=1; fi; \
	exit $$status

compile: check-vcs check-fsdb license check-test check-sources dirs
	@echo "[VCS] Compiling $(TB_TOP)"
	@mkdir -p "$(BUILD_DIR)"
	@cd "$(BUILD_DIR)" && \
	  $(VCS) $(VCS_COMMON) $(VCS_DEBUG) +define+FSDB \
	    -P "$(FSDB_TAB)" "$(FSDB_LIB)" \
	    "$(RTL_FILE)" \
	    "$(PROJECT_ROOT)/$(TB_FILE)" \
	    -top "$(TB_TOP)" -Mdir=csrc -o simv \
	    -l "$(COMPILE_LOG)"
	@! grep -Eiq '$(FAIL_PATTERN)' "$(COMPILE_LOG)" || \
	  { echo "ERROR: compile failure marker found in $(COMPILE_LOG)"; exit 1; }

run: compile
	@echo "[SIM] Running $(TB_TOP)"
	@cd "$(RUN_ROOT)" && \
	  "$(SIMV)" +vcs+lic+wait +FSDB_FILE="$(FSDB_FILE)" $(SIM_ARGS) \
	    -l "$(RUN_LOG)"
	@test -f "$(FSDB_FILE)" || \
	  { echo "ERROR: FSDB was not generated: $(FSDB_FILE)"; exit 1; }
	@grep -Eq "^[[:space:]#]*PASS:[[:space:]]+$(TB_TOP)([[:space:]]|$$)" "$(RUN_LOG)" || \
	  { echo "ERROR: PASS marker not found in $(RUN_LOG)"; exit 1; }
	@! grep -Eiq '$(FAIL_PATTERN)' "$(RUN_LOG)" || \
	  { echo "ERROR: simulator/assertion failure found in $(RUN_LOG)"; exit 1; }
	@echo "[PASS] $(TB_TOP)"
	@echo "[LOG]  $(RUN_LOG)"
	@echo "[FSDB] $(FSDB_FILE)"

verdi wave: check-verdi check-test
	@test -f "$(FSDB_FILE)" || \
	  { echo "ERROR: waveform not found: $(FSDB_FILE)"; \
	    echo "Run: make run TEST=$(TEST)"; exit 1; }
	@cd "$(RUN_ROOT)" && \
	  $(VERDI) -full64 -ssf "$(FSDB_FILE)" -dbdir "$(SIMV).daidir" -nologo &

summary: dirs
	@summary_file="$(LOG_DIR)/regression_summary.log"; \
	status=0; \
	: > "$$summary_file"; \
	printf "%-20s %-10s %s\n" "TEST" "STATUS" "RUN_LOG" | tee -a "$$summary_file"; \
	printf "%-20s %-10s %s\n" "--------------------" "----------" "------------------------------" | tee -a "$$summary_file"; \
	for test in $(TESTS); do \
	  run_log="$(LOG_DIR)/$${test}_run.log"; \
	  case "$$test" in \
	    main) top="tb_ahb_slave" ;; \
	    continuous_write) top="tb_ahb_slave_continuous_write" ;; \
	    continuous_read) top="tb_ahb_slave_continuous_read" ;; \
	    error) top="tb_ahb_slave_error" ;; \
	  esac; \
	  if [ ! -f "$$run_log" ]; then \
	    result="NOT_RUN"; \
	    status=1; \
	  elif ! grep -Eq "^[[:space:]#]*PASS:[[:space:]]+$$top([[:space:]]|$$)" "$$run_log"; then \
	    result="FAIL"; \
	    status=1; \
	  elif grep -Eiq '$(FAIL_PATTERN)' "$$run_log"; then \
	    result="FAIL"; \
	    status=1; \
	  else \
	    result="PASS"; \
	  fi; \
	  printf "%-20s %-10s %s\n" "$$test" "$$result" "$$run_log" | tee -a "$$summary_file"; \
	done; \
	echo "Summary: $$summary_file"; \
	exit $$status

dirs:
	@mkdir -p "$(LOG_DIR)" "$(WAVE_DIR)"

# Check the local lmgrd/snpslmd pair before every VCS compile. If it has
# disappeared, start it; if lmgrd exists but snpslmd is down, request a reread.
license: check-license-tools dirs
	@license_ok() { \
	  "$(LMUTIL)" lmstat -a -c "$(LICENSE_SERVER)" 2>&1 | grep -q 'snpslmd: UP'; \
	}; \
	if license_ok; then \
	  echo "[LICENSE] UP: $(LICENSE_SERVER)"; \
	else \
	  echo "[LICENSE] unavailable; attempting local recovery"; \
	  if pgrep -u "$(USER)" -x lmgrd >/dev/null 2>&1; then \
	    echo "[LICENSE] lmgrd exists; requesting vendor-daemon reread"; \
	    "$(LMUTIL)" lmreread -c "$(LICENSE_FILE)" >/dev/null 2>&1 || true; \
	  else \
	    echo "[LICENSE] starting $(LMGRD)"; \
	    nohup "$(LMGRD)" -c "$(LICENSE_FILE)" -l "$(LICENSE_LOG)" \
	      </dev/null >/dev/null 2>&1 & \
	  fi; \
	  ready=0; \
	  for second in $$(seq 1 "$(LICENSE_WAIT_SECONDS)"); do \
	    if license_ok; then ready=1; break; fi; \
	    sleep 1; \
	  done; \
	  if [ "$$ready" -ne 1 ]; then \
	    echo "ERROR: Synopsys license did not recover within $(LICENSE_WAIT_SECONDS)s"; \
	    echo "License log: $(LICENSE_LOG)"; \
	    test ! -f "$(LICENSE_LOG)" || tail -n 30 "$(LICENSE_LOG)"; \
	    exit 1; \
	  fi; \
	  echo "[LICENSE] recovered: $(LICENSE_SERVER)"; \
	fi

check-test:
	@case " $(TESTS) " in \
	  *" $(TEST) "*) ;; \
	  *) echo "ERROR: TEST must be one of: $(TESTS) (aliases: write, read)"; exit 1 ;; \
	esac

check-sources:
	@for src in "$(RTL_FILE)" "$(PROJECT_ROOT)/$(TB_FILE)"; do \
	  test -f "$$src" || { echo "ERROR: missing source: $$src"; exit 1; }; \
	done

check-vcs:
	@command -v $(VCS) >/dev/null 2>&1 || \
	  { echo "ERROR: vcs is not in PATH. Source the Synopsys setup script first."; exit 1; }

check-verdi:
	@command -v $(VERDI) >/dev/null 2>&1 || \
	  { echo "ERROR: verdi is not in PATH. Source the Verdi setup script first."; exit 1; }

check-fsdb:
	@test -n "$(VERDI_ROOT)" || \
	  { echo "ERROR: Verdi root was not found. Put verdi on PATH or set VERDI_HOME/NOVAS_HOME."; exit 1; }
	@test -f "$(FSDB_TAB)" || \
	  { echo "ERROR: FSDB PLI table not found: $(FSDB_TAB)"; exit 1; }
	@test -f "$(FSDB_LIB)" || \
	  { echo "ERROR: FSDB PLI library not found: $(FSDB_LIB)"; exit 1; }

check-license-tools:
	@test -x "$(LMUTIL)" || \
	  { echo "ERROR: lmutil not executable: $(LMUTIL)"; exit 1; }
	@test -x "$(LMGRD)" || \
	  { echo "ERROR: lmgrd not executable: $(LMGRD)"; exit 1; }
	@test -f "$(LICENSE_FILE)" || \
	  { echo "ERROR: Synopsys license file not found: $(LICENSE_FILE)"; exit 1; }

env:
	@echo "VCS          : $$(command -v $(VCS) 2>/dev/null || echo NOT_FOUND)"
	@echo "Verdi        : $$(command -v $(VERDI) 2>/dev/null || echo NOT_FOUND)"
	@echo "Verdi auto   : $(if $(VERDI_AUTO_ROOT),$(VERDI_AUTO_ROOT),NOT_FOUND)"
	@echo "VERDI_ROOT   : $(if $(VERDI_ROOT),$(VERDI_ROOT),NOT_SET)"
	@echo "Active test  : $(ACTIVE_TEST)"
	@echo "Selected test: $(TEST)"
	@echo "RTL source   : $(RTL_FILE)"
	@echo "Project root : $(PROJECT_ROOT)"
	@echo "Run root     : $(RUN_ROOT)"

clean: check-test
	@rm -rf -- "$(BUILD_DIR)"
	@rm -f -- "$(COMPILE_LOG)" "$(RUN_LOG)" "$(FSDB_FILE)"

help:
	@echo "AHB slave VCS/Verdi targets"
	@echo "  make all                         VCS compile/run ACTIVE_TEST and generate its FSDB"
	@echo "  make verdi                       Open that FSDB in Verdi"
	@echo "  make regress                     Compile/run all four tests and generate 4 FSDBs"
	@echo "  make run TEST=main               Run the one-write/one-read smoke TB"
	@echo "  make all TEST=error              Temporarily override ACTIVE_TEST"
	@echo "  make run TEST=continuous_write   Compile/run one test"
	@echo "  make run TEST=continuous_read    Compile/run one test"
	@echo "  make run TEST=error              Compile/run one test"
	@echo "  make verdi TEST=read             Open continuous-read FSDB"
	@echo "  make verdi TEST=error            Open ERROR FSDB"
	@echo "  make summary                     Print the latest regression summary"
	@echo "  make env                         Show VCS/Verdi environment detection"
	@echo "  make clean TEST=write            Remove one test's generated products"
	@echo ""
	@echo "Default selection: comment/uncomment the four ACTIVE_TEST lines at the top."
	@echo "If vcs and verdi are on PATH, no VERDI_HOME/NOVAS_HOME export is required."
	@echo "Generated files default to: $(RUN_ROOT)"
