#include <stdio.h>
#include <stdlib.h> 

extern int erroresLexicos;
extern int erroresSintacticos;
extern int erroresSemanticos;
extern int yyparse();
extern FILE *yyin;

int errores(){
    int totalErrores = (erroresLexicos + erroresSintacticos + erroresSemanticos);
    return totalErrores;
}


int main(int argc, char *argv[]){
    if (argc != 2){
        printf("Uso correcto: %s fichero\n", argv[0]);
        exit(1);
    }
    yyin = fopen(argv[1], "r");
    if (yyin == 0){
        printf("No se puede abrir %s\n",argv[1]);
        exit(2);
    }


    yyparse();
    
    if (errores() != 0){
        printf("%d Errores lexicos\n", erroresLexicos);
        printf("%d Errores sintacticos\n", erroresSintacticos);
        printf("%d Errores semanticos\n", erroresSemanticos);
    }
    fclose(yyin);
}