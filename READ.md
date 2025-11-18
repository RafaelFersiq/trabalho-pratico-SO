# Trabalho prático: Experimento com Escalonamento Real do Linux

## Sobre
Este projeto investiga o comportamento do escalonador do Linux (CFS) sob diferentes cargas (CPU-bound vs I/O-bound) e prioridades (`nice`).

## Estrutura
* `src/`: Códigos fonte em C.
* `bin/`: Executáveis (gerados após compilação).
* `logs/`: Resultados dos experimentos.

## Como Executar

1. **Compilar todos os programas:**
   ```bash
   make