#!/usr/bin/env dmd -run

module app;

import std.algorithm;
import std.exception;
import std.format;
import std.getopt;
import std.path;
import std.range;
import std.string;
import std.stdio : println = writeln;

struct Options
{
    struct Defaults
    {
        enum templatePath = "template.html";
        enum outputPath = "index.html";
        enum slidesOrderingPath = "slides_ordering.txt";
    }

    bool help;

    string templatePath = Defaults.templatePath;
    string outputPath = Defaults.outputPath;
    string slidesOrderingPath = Defaults.slidesOrderingPath;
    string[] slides;
}

struct Slide
{
    string filename;
    string content;

    bool isValid()
    {
        return filename.length > 0;
    }
}

auto readSlidesOrder(string path)
{
    return readFile(path).slidesOrder;
}

auto slidesOrder(string slidesOrderingContent)
{
    return slidesOrderingContent
        .lineSplitter
        .filter!(line => !line.empty);
}

unittest
{
    assert(slidesOrder("foo.md\nbar.md").equal(["foo.md", "bar.md"]));

    // with extra empty newline
    assert(slidesOrder("foo.md\nbar.md\n\n").equal(["foo.md", "bar.md"]));
}

auto readSlides(string[] paths)
{
    return paths.map!(path => Slide(path, readFile(path)));
}

auto sort(SlideRange, OrderRange)(SlideRange slides, OrderRange order)
if (
    is(ElementType!SlideRange == Slide) &&
    is(ElementType!OrderRange == string)
)
{
    auto equalBaseName(string key)
    {
        auto slide = slides.find!(e => e.filename.baseName == key);
        return slide.empty ? Slide() : slide.front;
    }

    return order
        .map!(equalBaseName)
        .filter!(e => e.isValid);
}

unittest
{
    auto slides = [Slide("test/foo.md"), Slide("test/bar.md")];
    auto order = ["bar.md", "foo.md"];

    auto expedted = [Slide("test/bar.md"), Slide("test/foo.md")];
    assert(slides.sort(order).equal(expedted));
}

// with missing slides
unittest
{
    auto slides = [Slide("test/foo.md"), Slide("test/bar.md")];
    auto order = ["bar.md", "a.md", "foo.md"];

    auto expedted = [Slide("test/bar.md"), Slide("test/foo.md")];
    assert(slides.sort(order).equal(expedted));
}

string stripSlideSeparator(string str)
{
    import std.regex;
    enum regex = ctRegex!r"(\s|---)+$";

    return str.replaceFirst(regex, "");
}

unittest
{
    assert("foo".stripSlideSeparator == "foo");
    assert("foo    ".stripSlideSeparator == "foo");
    assert("foo\n\n\n".stripSlideSeparator == "foo");
    assert("foo\n---\n".stripSlideSeparator == "foo");
    assert("foo\n\n---\n\n".stripSlideSeparator == "foo");
    assert("foo\n\n---\n\n\n\n---\n\n".stripSlideSeparator == "foo");
}

auto combine(Range)(Range slides)
    if (is(ElementType!Range == Slide))
{
    return slides
        .map!(e => e.content)
        .map!(stripSlideSeparator)
        .joiner("\n---\n");
}

unittest
{
    auto slides = [Slide("", "foo\n"), Slide("", "bar\n---")];
    assert(slides.combine.equal("foo\n---\nbar"));
}

string generateTemplate(Range)(Range data, string templatePath)
{
    import std.conv : to;

    return readFile(templatePath).evaluateTemplate(data.to!string);
}

string evaluateTemplate(string templateData, string slidesData)
{
    enum placeholder = "{{ slides }}";
    return templateData.replace(placeholder, slidesData);
}

unittest
{
    enum templateData = q"HTML
<textarea id="source">
  {{ slides }}
</textarea>
HTML";

enum expected = q"HTML
<textarea id="source">
  foo
</textarea>
HTML";

    assert(templateData.evaluateTemplate("foo") == expected);
}

void output(string data, string path)
{
    import std.file : write;
    write(path, data);
}

string readFile(string path)
{
    import std.file : read;
    import std.conv : to;

    return read(path).to!string;
}

struct Application
{
    string[] args;

    void run()
    {
        import core.stdc.stdlib : exit, EXIT_FAILURE;
        debug
            _run();
        else
        {
            try
                _run();
            catch (Exception e)
            {
                println(e.msg);
                exit(EXIT_FAILURE);
            }
        }
    }

private:

    Options parseCli()
    {
        enum usage = "Usage: remarkify [options] <slides/*.md>

Remarkify will combine Markdown files to be used together with remark. It takes
a list of Markdown files, combines the content of those and outputs the result
to an HTML file.

An HTML template file is used to generate the final result. This can be any file
containing: \033[1m{{ slides }}\033[0m. \033[1m{{ slides }}\033[0m acts as a placeholder and will be
replaced with the combined Markdown files. The template is expected to contain
the HTML boilerplate necessary for remakr.

A plain text file containing the ordering of the slides is necessary. The file
should contain the basename (without the directory path) of the Markdown files,
one file per line.\n";

        Options options;

        auto getoptResult = getopt(
            args,
            "template|t", format("The path to the HTML template to use (defaults to %s).", Options.Defaults.templatePath), &options.templatePath,
            "output|o", format("Put the result in this file (defaults to %s).", Options.Defaults.outputPath), &options.outputPath,
            "slides-ordering|s", format("A file contaning the order of the slides, one filename per line (defaults to %s).", Options.Defaults.slidesOrderingPath), &options.slidesOrderingPath
        );

        if (getoptResult.helpWanted)
        {
            defaultGetoptPrinter(usage, getoptResult.options);
            return Options(true);
        }

        options.slides = args[1 .. $];
        enforce(!options.slides.empty, "No Markdown files given");

        return options;
    }

    void _run()
    {
        auto options = parseCli();

        if (options.help)
            return;

        auto slidesOrder = readSlidesOrder(options.slidesOrderingPath);

        readSlides(options.slides)
            .sort(slidesOrder)
            .combine
            .generateTemplate(options.templatePath)
            .output(options.outputPath);
    }
}

version (unittest)
    void main() {}
else

void main(string[] args)
{
    Application(args).run();
}
