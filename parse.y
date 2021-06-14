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
	|	%empty
		;

lines:		line
	|	lines line 
		;

line:		fields EOL
		{
		    add_field($2);
		    assert(csv_line_callback);
		    if( ! csv_line_callback(line.nfld, line.flds) ) YYABORT; 
		    free_fields();
		}
	|	EOL
		{
		    add_field($1);
		    assert(csv_line_callback);
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
yyerror( char const *s ) {
    warnx( "%s on line %d at '%.*s'",
	   s, yylineno, yyleng, yylval);
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
	       yylineno, line.nfld );
	return s;
    }
    if( (s = strstr(text, outsep.rs)) != NULL ) {
	warnx( "line %d: quoted text in field %zu matches record separator",
	       yylineno, line.nfld );
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

