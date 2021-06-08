%{
#include <err.h>
#include <stdlib.h>
#include <stdint.h>

static struct line_t {
    size_t capacity, nfld;
    char   **flds;
} line = { 0, 0, NULL };

void add_field(char field[]);

extern int yylineno, yyleng;

int yylex(void);
void yyerror( char const *s );
%}
			
%token EOL FIELD

%define parse.error verbose
%defines "parse.h"

%define api.value.type {char *}

%%

file:		lines
		;

lines:		line
	|	lines line 
		;

line:		fields EOL
		;

fields:		field
	|	fields field
		;

field:		FIELD
		{
		    add_field(yylval);
		}
		;

%%

void
add_field(char field[]) {	
    if( line.capacity = line.nfld ) {
	struct line_t L = line;
	L.capacity = L.capacity == 0? 16 : 2 * L.capacity;
	L.flds = realloc(L.flds, L.capacity * sizeof(L.flds[0]));
	if( !L.flds ) {
	    err(EXIT_FAILURE, "no memory for %zu fields", L.capacity);
	}
	line = L;
    }
    line.flds[line.nfld++] = field;
}

void
yyerror( char const *s ) {
    warnx( "%s on line %d at '%.*s'",
	   s, yylineno, yyleng, yylval);
}
