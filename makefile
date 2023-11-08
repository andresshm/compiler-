compilar : main.c lex.yy.c minic.tab.c listaSimbolos.c listaCodigo.c
	gcc main.c lex.yy.c minic.tab.c listaSimbolos.c listaCodigo.c -lfl -o miniC

lexico : minic.l minic.tab.h
	flex minic.l

gramatica : minic.y listaSimbolos.h listaCodigo.h
	bison -d -v minic.y

limpiar: 
	rm -f minic.tab.* lex.yy.c miniC minic.output

run: miniC prueba.txt
	./miniC prueba.txt