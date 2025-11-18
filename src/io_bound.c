#include <stdio.h>
#include <stdlib.h> 
#include <string.h> 

#define BLOCK_SIZE 4096 
#define DEFAULT_ITERATIONS 50000 

int main(int argc, char *argv[]) {
    int iterations = DEFAULT_ITERATIONS;
    const char *filename = "temp_io_file.tmp"; 

    if (argc == 2) {
        iterations = atoi(argv[1]);
    }

    FILE *file;
    char buffer[BLOCK_SIZE];
    memset(buffer, 'X', BLOCK_SIZE);

    printf("Iniciando teste I/O-bound (escrevendo %d blocos de %d bytes em '%s')...\n", 
           iterations, BLOCK_SIZE, filename);

    file = fopen(filename, "w");
    if (file == NULL) {
        perror("Erro ao abrir arquivo para escrita");
        return 1;
    }

    for (int i = 0; i < iterations; i++) {
        
        if (fwrite(buffer, 1, BLOCK_SIZE, file) != BLOCK_SIZE) {
            perror("Erro ao escrever no arquivo");
            fclose(file);
            remove(filename);
            return 1;
        }

        fflush(file);
    }

    fclose(file);

    if (remove(filename) != 0) {
        perror("Erro ao remover arquivo temporário");
    }

    printf("Teste I/O-bound concluído. Arquivo temporário removido.\n");
    return 0;
}