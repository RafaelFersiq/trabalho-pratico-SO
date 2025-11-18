# --- Configurações ---
CC = gcc
CFLAGS = -Wall -O0
SRC_DIR = src
BIN_DIR = bin
LOG_DIR = logs

# Parâmetros dos Testes
FIB_N = 49
IO_ITERS = 5000000

# --- Alvos Principais ---

# Garante que as pastas bin e logs existam antes de compilar
all: directories $(BIN_DIR)/cpu_bound $(BIN_DIR)/io_bound $(BIN_DIR)/fork_test

directories:
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(LOG_DIR)

# --- Compilação (Lê de SRC, grava em BIN) ---

$(BIN_DIR)/cpu_bound: $(SRC_DIR)/cpu_bound.c
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR)/io_bound: $(SRC_DIR)/io_bound.c
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR)/fork_test: $(SRC_DIR)/fork_test.c
	$(CC) $(CFLAGS) -o $@ $<

# --- Experimentos ---

# 1. CPU vs CPU (Nice)
# Salva a saída num arquivo de log para você analisar depois
run_cpuxcpu: all
	@echo "--- Rodando Experimento CPU x CPU ---"
	@echo "Resultados serão salvos em $(LOG_DIR)/exp_cpuxcpu.txt"
	@sudo -v
	@echo "Timestamp: $$(date)" > $(LOG_DIR)/exp_cpuxcpu.txt
	@sudo time -f "HIGH_PRIO (-10): Real %E, User %U, Sys %S" nice -n -10 $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_DIR)/exp_cpuxcpu.txt 2>&1 & \
	pid_high=$$! ; \
	time -f "LOW_PRIO (+19):  Real %E, User %U, Sys %S" nice -n 19 $(BIN_DIR)/cpu_bound $(FIB_N) >> $(LOG_DIR)/exp_cpuxcpu.txt 2>&1 & \
	pid_low=$$! ; \
	wait $$pid_high ; \
	wait $$pid_low
	@cat $(LOG_DIR)/exp_cpuxcpu.txt

# 2. Controle (CPU vs IO)
run_control: all
	@echo "--- Rodando Grupo de Controle ---"
	$(BIN_DIR)/fork_test

# --- Limpeza ---
clean:
	rm -rf $(BIN_DIR) *.tmp