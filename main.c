#include "csvany.h"

#include <assert.h>
#include <err.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void set_fs( const char sep[] );
void set_rs( const char sep[] );

extern int csvdebug, csv_flex_debug;

int
main( int argc, char *argv[] ) {
  csv_flex_debug = 0;
  int opt;
  int erc = EXIT_FAILURE;
  
  while ((opt = getopt(argc, argv, "alyr:t:w")) != -1) {
    static char us[2] = { 0x1F }, rs[2] = { 0x1E };
    
    switch (opt) {
    case 'l': // flex debugging
      csv_flex_debug = 1;
      break;
    case 'y': // yacc debugging
      csvdebug = 1;
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
    return csvparse();
  }
  
  for( int i=optind; i < argc; i++ ) {
    if( (csvin = fopen(argv[i], "r")) == NULL ) {
      err(EXIT_FAILURE, "could not open %s", argv[i]);
    }

    if( (erc = csvparse()) != EXIT_SUCCESS ) {
      return erc;
    }
  }
    
  return erc;
}
