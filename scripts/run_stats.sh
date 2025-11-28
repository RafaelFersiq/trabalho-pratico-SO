#!/bin/bash

# Configuração
TESTE=$1
RODADAS=20

if [ -z "$TESTE" ]; then
    echo "Erro: Especifique o teste. Ex: ./scripts/run_stats.sh test_fifo_cpucpu"
    exit 1
fi

TEST_DIR="logs/${TESTE}"
LOG_TEMP="${TEST_DIR}/temp_stats.txt"
LOG_FINAL="${TEST_DIR}/stats_final.txt"

# Cria a pasta do teste se não existir
mkdir -p "$TEST_DIR"

echo "=================================================="
echo " INICIANDO ESTATÍSTICA PARA: $TESTE"
echo " Pasta de saída: $TEST_DIR"
echo "=================================================="

rm -f "$LOG_TEMP"
echo "Timestamp: $(date)" > "$LOG_FINAL"

# Loop de Execução
for i in $(seq 1 $RODADAS); do
    printf "Rodada $i/$RODADAS... "
    make "$TESTE" energy=1 LOG_PATH="$TEST_DIR" > /dev/null 2>&1
    tail -n 20 "${TEST_DIR}/run_latest.txt" | grep -E "Real:|,Joules" >> "$LOG_TEMP"
    cp "${TEST_DIR}/run_latest.txt" "${TEST_DIR}/rodada_${i}.txt"
    echo "OK"
done

# Extração e Cálculo
echo "--------------------------------------------------"
echo "Calculando médias..."

export LC_NUMERIC=C

# Cálculo de tempo
MEDIA_TEMPO=$(grep "Real:" "$LOG_TEMP" | sed -E 's/.*Real: ([0-9.]+).*/\1/' | awk '{sum+=$1} END {if (NR>0) printf "%.3f", sum/NR; else print "N/A"}')

# Cálculo de energia
MEDIA_ENERGIA=$(grep ",Joules" "$LOG_TEMP" | awk -F, '{sum+=$1} END {if (NR>0) printf "%.2f", sum/NR; else print "N/A"}')

echo ""
echo "RESULTADO FINAL ($TESTE):"
echo "MÉDIA TEMPO:   ${MEDIA_TEMPO} s"
echo "MÉDIA ENERGIA: ${MEDIA_ENERGIA} J"
echo "--------------------------------------------------"

# Salva no log final
echo "Média Tempo ($RODADAS rodadas):   ${MEDIA_TEMPO} s" >> "$LOG_FINAL"
echo "Média Energia ($RODADAS rodadas): ${MEDIA_ENERGIA} J" >> "$LOG_FINAL"
echo "" >> "$LOG_FINAL"
echo "--- Detalhes Brutos ---" >> "$LOG_FINAL"
cat "$LOG_TEMP" >> "$LOG_FINAL"