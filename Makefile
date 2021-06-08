LFLAGS = -d --noyywrap --yylineno --nodefault 

YFLAGS = -t -k  --report-file=parser.out --verbose
YACC = bison

CPPFLAGS = -D_GNU_SOURCE
CFLAGS   = -fPIC -g -O0 -Wall

all: libcsv.so csv2any

csv2any: main.o
	$(CC) -o $@ $^ -L$(PWD) -Wl,-rpath -Wl,$(PWD) -lcsv

libcsv.so: parse.o scan.o
	$(CC) -o $@ -shared $(CPPFLAGS) $(CFLAGS) $^

scan.o: scan.c
	$(CC) -c -o$@ $(CPPFLAGS) $(subst -Wall,,$(CFLAGS)) $^

parse.c: parse.y
	$(YACC) $(YFLAGS) -o$@ $^

tags: TAGS
TAGS:
	etags *.[yl] main.c parse.h
