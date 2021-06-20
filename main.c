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
  extern bool warn_quoted;
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
