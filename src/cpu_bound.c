#include <stdio.h>
#include <stdlib.h>

long long fibonacci(int n) {
    if (n <= 1) {
        return n;
    }

    return fibonacci(n - 1) + fibonacci(n - 2);
}

int main(int argc, char *argv[]) {
    int n = 40; 

    if (argc == 2) {
        n = atoi(argv[1]);
    }

    if (n < 0) {
        fprintf(stderr, "Erro: O número deve ser não-negativo.\n");
        return 1;
    }

    printf("Iniciando cálculo CPU-bound (Fibonacci de %d)...\n", n);

    long long resultado = fibonacci(n);

    printf("Cálculo CPU-bound concluído. Resultado: %lld\n", resultado);

    return 0;
}