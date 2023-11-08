#include "listaSimbolos.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>
//añadido
#include <stdio.h>

struct PosicionListaRep {
  Simbolo dato;
  struct PosicionListaRep *sig;
};

struct ListaRep {
  PosicionLista cabecera;
  PosicionLista ultimo;
  int n;
};

typedef struct PosicionListaRep *NodoPtr;

Lista creaLS() {
  Lista nueva = malloc(sizeof(struct ListaRep));
  nueva->cabecera = malloc(sizeof(struct PosicionListaRep));
  nueva->cabecera->sig = NULL;
  nueva->ultimo = nueva->cabecera;
  nueva->n = 0;
  return nueva;
}

void liberaLS(Lista lista) {
  while (lista->cabecera != NULL) {
    NodoPtr borrar = lista->cabecera;
    lista->cabecera = borrar->sig;
    free(borrar);
  }
  free(lista);
}

void insertaLS(Lista lista, PosicionLista p, Simbolo s) {
  NodoPtr nuevo = malloc(sizeof(struct PosicionListaRep));
  nuevo->dato = s;
  nuevo->sig = p->sig;
  p->sig = nuevo;
  if (lista->ultimo == p) {
    lista->ultimo = nuevo;
  }
  (lista->n)++;
}

void suprimeLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  NodoPtr borrar = p->sig;
  p->sig = borrar->sig;
  if (lista->ultimo == borrar) {
    lista->ultimo = p;
  }
  free(borrar);
  (lista->n)--;
}

Simbolo recuperaLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  return p->sig->dato;
}

PosicionLista buscaLS(Lista lista, char *nombre) {
  NodoPtr aux = lista->cabecera;
  while (aux->sig != NULL && strcmp(aux->sig->dato.nombre,nombre) != 0) {
    aux = aux->sig;
  }
  return aux;
}

void asignaLS(Lista lista, PosicionLista p, Simbolo s) {
  assert(p != lista->ultimo);
  p->sig->dato = s;
}

int longitudLS(Lista lista) {
  return lista->n;
}

PosicionLista inicioLS(Lista lista) {
  return lista->cabecera;
}

PosicionLista finalLS(Lista lista) {
  return lista->ultimo;
}

PosicionLista siguienteLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  return p->sig;
}


//añadido

int perteneceTablaS(Lista l, char *nombre){
  PosicionLista p = inicioLS(l);
  while(p!=finalLS(l)){
    if(buscaLS(l, nombre)==p){
      return 1;
  }
    p=siguienteLS(l,p);
  } 
  return 0; 
} 


void anadeEntrada(Lista l, char *name, Tipo t){
  Simbolo s = {name, t, 0};
  insertaLS(l, finalLS(l), s);
  
}


int esConstante(Lista l, char *nombre){
  Simbolo s = recuperaLS(l, buscaLS(l, nombre));
  if(s.tipo==2){
    return 1; // si es cte.
  }else{
    return 0; //no es cte.
  }
}


/* Hacemos dos bucles porque lo primero que se inserta 
son las variables, que deben aparecer despues de las cadenas, 
las cuales como se insertan las ultimas por el final de la tabla, 
en un solo bucle, aparecerian primero si recorremos la tabla de 
principio a fin*/
void imprimirTablaS(Lista l){
  PosicionLista pos = inicioLS(l);
  printf("\n##################\n# Seccion de datos\n");
  printf("    .data\n\n");
  while (pos != finalLS(l)) {
    Simbolo s = recuperaLS(l,pos);
    if (s.tipo == CADENA){
        printf("$str%d:\n    .asciiz %s\n",s.valor, s.nombre);
    } 
    pos = siguienteLS(l,pos);
  }

// Volvemos a poner pos en el inicio de la tabla
  pos = inicioLS(l);
while (pos != finalLS(l)) {
    Simbolo s = recuperaLS(l,pos);
    if (s.tipo != CADENA){
        printf("_%s:\n          .word 0\n",s.nombre); 
    }   
    pos = siguienteLS(l,pos);
  }
  printf("\n###################\n# Seccion de codigo\n");
  printf("    .text\n    .globl main\nmain:\n");
} 
