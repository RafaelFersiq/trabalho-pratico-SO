# Trabalho prático: Experimento com Escalonamento Real do Linux

## Sobre
Este projeto investiga o comportamento do escalonador do Linux (CFS) sob diferentes cargas (CPU-bound vs I/O-bound), prioridades (`nice`) e políticas (`chrt`).

## Estrutura
* `src/`: Códigos fonte em C.
* `scripts/`: Códigos de rodagem e análise de testes.
* `bin/`: Executáveis.
* `logs/`: Resultados dos experimentos.

## Como Executar

1. **Compilar todos os programas:**
   ```bash
   make

2. **Rodar testes específicos**
   ```bash
   # Sem estatísticas
   make <nome_do_teste> 
   # Com estatísticas
   make stats t=<nome_do_teste>

3. **Rodas testes em grupos**
   ```bash
   # Todos
   make run_all
   # Grupo CFS
   make run_group_cfs
   # Grupo FIFO
   make run_group_fifo
   # Grupo RR
   make run_group_rr

4. **Rodar bateria de testes**
   ```bash
   make stats_all

5. **Limpar logs e executáveis**
   ```bash
   make clean