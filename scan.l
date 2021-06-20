  /*
   * Copyright (c) 2021, James K. Lowden
   * All rights reserved.
   * 
   * Redistribution and use in source and binary forms, with or without
   * modification, are permitted provided that the following conditions are met:
   * 
   * 1. Redistributions of source code must retain the above copyright notice, this
   *    list of conditions and the following disclaimer.
   * 
   * 2. Redistributions in binary form must reproduce the above copyright notice,
   *    this list of conditions and the following disclaimer in the documentation
   *    and/or other materials provided with the distribution.
   * 
   * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
   * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
   * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
   * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
   * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
   */

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
