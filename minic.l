%{
    #include <stdio.h>
    #include "minic.tab.h"
    void error_lexico();
    int erroresLexicos = 0;   
%}

%option yylineno


digito              [0-9]
identificador       [a-zA-a_][a-zA-Z0-9_]{0,15}
entero              {digito}+




%%

[ \n\t]+                            ;
"//"(.*)[\n]                        ;
"/*"([^*]|[*]+[^*/])*[*]+"/"        ;
"("                                 return LPAR;		
")"                                 return RPAR;
";"                                 return SEMICOMA;
","                                 return COMA;
"="                                 return ASSIGNOP;
"+"                                 return MAS;
"-"                                 return MENOS;
"{"                                 return LKEY;
"}"                                 return RKEY;
"/"                                 return DIV;
"*"                                 return POR;
"void"                              return VOID;
"var"                               return VAR;
"const"                             return CONST;
"if"                                return IF;
"else"                              return ELSE;
"while"                             return WHILE;
"print"                             return PRINT;
"read"                              return READ;
"do"                                return DO;
{entero}                            {yylval.cadena = strdup(yytext); return INT;}
{identificador}                     {yylval.cadena = strdup(yytext); return ID; }
\"(\.|[^\"])*\"                     {yylval.cadena = strdup(yytext); return STRING; }
.                                   error_lexico();


%%

void error_lexico(){
    erroresLexicos++;
    printf("Error lexico en la linea %d: %s\n", yylineno, yytext);
}