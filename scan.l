%option yylineno stack prefix="csv"

%{
#include "parse.h"

#include <err.h>
#include <stdbool.h>
#include <stdio.h>

off_t pos;
bool warn_quoted = false;
char *field = NULL;

#define YY_USER_ACTION pos += csvleng;

off_t position(void) { return pos; }

static int set_csvlval( int token );
static void append_field( const char *);
const char * warn_if( const char text[] );

void csverror( char const *s );
%}

NUM    [[:digit:]]+
DATA   [^\r\n,]
QUOTE  [[:blank:]]*[""]

%x quote
		
%%

\r?\n              { return set_csvlval(EOL); }

[^"",]{DATA}*      { field = strdup(csvtext); }

^{QUOTE}           { yy_push_state(quote); } 
,{QUOTE}/.         { yy_push_state(quote); return set_csvlval(FIELD); }

[,]                { return set_csvlval(FIELD); }

^[[:blank:]]*\r?\n {  /* ignore blank lines*/  }

.                  { csverror(csvtext); errx(EXIT_FAILURE, "default rule"); }

<<EOF>>            { if( !field ) yyterminate(); return set_csvlval(EOL); }

<quote>{
  [^""]+           { append_field(csvtext); }
  [""]{2}          { append_field(csvtext + 1); }

  [""]             { yy_pop_state(); }
}

%%

static void
append_field(const char text[]) {
    char *data, *extant = field? field : "";

    int n = asprintf( &data, "%s%s", extant, text );
    if( n == -1 ) {
	err(EXIT_FAILURE, "%s(%s, %s)", __func__, extant, text);
    }
    free(field);
    field = data;

    if( warn_quoted ) {
	warn_if( field );
    }
}

static int
set_csvlval( int token ) {
    csvlval = field;
    field = NULL;
    return token;
}
