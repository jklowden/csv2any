#include <assert.h>
#include <err.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef int (*csvcb_t)( int, char *elems[] );
extern csvcb_t csv_callback;

extern bool warn_quoted;

void set_fs( const char sep[] );
void set_rs( const char sep[] );

int yyparse(void);
extern int yydebug, yy_flex_debug;
extern FILE * yyin;

int
main( int argc, char *argv[] ) {
  yy_flex_debug = 0;
  int opt;
  int erc = EXIT_FAILURE;
  
  while ((opt = getopt(argc, argv, "alyr:t:w")) != -1) {
    static char us[2] = { 0x1F }, rs[2] = { 0x1E };
    
    switch (opt) {
    case 'l': // flex debugging
      yy_flex_debug = 1;
      break;
    case 'y': // yacc debugging
      yydebug = 1;
      break;
    case 't':
      set_fs(optarg);
      break;
    case 'r':
      set_rs(optarg);
      break;
    case 'a':
      set_fs(us);
      set_rs(rs);
      break;
    case 'w':
      warn_quoted = true;
      break;
    default:
      break;
    }
  }

  if( argc == optind ) {
    return yyparse();
  }
  
  for( int i=optind; i < argc; i++ ) {
    if( (yyin = fopen(argv[i], "r")) == NULL ) {
      err(EXIT_FAILURE, "could not open %s", argv[i]);
    }

    if( (erc = yyparse()) != EXIT_SUCCESS ) {
      return erc;
    }
  }
    
  return erc;
}
