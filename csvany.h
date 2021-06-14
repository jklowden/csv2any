#ifndef _CSVANY_H_
#define _CSVANY_H_

#include <stdbool.h>
#include <stdio.h>

typedef bool (*csvlcb_t)( int, char *elems[] );
extern csvlcb_t csv_line_callback;

typedef char * (*csvfcb_t)( char elem[] );
extern csvfcb_t csv_field_callback;

int csvparse(void);

extern int csvlineno;

extern FILE * csvin;

#endif
