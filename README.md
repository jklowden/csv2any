# csv2any

csv2any is a simple command-line utility to convert CSV files to use
other delimiters. It is a full CSV parser; any failure to process a
CSV file that meets the specification is considered a bug.

The utility was prompted by an unmet need. Many command-line and
database utilities read "delimited" files, but do not parse CSV files
correctly. If one simply splits the lines on commas (with `sed` or
`awk`, say), quoted fields will not be processed correctly. With
csv2any, the file can be converted to use delimiters that don't appear
in the data, making quoting unnecessary.

# libcsv

The project produces a library, `libcsv.so`, that can be used to
process a CSV file. The user provides a callback function that accepts
an array of strings, similar to `argc` and `argv`. That function is
called for each parsed line in the file.

# Notes on the parser

Many CSV files do not conform to RFC 4180.  Some so-called CSV files
aren't even comma-delimited!

The parser takes the RFC seriously but with some allowances.

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
- A "newline" may in fact be a 2-character 0x0d0a sequence, as is
  conventional on Microsoft Windows.
- Per 4180, Spaces are considered part of a field. They're not
  skipped: a space following a separating comma is a leading blank in
  the next field.
- The RFC says a CSV file "should contain the same number of fields"
  on every line. This parser does not require lines to have a
  consistent number of fields.
  
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

Development was done on Linux, but the project is expected to build in
any Posix environment with a C99 compiler.



