# csv2any

csv2any is a command-line utility to convert CSV files to use other
delimiters. It is a full CSV parser; any failure to process a CSV file
that meets the specification is considered a bug.

The utility was prompted by an unmet need. Many command-line and
database utilities read "delimited" files, but do not parse CSV files
correctly. If one simply splits the lines on commas (with `sed` or
`awk`, say), quoted fields will not be processed correctly. With
csv2any, the file can be converted to use delimiters that don't appear
in the data, making quoting unnecessary.

# libanycsv

The project produces a library, `libanycsv.so`, that can be used to
process a CSV file. The user provides a callback function that accepts
an array of strings. That function is called for each parsed line in
the file.

# Notes on the parser

Many CSV files do not conform to RFC 4180.  Some so-called CSV files
aren't even comma-delimited!

The parser takes the RFC seriously but with some allowances.  See the
man page **libanycsv**(3) for details.

- The encoding of a CSV file is not defined by the RFC. Because this
parser is based on GNU flex, it's looking for the ASCII values of the
NUL, comma, newline, carriage return, and double-quote characters. If
those values appear as part of a multibyte encoding, the file will not
be parsed correctly.
- A field may be enclosed in double-quotes. Within the quoted field, 
  - a consecutive pair of double-quotes represents one double-quote
  character.
  - the normal delimeters -- commma and newline characters -- are
    treated as data.

## Minor Screed

It is not hard to find on the interwebs such things as "tab-delimited
CSV" files. This parser works on real CSV files, where "CSV" means
*comma separated value*. It breaks lines into fields separated by
commas, and only commas. If you need something else, you need something else. 
  
# Notes on the project

The project requires **GNU make** to build. It doesn't use any kind of
build framework or install utility. To build:

    $ make 
	
To build and install in one fell swoop: 

    $ make install

It installs in `/usr/local` by default. To override: 

    $ make install PREFIX=/your/favorite/place
	
The project requires the **GNU flex** and **GNU bison**
implementations of lex and yacc. 

The programs are written in C, written to the C11 standard. If your
system doesn't have `stdbool.h` or complains about local variables not
declared at the top of functions, you need a newer compiler or an
older library.

Development was done on Linux, but the project is expected to build in
any Posix environment with a C99 compiler.
