# Configurações Gerais
CC = gcc
CFLAGS = -Wall -O0
SRC_DIR = src
BIN_DIR = bin
BASE_LOG_DIR = logs

# Parâmetros de Carga
FIB_N = 45
IO_ITERS = 1000000
CORE_ID = 0

# Configurção de Caminhos de Log
ifdef LOG_PATH
    CURRENT_LOG_DIR = $(LOG_PATH)
    LOG_FILE = $(CURRENT_LOG_DIR)/run_latest.txt
else
    CURRENT_LOG_DIR = $(BASE_LOG_DIR)
    LOG_FILE = $(CURRENT_LOG_DIR)/$@.txt
endif

MKDIR_P = mkdir -p
TIME_BIN = /usr/bin/time
FMT_DATA = | PID: %P | Real: %e | User: %U | Sys: %S | CPU: %P

# WRAPPER DE ENERGIA
ifdef energy
    WRAPPER = perf stat -e power/energy-pkg/ -x, 2>&1
else
    WRAPPER = 
endif

# Alvos de Compilação

all: directories $(BIN_DIR)/cpu_bound $(BIN_DIR)/io_bound

directories:
	@$(MKDIR_P) $(BIN_DIR)
	@$(MKDIR_P) $(BASE_LOG_DIR)
	@$(MKDIR_P) $(CURRENT_LOG_DIR)

$(BIN_DIR)/cpu_bound: $(SRC_DIR)/cpu_bound.c
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR)/io_bound: $(SRC_DIR)/io_bound.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -rf $(BIN_DIR) $(BASE_LOG_DIR) *.tmp

# TESTES SEM POLÍTICA ESPECÍFICA (CFS)

test_cfs_cpucpu_diff_cores: all
	@echo "--- [CFS] CPU (-10) x CPU (+19) em Cores Diferentes ---"
	@sudo -v
	@# Cria o diretório caso não exista (segurança extra)
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) $(TIME_BIN) -f "Label: HIGH_PRIO_(-10) $(FMT_DATA)" nice -n -10 $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) $(TIME_BIN) -f "Label: LOW_PRIO_(+19)  $(FMT_DATA)" nice -n 19 $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

test_cfs_cpucpu_same_core: all
	@echo "--- [CFS] CPU (-10) x CPU (+19) no Core $(CORE_ID) ---"
	@sudo -v
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) taskset -c $(CORE_ID) $(TIME_BIN) -f "Label: HIGH_PRIO_(-10) $(FMT_DATA)" nice -n -10 $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) taskset -c $(CORE_ID) $(TIME_BIN) -f "Label: LOW_PRIO_(+19)  $(FMT_DATA)" nice -n 19 $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

test_cfs_ioio_diff_cores: all
	@echo "--- [CFS] I/O (-10) x I/O (+19) em Cores Diferentes ---"
	@sudo -v
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) $(TIME_BIN) -f "Label: IO_HIGH_PRIO $(FMT_DATA)" nice -n -10 $(BIN_DIR)/io_bound $(IO_ITERS) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) $(TIME_BIN) -f "Label: IO_LOW_PRIO  $(FMT_DATA)" nice -n 19 $(BIN_DIR)/io_bound $(IO_ITERS) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

test_cfs_ioio_same_core: all
	@echo "--- [CFS] I/O (-10) x I/O (+19) no Core $(CORE_ID) ---"
	@sudo -v
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) taskset -c $(CORE_ID) $(TIME_BIN) -f "Label: IO_HIGH_PRIO $(FMT_DATA)" nice -n -10 $(BIN_DIR)/io_bound $(IO_ITERS) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) taskset -c $(CORE_ID) $(TIME_BIN) -f "Label: IO_LOW_PRIO  $(FMT_DATA)" nice -n 19 $(BIN_DIR)/io_bound $(IO_ITERS) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

test_cfs_cpuio_same_core: all
	@echo "--- [CFS] CPU (0) x I/O (0) no Core $(CORE_ID) ---"
	@sudo -v
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) taskset -c $(CORE_ID) $(TIME_BIN) -f "Label: CPU_NORMAL $(FMT_DATA)" nice -n 0 $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) taskset -c $(CORE_ID) $(TIME_BIN) -f "Label: IO_NORMAL  $(FMT_DATA)" nice -n 0 $(BIN_DIR)/io_bound $(IO_ITERS) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

# TESTES COM PROCESSOS EM FIFO (MESMO CORE)

test_fifo_cpucpu: all
	@echo "--- [FIFO] CPU (Prio 50) x CPU (Prio 20) no Core $(CORE_ID) ---"
	@sudo -v
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) taskset -c $(CORE_ID) chrt -f 50 $(TIME_BIN) -f "Label: FIFO_HIGH_(50) $(FMT_DATA)" $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) taskset -c $(CORE_ID) chrt -f 20 $(TIME_BIN) -f "Label: FIFO_LOW_(20)  $(FMT_DATA)" $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

test_fifo_ioio: all
	@echo "--- [FIFO] I/O (Prio 50) x I/O (Prio 20) no Core $(CORE_ID) ---"
	@sudo -v
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) taskset -c $(CORE_ID) chrt -f 50 $(TIME_BIN) -f "Label: FIFO_IO_HIGH $(FMT_DATA)" $(BIN_DIR)/io_bound $(IO_ITERS) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) taskset -c $(CORE_ID) chrt -f 20 $(TIME_BIN) -f "Label: FIFO_IO_LOW  $(FMT_DATA)" $(BIN_DIR)/io_bound $(IO_ITERS) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

test_fifo_cpuio: all
	@echo "--- [FIFO] CPU (Prio 50) x I/O (Prio 50) no Core $(CORE_ID) ---"
	@sudo -v
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) taskset -c $(CORE_ID) chrt -f 50 $(TIME_BIN) -f "Label: FIFO_CPU_50 $(FMT_DATA)" $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) taskset -c $(CORE_ID) chrt -f 50 $(TIME_BIN) -f "Label: FIFO_IO_50  $(FMT_DATA)" $(BIN_DIR)/io_bound $(IO_ITERS) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

test_fifo_mixed_cpu_fifo: all
	@echo "--- [MISTO] CPU (FIFO 99) x I/O (Normal) no Core $(CORE_ID) ---"
	@sudo -v
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) taskset -c $(CORE_ID) chrt -f 99 $(TIME_BIN) -f "Label: FIFO_CPU_99 $(FMT_DATA)" $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) taskset -c $(CORE_ID) $(TIME_BIN) -f "Label: CFS_IO_NORMAL $(FMT_DATA)" $(BIN_DIR)/io_bound $(IO_ITERS) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

test_fifo_mixed_io_fifo: all
	@echo "--- [MISTO] CPU (Normal) x I/O (FIFO 99) no Core $(CORE_ID) ---"
	@sudo -v
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) taskset -c $(CORE_ID) $(TIME_BIN) -f "Label: CFS_CPU_NORMAL $(FMT_DATA)" $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) taskset -c $(CORE_ID) chrt -f 99 $(TIME_BIN) -f "Label: FIFO_IO_99     $(FMT_DATA)" $(BIN_DIR)/io_bound $(IO_ITERS) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

# TESTES COM PROCESSOS EM RR (MESMO CORE)

test_rr_cpucpu: all
	@echo "--- [RR] CPU (Prio 50) x CPU (Prio 50) no Core $(CORE_ID) ---"
	@sudo -v
	@$(MKDIR_P) $(CURRENT_LOG_DIR)
	@echo "Timestamp: $$(date)" > $(LOG_FILE)
	@sudo $(WRAPPER) taskset -c $(CORE_ID) chrt -r 50 $(TIME_BIN) -f "Label: RR_CPU_A $(FMT_DATA)" $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid1=$$! ; \
	sudo $(WRAPPER) taskset -c $(CORE_ID) chrt -r 50 $(TIME_BIN) -f "Label: RR_CPU_B $(FMT_DATA)" $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_FILE) 2>&1 & pid2=$$! ; \
	wait $$pid1 $$pid2
	@cat $(LOG_FILE)
	@echo "Log salvo em: $(LOG_FILE)"

# AUTOMAÇÃO DE TESTES (RODAR GRUPOS)

run_all: run_group_cfs run_group_fifo run_group_rr
	@echo "=== TODOS OS TESTES CONCLUÍDOS ==="

run_group_cfs:
	@echo "=== GRUPO CFS ==="
	@$(MAKE) test_cfs_cpucpu_diff_cores
	@$(MAKE) test_cfs_cpucpu_same_core
	@$(MAKE) test_cfs_ioio_diff_cores
	@$(MAKE) test_cfs_ioio_same_core
	@$(MAKE) test_cfs_cpuio_same_core

run_group_fifo:
	@echo "=== GRUPO FIFO ==="
	@$(MAKE) test_fifo_cpucpu
	@$(MAKE) test_fifo_ioio
	@$(MAKE) test_fifo_cpuio
	@$(MAKE) test_fifo_mixed_cpu_fifo
	@$(MAKE) test_fifo_mixed_io_fifo

run_group_rr:
	@echo "=== GRUPO RR ==="
	@$(MAKE) test_rr_cpucpu

# Atalhos para rodar estatísticas

stats:
	@if [ -z "$(t)" ]; then \
		echo "Erro: Especifique o teste. Ex: make stats t=test_fifo_cpucpu"; \
	else \
		./scripts/run_stats.sh $(t); \
	fi

stats_all:
	@echo "=== INICIANDO BATERIA COMPLETA DE ESTATÍSTICAS (Isso vai demorar!) ==="
	@$(MAKE) stats t=test_cfs_cpucpu_diff_cores
	@$(MAKE) stats t=test_cfs_cpucpu_same_core
	@$(MAKE) stats t=test_cfs_ioio_diff_cores
	@$(MAKE) stats t=test_cfs_ioio_same_core
	@$(MAKE) stats t=test_cfs_cpuio_same_core
	@$(MAKE) stats t=test_fifo_cpucpu
	@$(MAKE) stats t=test_fifo_ioio
	@$(MAKE) test_fifo_cpuio
	@$(MAKE) stats t=test_fifo_mixed_cpu_fifo
	@$(MAKE) stats t=test_fifo_mixed_io_fifo
	@$(MAKE) stats t=test_rr_cpucpu
	@echo "=== BATERIA COMPLETA CONCLUÍDA. Verifique a pasta logs/ ==="