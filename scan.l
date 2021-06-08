%option yylineno stack

%{
#include "parse.h"

#include <err.h>
#include <stdbool.h>
#include <stdio.h>

off_t pos;
bool warn_quoted = false;

#define YY_USER_ACTION pos += yyleng;

off_t position(void) { return pos; }

static void append( const char *);
const char * warn_if( const char text[] );

void yyerror( char const *s );
%}

NUM  [[:digit:]]+
DATA [^\r\n"",]

%x quote
		
%%

{DATA}+/[,]        { yylval = strdup(yytext); return FIELD; }
{DATA}+/\r?\n      { yylval = strdup(yytext); return FIELD; }
[""]               { yy_push_state(quote); } 

[,]                {}

\r?\n              { return EOL; }

.                  { yyerror(yytext); errx(EXIT_FAILURE, "default rule"); }

<quote>{
  [^""]+           { append(yytext); }
  [""]{2}          { append(yytext + 1); }

  [""],            { yy_pop_state(); return FIELD; }
  [""]/\r?\n?      { yy_pop_state(); return FIELD; }
}

%%

static void
append(const char text[]) {
    char *data;

    if( warn_quoted ) {
	warn_if( yylval );
    }
    
    int n = asprintf( &data, "%s%s", yylval, text );
    if( n == -1 ) {
	err(EXIT_FAILURE, "strcat(%s, %s)", yylval, text);
    }
    free(yylval);
    yylval = data;
}
