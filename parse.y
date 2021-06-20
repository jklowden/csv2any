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

%{
#include <assert.h>
#include <err.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

static struct line_t {
    size_t capacity, nfld;
    char   **flds;
} line = { 0, 0, NULL };

static void add_field(char field[]);
static void free_fields();

static bool recapitulate( int nelem, char *elems[] );

typedef bool (*csvlcb_t)( int, char *elems[] );
csvlcb_t csv_line_callback = recapitulate;

typedef char * (*csvfcb_t)( char elem[] );
csvfcb_t csv_field_callback = NULL;

extern int csvlineno, csvleng;

int csvlex(void);
void csverror( char const *s );
%}
			
%token EOL FIELD

%define parse.error verbose
%defines "parse.h"

%define api.value.type {char *}

%define api.prefix {csv}

%%

file:		lines
	|	%empty
		;

lines:		line
	|	lines line 
		;

line:		fields EOL
		{
		    add_field($2);
		    if( ! csv_line_callback ) csv_line_callback = recapitulate;
		    if( ! csv_line_callback(line.nfld, line.flds) ) YYABORT; 
		    free_fields();
		}
	|	EOL
		{
		    add_field($1);
		    if( ! csv_line_callback ) csv_line_callback = recapitulate;
		    if( ! csv_line_callback(line.nfld, line.flds) ) YYABORT; 
		    free_fields();
		}
		;

fields:		field
	|	fields field
		;

field:		FIELD
		{
		    add_field($1);
		}
		;

%%

static void
add_field(char field[]) {	
    if( line.capacity == line.nfld ) {
	struct line_t L = line;
	L.capacity = L.capacity == 0? 16 : 2 * L.capacity;
	L.flds = realloc(L.flds, L.capacity * sizeof(L.flds[0]));
	if( !L.flds ) {
	    err(EXIT_FAILURE, "no memory for %zu fields", L.capacity);
	}
	line = L;
    }
    if( csv_field_callback ) {
	char *f;
	if( (f = csv_field_callback(field)) != field ) {
	    free(field);
	    field = f;
	}
    }
    line.flds[line.nfld++] = field;
}

static void
free_fields() {
    for( int i=0; i < line.nfld; i++ ) {
	free(line.flds[i]);
	line.flds[i] = NULL;
    }
    line.nfld = 0;
}

void
csverror( char const *s ) {
    warnx( "%s on line %d at '%.*s'",
	   s, csvlineno, csvleng, csvlval);
}

static struct {
  char *fs, *rs;
} outsep = { ",", "\n" };

static void
set_separator( char **separator, const char sep[] ) {
  *separator = strdup(sep);
  assert(*separator);
  char *tgt = *separator;
  
  for( const char *s = sep; *s != '\0'; s++, tgt++ ) {
    if( *s != '\\' ) {
      *tgt = *s;
      continue;
    }

    switch( *++s ) {
    default: case '\\':
      *tgt = *s;
      break;
    case 'a':
      *tgt = 0x07;
      break;
    case 'b':
      *tgt = 0x08;
      break;
    case 'f':
      *tgt = 0x0c;
      break;
    case 'n':
      *tgt = '\n';
      break;
    case 't':
      *tgt = '\t';
      break;
    case 'v':
      *tgt = 0x0b;
      break;
    }
  }
  *tgt = '\0';;
}

const char *
warn_if( const char text[] ) {
    const char *s;
    if( (s = strstr(text, outsep.fs)) != NULL ) {
	warnx( "line %d: quoted text in field %zu matches field separator",
	       csvlineno, line.nfld );
	return s;
    }
    if( (s = strstr(text, outsep.rs)) != NULL ) {
	warnx( "line %d: quoted text in field %zu matches record separator",
	       csvlineno, line.nfld );
    }
    return s;
}

void
set_fs( const char sep[] ) {
    set_separator( &outsep.fs, sep );
}

void
set_rs( const char sep[] ) {
    set_separator( &outsep.rs, sep );
}

static bool
recapitulate( int nelem, char *elems[] ) {
    char *comma = "";

    for( int i=0; i < nelem; i++ ) {
	const char *data = elems[i]? elems[i] : "";
	
	printf( "%s%s", comma, data );
	comma = outsep.fs;
    }

    printf("\n");

    return true;
}

