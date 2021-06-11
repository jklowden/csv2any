%option yylineno stack

%{
#include "parse.h"

#include <err.h>
#include <stdbool.h>
#include <stdio.h>

off_t pos;
bool warn_quoted = false;
char *field = NULL;

#define YY_USER_ACTION pos += yyleng;

off_t position(void) { return pos; }

static int set_yylval( int token );
static void append_field( const char *);
const char * warn_if( const char text[] );

void yyerror( char const *s );
%}

NUM    [[:digit:]]+
DATA   [^\r\n,]+
QUOTE  [[:blank:]]*[""]

%x quote
		
%%

{DATA}             { field = strdup(yytext); }

^{QUOTE}/{DATA}    { yy_push_state(quote); } 
,{QUOTE}/{DATA}    { yy_push_state(quote); return set_yylval(FIELD); }

[,]                { return set_yylval(FIELD); }

^[[:blank:]]*\r?\n {  /* ignore blank lines*/  }

\r?\n              { return set_yylval(EOL); }

.                  { yyerror(yytext); errx(EXIT_FAILURE, "default rule"); }

<<EOF>>            { if( !field ) yyterminate(); return set_yylval(EOL); }

<quote>{
  [^""]+           { append_field(yytext); }
  [""]{2}          { append_field(yytext + 1); }

  [""]             { yy_pop_state(); }
}

%%

static void
append_field(const char text[]) {
    char *data;

    if( warn_quoted ) {
	warn_if( field );
    }
    
    int n = asprintf( &data, "%s%s", field, text );
    if( n == -1 ) {
	err(EXIT_FAILURE, "strcat(%s, %s)", field, text);
    }
    free(field);
    field = data;
}

static int
set_yylval( int token ) {
    yylval = field;
    field = NULL;
    return token;
}