#include <stdio.h>
#include <stdlib.h>     // Para atoi, exit
#include <string.h>     // Para memset
#include <unistd.h>     // Para fork, getpid
#include <sys/wait.h>   // Para waitpid
#include <sys/types.h>  // Para pid_t
#include <sys/time.h>   // Para gettimeofday

// --- Configurações dos Processos ---
#define FIB_N 49               // "Carga" do processo CPU-bound (~30s)
#define IO_ITERATIONS 5000000  // "Carga" do processo I/O-bound (~30s)
#define BLOCK_SIZE 4096

double get_elapsed_time(struct timeval *start, struct timeval *end) {
    return (end->tv_sec - start->tv_sec) + (end->tv_usec - start->tv_usec) / 1000000.0;
}

long long fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

void run_io_bound_task(int iterations) {
    struct timeval start, end;
    gettimeofday(&start, NULL); // MARCADOR DE INÍCIO (I/O)

    const char *filename = "temp_io_file.tmp";
    FILE *file;
    char buffer[BLOCK_SIZE];
    memset(buffer, 'X', BLOCK_SIZE);

    printf("[PID %d] I/O-Bound: Iniciando. Escrevendo %d blocos.\n", getpid(), iterations);

    file = fopen(filename, "w");
    if (file == NULL) {
        perror("[PID %d] I/O-Bound: Erro ao abrir arquivo");
        exit(1); 
    }

    for (int i = 0; i < iterations; i++) {
        if (fwrite(buffer, 1, BLOCK_SIZE, file) != BLOCK_SIZE) {
            perror("[PID %d] I/O-Bound: Erro ao escrever");
            fclose(file);
            remove(filename);
            exit(1);
        }
        fflush(file);
    }

    fclose(file);
    remove(filename);

    gettimeofday(&end, NULL); // MARCADOR DE FIM (I/O)
    double elapsed = get_elapsed_time(&start, &end);
    printf("[PID %d] I/O-Bound: Concluído. (Tempo: %.3f segundos)\n", getpid(), elapsed);
}

int main() {
    struct timeval main_start, main_end;
    gettimeofday(&main_start, NULL); // MARCADOR DE INÍCIO (PAI)
    
    pid_t pid_cpu, pid_io;
    int status_cpu, status_io;

    printf("[PID %d] Processo Pai: Criando processo CPU-Bound...\n", getpid());
    
    pid_cpu = fork();

    if (pid_cpu < 0) {
        perror("fork (cpu) falhou");
        return 1;
    }

    if (pid_cpu == 0) {
            // --- Código do Filho 1 (CPU-Bound) ---
            struct timeval start, end;
            gettimeofday(&start, NULL); // MARCADOR DE INÍCIO (CPU)

            printf("[PID %d] CPU-Bound: Iniciando. Calculando Fibonacci(%d)...\n", getpid(), FIB_N);
            long long resultado = fibonacci(FIB_N);
            
            gettimeofday(&end, NULL); // MARCADOR DE FIM (CPU)
            double elapsed = get_elapsed_time(&start, &end);
            
            printf("[PID %d] CPU-Bound: Concluído. Resultado: %lld. (Tempo: %.3f segundos)\n", getpid(), resultado, elapsed);
            exit(0); // Termina o processo filho
            // --- Fim do Código do Filho 1 ---
        }

    // --- Código do Pai (continua aqui) ---
    printf("[PID %d] Processo Pai: Criando processo I/O-Bound...\n", getpid());

    // --- Cria o segundo filho (I/O-Bound) ---
    pid_io = fork();

    if (pid_io < 0) {
        // Erro no fork
        perror("fork (io) falhou");
        return 1;
    }

    if (pid_io == 0) {
        // --- Código do Filho 2 (I/O-Bound) ---
        run_io_bound_task(IO_ITERATIONS);
        exit(0); // Termina o processo filho
        // --- Fim do Código do Filho 2 ---
    }

    // --- Código do Pai (continua aqui) ---
    printf("[PID %d] Processo Pai: Aguardando filhos terminarem (CPU PID: %d, I/O PID: %d).\n", getpid(), pid_cpu, pid_io);

    // Espera pelos dois filhos terminarem.
    // Isso é importante para evitar "processos zumbis".
    waitpid(pid_cpu, &status_cpu, 0);
    waitpid(pid_io, &status_io, 0);

    gettimeofday(&main_end, NULL); // MARCADOR DE FIM (PAI)
    double total_elapsed = get_elapsed_time(&main_start, &main_end);
        
    printf("[PID %d] Processo Pai: Ambos os filhos terminaram. (Tempo Total: %.3f segundos)\n", getpid(), total_elapsed);
        
    return 0;
}