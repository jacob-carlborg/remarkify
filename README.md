# Remarkify

This tool will combine Markdown files to be used together with
[remark](https://remarkjs.com). The tool takes a list of Markdown files,
combines the content of those and outputs the result to an HTML file.

An HTML template file is used to generate the final result. This can be any file
containing: `{{ slides }}`. `{{ slides }}` acts as a placeholder and will be
replaced with the combined Markdown files. The template is expected to contain
the [HTML boilerplate](https://github.com/gnab/remark#getting-started)
necessary for remark.

A plain text file containing the ordering of the slides is necessary. The file
should contain the basename (without the directory path) of the Markdown files,
one file per line.

## Usage

Specify the Markdown files to combine as arguments, the HTML template to use
with the `-t` flag, the slides ordering file using `-s` and where to place the
output using the `-o` flag. Example:

```html
$ cat template.html
<html>
  <body>
    {{ slides }}
  </body>
</html>
```

```
$ cat slides_ordering.txt
foo.md
bar.md
```

```
$ ls slides
bar.md foo.md
```

```
$ remarkify -t template.html -o index.html -s slides_ordering.txt slides/*.md
```

## Building

Build with [Dub](http://code.dlang.org), just by invoking it: `dub`. Building on
Linux using LDC will result in a completely statically linked binary that should
work on all distributions and versions.

## Running the Tests

Run the tests by invoking `dub test`.
