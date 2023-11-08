%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "listaSimbolos.h"
    #include "listaCodigo.h"
    extern int yylex();
    void yyerror(const char *s);
    extern int yylineno;  
    extern int erroresLexicos;  
    int erroresSintacticos = 0;
    int erroresSemanticos = 0;
    Lista tablaSimb;
    Tipo tipo;
    char registros[10];
    int contCadenas = 1;
    int contador_etiq=1;
    int noHayErrores();
    char *obtenerReg();
    void liberarReg(char *reg);
    void imprimirCodigo(ListaC codigo);
    char *nuevaEtiqueta();
    char *concatena(char c, char *l);
%}

%code requires {
        #include "listaCodigo.h"
}


%union{
    char *cadena;
    ListaC codigo;
}

%token MAS MENOS POR DIV COMA SEMICOMA LPAR RPAR LKEY RKEY ASSIGNOP PRINT READ VOID VAR CONST IF ELSE WHILE DO
%token <cadena> ID 
%token <cadena> INT  
%token <cadena> STRING 

%type <codigo> program declarations identifier_list asig  statement_list statement print_list print_item read_list expression

%left MAS MENOS
%left POR DIV
%precedence UMENOS

%%

program :  {tablaSimb = creaLS(); for(int i=0;i<10;i++){registros[i] = 0; }} VOID ID LPAR RPAR LKEY declarations statement_list RKEY  {
                if(noHayErrores()==1){
                       
                        concatenaLC($7, $8);
                        liberaLC($8);
                        Operacion oper;
                        oper.op = "\n##############\n# Fin\n   li";
                        oper.res = "$v0";
                        oper.arg1 = "10";
                        oper.arg2 = NULL;
                        insertaLC($7, finalLC($7), oper);
                        Operacion oper2;
                        oper2.op = "syscall";
                        oper2.res = NULL;
                        oper2.arg1 = NULL;
                        oper2.arg2 = NULL;
                        insertaLC($7, finalLC($7), oper2);
                        imprimirTablaS(tablaSimb);
                        imprimirCodigo($7);
                        liberaLS(tablaSimb);
                        liberaLC($7);
                }
        }
;



declarations : declarations VAR {tipo = VARIABLE; } identifier_list SEMICOMA {
                                                                        if(noHayErrores()){
                                                                                $$ = $1;
                                                                                concatenaLC($$, $4);
                                                                                liberaLC($4);
                                                                                
                                                                        }
                                                                        
                                                                }
        | declarations CONST { tipo = CONSTANTE; }identifier_list SEMICOMA {
                                                                        if(noHayErrores()){
                                                                                $$ = $1;
                                                                                concatenaLC($$, $4);
                                                                                liberaLC($4);
                                                                                
                                                                        }
                                                                }
        | %empty        { if(noHayErrores()){
                                $$ = creaLC();
                                }
                        }
        ;

identifier_list : asig      { if(noHayErrores()){
                                $$ = $1;
                                }
                        }
        |   identifier_list COMA asig    { if(noHayErrores()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                liberaLC($3);
                                                }                      
                                        }
        ;

asig : ID     {
                if(!perteneceTablaS(tablaSimb, $1)){
                        anadeEntrada(tablaSimb, $1, tipo);
                        if(noHayErrores()){
                        $$ = creaLC();
                        }                        
                }else{
                        printf("Variable %s ya declarada\n", $1);
                        erroresSemanticos++;
                }
                
                
                
                }
        | ID ASSIGNOP expression       {
                
                                        if(!perteneceTablaS(tablaSimb, $1)){
                                                anadeEntrada(tablaSimb, $1, tipo);
                                                if(noHayErrores()){
                                                $$ = $3;
                                                Operacion oper;
                                                oper.op = "sw";
                                                oper.res = recuperaResLC($3);
                                                oper.arg1 = concatena('_', $1);
                                                oper.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper);
                                                liberarReg(oper.res);
                                        }else{
                                                erroresSemanticos++; 
                                                printf("Variable %s ya declarada\n", $1);} 
                                                }
                }
        ;

statement_list : statement_list  statement      { if(noHayErrores()){
                                                        $$ = $1;
                                                        concatenaLC($$, $2);
                                                        liberaLC($2);
                                                        }        
                                                }
        | %empty                                { if(noHayErrores()){
                                                        $$ = creaLC(); 
                                                        }
                                                }
        ;

statement : ID ASSIGNOP expression SEMICOMA    {
                                        if(!perteneceTablaS(tablaSimb, $1)){
                                             printf("Variable %s no declarada\n", $1);
                                             erroresSemanticos++;
                                        }else if(esConstante(tablaSimb, $1)){
                                             printf("Asignacion a constante\n");
                                             erroresSemanticos++;
                                        }
                                        
                                        if(noHayErrores()){
                                                        $$ = $3;
                                                        Operacion oper;
                                                        oper.op = "sw";
                                                        oper.res = recuperaResLC($3);
                                                        oper.arg1 = concatena('_', $1);
                                                        oper.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), oper);
                                                        liberarReg(oper.res);
                                        }
                                  
                                        }
        | LKEY statement_list RKEY      { if(noHayErrores()){
                                                $$ = $2;
                                        }
                                        }
        | IF LPAR expression RPAR statement ELSE statement    {if(noHayErrores()){
                                                                        $$ = $3;
                                                                        Operacion oper;
                                                                        oper.op = "beqz";
                                                                        oper.res = recuperaResLC($3);
                                                                        char *label = nuevaEtiqueta();
                                                                        oper.arg1 = label;
                                                                        oper.arg2 = NULL;
                                                                        insertaLC($$, finalLC($$), oper);
                                                                        concatenaLC($$, $5);
                                                                        liberarReg(oper.res);
                                                                        Operacion oper2;
                                                                        oper2.op = "b";
                                                                        char *label2 = nuevaEtiqueta();
                                                                        oper2.res = label2;
                                                                        oper2.arg1 = NULL;
                                                                        oper2.arg2 = NULL;
                                                                        insertaLC($$, finalLC($$), oper2);
                                                                        Operacion oper3;
                                                                        oper3.op = "label";
                                                                        oper3.res = label;
                                                                        oper3.arg1 = NULL;
                                                                        oper3.arg2 = NULL;
                                                                        insertaLC($$, finalLC($$), oper3);
                                                                        concatenaLC($$, $7);
                                                                        Operacion oper4;
                                                                        oper4.op = "label";
                                                                        oper4.res = label2;
                                                                        oper4.arg1 = NULL;
                                                                        oper4.arg2 = NULL;
                                                                        insertaLC($$, finalLC($$), oper4);
                                                                        liberaLC($5);
                                                                        liberaLC($7);
                                                                        }
                                                                }

        | IF LPAR expression RPAR statement     { if(noHayErrores()){
                                                        $$ = $3;
                                                        char *label = nuevaEtiqueta();
                                                        Operacion oper;
                                                        oper.op = "beqz";
                                                        oper.res = recuperaResLC($3);
                                                        oper.arg1 = label;
                                                        oper.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), oper);
                                                        concatenaLC($$, $5);
                                                        liberarReg(oper.res);
                                                        liberaLC($5);
                                                        Operacion oper2;
                                                        oper2.op = "label";
                                                        oper2.res = label;
                                                        oper2.arg1 = NULL;
                                                        oper2.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), oper2);
                                                }
                                                }
        | WHILE LPAR expression RPAR statement  { if(noHayErrores()){
                                                        $$ = creaLC();
                                                        char *label = nuevaEtiqueta();
                                                        Operacion oper;
                                                        oper.op = "label";
                                                        oper.res = label;
                                                        oper.arg1 = NULL;
                                                        oper.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), oper);
                                                        concatenaLC($$, $3);
                                                        Operacion oper2;
                                                        oper2.op = "beqz";
                                                        oper2.res = recuperaResLC($3);
                                                        char *label2 = nuevaEtiqueta();
                                                        oper2.arg1 = label2;
                                                        oper2.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), oper2);
                                                        concatenaLC($$, $5);
                                                        Operacion oper3;
                                                        oper3.op = "b";
                                                        oper3.res = label;
                                                        oper3.arg1 = NULL;
                                                        oper3.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), oper3);
                                                        Operacion oper4;
                                                        oper4.op = "label";
                                                        oper4.res = label2;
                                                        oper4.arg1 = NULL;
                                                        oper4.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), oper4);
                                                        liberaLC($3);
                                                        liberaLC($5);
                                                        liberarReg(oper2.res);
                                                        }                                                
                                                }
        | PRINT print_list SEMICOMA                { if(noHayErrores()){
                                                        $$ = $2;
                                                        }       
                                                }
        | READ read_list SEMICOMA                  { if(noHayErrores()){
                                                        $$ = $2;
                                                        }
                                                }
        | DO statement WHILE LPAR expression RPAR SEMICOMA {
                if(noHayErrores()){
                        $$ = creaLC();
                        char *label = nuevaEtiqueta();
                        Operacion oper;
                        oper.op = "label";
                        oper.res = label;
                        oper.arg1 = NULL;
                        oper.arg2 = NULL;
                        insertaLC($$, finalLC($$), oper);
                        concatenaLC($$, $2);
                        liberaLC($2);
                        concatenaLC($$,$5);
                        Operacion oper2;
                        oper2.op = "bnez";
                        oper2.res = recuperaResLC($5);
                        oper2.arg1 = label;
                        oper2.arg2 = NULL;
                        insertaLC($$, finalLC($$), oper2);
                        liberaLC($5);
                        liberarReg(oper2.res);
                }
        }                     
        ;

print_list : print_item         { if(noHayErrores()){
                                        $$ = $1;
                                        }
                                }
        | print_list COMA print_item { if(noHayErrores()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                liberaLC($3);
                                                }                                        
                                        }
        ;

print_item : expression             { if(noHayErrores()){
                                                $$ = $1;
                                                Operacion oper;
                                                oper.op = "move";
                                                oper.res = "$a0";
                                                oper.arg1 = recuperaResLC($1);
                                                oper.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper);
                                                liberarReg(oper.arg1);
                                                Operacion oper2;
                                                oper2.op = "li";
                                                oper2.res = "$v0";
                                                oper2.arg1 = "1";
                                                oper2.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper2);
                                                Operacion oper3;
                                                oper3.op = "syscall";
                                                oper3.arg1 = NULL;
                                                oper3.arg2 = NULL;
                                                oper3.res = NULL;
                                                insertaLC($$, finalLC($$), oper3);
                                                }                                        
                                        }
        |       STRING                  { if(noHayErrores()){
                                                Simbolo s = {$1, CADENA, contCadenas};
                                                insertaLS(tablaSimb,finalLS(tablaSimb),s); 
                                                $$ = creaLC();
                                                char *label;
                                                asprintf(&label, "$str%d", contCadenas);
                                                contCadenas++;
                                                Operacion oper;
                                                oper.op = "la";
                                                oper.res = "$a0";
                                                oper.arg1 = label;
                                                oper.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper);
                                                Operacion oper2;
                                                oper2.op = "li";
                                                oper2.res = "$v0";
                                                oper2.arg1 = "4";
                                                oper2.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper2);
                                                Operacion oper3;
                                                oper3.op = "syscall";
                                                oper3.res = NULL;
                                                oper3.arg1 = NULL;
                                                oper3.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper3);
                                                }                                        
                                        }
        ;

read_list : ID                  { if(!perteneceTablaS(tablaSimb, $1)){
                                        printf("Variable %s no declarada\n", $1);
                                        erroresSemanticos++;
                                }else if(esConstante(tablaSimb, $1)){
                                        printf("Asignacion a constante\n");
                                        erroresSemanticos++;
                                }
                                        if(noHayErrores()){
                                                $$ = creaLC();
                                                Operacion oper;
                                                oper.op = "li";
                                                oper.res = "$v0";
                                                oper.arg1 = "5";
                                                oper.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper);
                                                Operacion oper2;
                                                oper2.op = "syscall";
                                                oper2.res = NULL;
                                                oper2.arg1 =NULL;
                                                oper2.arg2  =NULL;
                                                insertaLC($$, finalLC($$), oper2);
                                                Operacion oper3;
                                                oper3.op = "sw";
                                                oper3.res = "$v0";
                                                oper3.arg1 = concatena('_', $1);
                                                oper3.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper3);
                                                }
                                        }
        | read_list COMA ID {   if(!perteneceTablaS(tablaSimb, $3)){
                                        printf("Variable %s no declarada\n", $3);
                                        erroresSemanticos++;
                                }else if(esConstante(tablaSimb, $3)){
                                        printf("Asignacion a constante\n");
                                        erroresSemanticos++;
                                } 
                                        if(noHayErrores()){
                                                $$ = $1;
                                                Operacion oper;
                                                oper.op = "li";
                                                oper.res = "$v0";
                                                oper.arg1 = "5";
                                                oper.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper);
                                                Operacion oper2;
                                                oper2.op = "syscall";
                                                oper2.res = NULL;
                                                oper2.arg1 = NULL;
                                                oper2.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper2);
                                                Operacion oper3;
                                                oper3.op = "sw";
                                                oper3.res = "$v0";
                                                oper3.arg1 = concatena('_', $3);
                                                oper3.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper3);
                                        }
                                }
        ;
expression : expression MAS expression { if(noHayErrores()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                Operacion oper;
                                                oper.op = "add";
                                                oper.res = recuperaResLC($1);
                                                oper.arg1 = recuperaResLC($1);
                                                oper.arg2 = recuperaResLC($3);
                                                insertaLC($$, finalLC($$), oper);
                                                liberaLC($3);
                                                liberarReg(oper.arg2);
                                                }
                                        }

        | expression MENOS expression { if(noHayErrores()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                Operacion oper;
                                                oper.op = "sub";
                                                oper.res = recuperaResLC($1);
                                                oper.arg1 = recuperaResLC($1);
                                                oper.arg2 = recuperaResLC($3);
                                                insertaLC($$, finalLC($$), oper);
                                                liberaLC($3);
                                                liberarReg(oper.arg2);
                                                }                                        
                                        }

        | expression POR expression     { if(noHayErrores()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                Operacion oper;
                                                oper.op = "mul";
                                                oper.res = recuperaResLC($1);
                                                oper.arg1 = recuperaResLC($1);
                                                oper.arg2 = recuperaResLC($3);
                                                insertaLC($$, finalLC($$), oper);
                                                liberaLC($3);
                                                liberarReg(oper.arg2);                                                 
                                                }                                        
                                        }

        | expression DIV expression   { if(noHayErrores()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                Operacion oper;
                                                oper.op = "div";
                                                oper.res = recuperaResLC($1);
                                                oper.arg1 = recuperaResLC($1);
                                                oper.arg2 = recuperaResLC($3);
                                                insertaLC($$, finalLC($$), oper);
                                                liberaLC($3);
                                                liberarReg(oper.arg2);                                                
                                                }                                        
                                        }

        | MENOS expression   %prec UMENOS { if(noHayErrores()){
                                                $$ = $2;
                                                Operacion oper;
                                                oper.op = "neg";
                                                oper.res = recuperaResLC($2);
                                                oper.arg1 = recuperaResLC($2);
                                                oper.arg2 = NULL;
                                                insertaLC($$, finalLC($$), oper);    
                                                }                                        
                                        }

        | LPAR expression RPAR        { if(noHayErrores()){$$ = $2;} }

        | ID                  { if(!perteneceTablaS(tablaSimb, $1)){
                                        printf("Variable %s no declarada \n",$1); 
                                        erroresSemanticos++; }
                                if(noHayErrores()){
                                        $$ = creaLC();
                                        Operacion oper;
                                        oper.op = "lw";
                                        oper.res = obtenerReg();
                                        oper.arg1 = concatena('_', $1);
                                        oper.arg2 = NULL;
                                        insertaLC($$, finalLC($$), oper);
                                        guardaResLC($$, oper.res);
                                        }
                                }

        | INT                  { if(noHayErrores()){
                                        $$ = creaLC();
                                        Operacion oper;
                                        oper.op = "li";
                                        oper.res = obtenerReg();
                                        oper.arg1 = $1;
                                        oper.arg2 = NULL;
                                        insertaLC($$, finalLC($$), oper);
                                        guardaResLC($$, oper.res);
                                        }                                
                                }
        ;


%%

void yyerror(const char *s){
    printf("Error: %s\n", s);
    erroresSintacticos++;
}

char *concatena(char c, char *l){
        char *iden;
        asprintf(&iden, "%c%s",c ,l);
        return iden;
} 


int noHayErrores(){
        int errores = (erroresLexicos + erroresSintacticos + erroresSemanticos);
        if(errores==0) return 1;
        return 0;
}

char *obtenerReg(){
        int i;
        for(i = 0; i < 10; i++){
                if(registros[i] == 0){
                        break;
                }
        }
        if(i == 10){
                printf("No quedan registros libres\n");
                exit(1);/*necesita stdlib*/
        }
        registros[i] = 1;
        char *reg;
        asprintf(&reg, "$t%d", i);
        return reg;
}

void liberarReg(char *reg){
        int i = reg[2] - '0';//48
        registros[i] = 0;
}

void imprimirCodigo(ListaC codigo){
        PosicionListaC p = inicioLC(codigo);
        while (p != finalLC(codigo)) {
                Operacion oper = recuperaLC(codigo,p);

                if(!strcmp(oper.op, "label")){
                        printf("%s:\n", oper.res);
                }else{
                        printf("   %s",oper.op);
                        if(oper.res) printf(" %s",oper.res);
                        if(oper.arg1) printf(", %s",oper.arg1);
                        if(oper.arg2) printf(", %s",oper.arg2);
                        printf("\n");
                }

                p = siguienteLC(codigo,p);
        }
}

char *nuevaEtiqueta() {
        char *aux;
        asprintf(&aux,"$l%d",contador_etiq++);
        return aux;
}

