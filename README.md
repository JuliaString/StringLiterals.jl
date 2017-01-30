# StringLiterals

[![Build Status](https://travis-ci.org/JuliaString/StringLiterals.jl.svg?branch=master)](https://travis-ci.org/JuliaString/StringLiterals.jl)

[![Coverage Status](https://coveralls.io/repos/github/JuliaString/StringLiterals.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaString/StringLiterals.jl?branch=master)

[![codecov.io](http://codecov.io/github/JuliaString/StringLiterals.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaString/StringLiterals.jl?branch=master)

The StringLiterals package is an attempt to bring a cleaner string literal syntax to Julia, as well as having an easier way of producing formatted strings, borrowing from both Python and C formatted printing syntax.  It also adds support for using LaTex, Emoji, HTML, or Unicode entity names that are looked up at compile-time.

Currently, it adds a Swift style string macro, `f"..."`, which uses the Swift syntax for
interpolation, i.e. `\(expression)`.  This means that you never have to worry about strings with
the $ character in them, which is rather frequent in some applications.
Also, Unicode sequences are represented as in Swift, i.e. as `\u{hexdigits}`, where there
can be from 1 to 6 hex digits. This syntax eliminates having to worry about always outputting
4 or 8 hex digits, to prevent problems with 0-9,A-F,a-f characters immediately following.
Finally, I have added four ways of representing characters in the literal string,
`\:emojiname:`, `\<latexname>`, `\&htmlname;` and `\N{UnicodeName}`.
This makes life a lot easier when you want to keep the text of a program in ASCII, and
also to be able to write programs using those characters that might not even display
correctly in their editor.

It also adds a string macro that instead of building a string, can print the strings and interpolated values directly, without having to create a string out of all the parts.
Finally, there are uppercase versions of the macros, which also supports the legacy sequences, $ for string interpolation, `\x` followed by 1 or 2 hex digits, `\u` followed by 1 to 4 hex digits, and `\U` followed by 1 to 8 hex digits.

This uses a fork of the https://github.com/JuliaIO/Formatting.jl package to provide formatting capability, as well as Tom Breloff's PR https://github.com/JuliaIO/Formatting.jl/pull/10, which provides the capability of using settable printing defaults based on the types of the argument.
The formatting code has been extensively modified, see https://github.com/JuliaString/Format.jl.

* `\` can be followed by: 0, $, ", ', \, a, b, e, f, n, r, t, u, v, N, %, (, <, {, : or &.
In the legacy modes, x and U are also allowed after the `\`.
Unlike standard Julia string literals, unsupported characters give an error (as in Swift).

* `\0` outputs a nul byte (0x00) (note: as in Swift, octal sequences are not supported, just the nul byte)
* `\a` outputs the "alarm" or "bell" control code (0x07)
* `\b` outputs the "backspace" control code (0x08)
* `\e` outputs the "escape" control code (0x1b)
* `\f` outputs the "formfeed" control code (0x0c)
* `\n` outputs the "newline" or "linefeed" control code (0x0a)
* `\r` outputs the "return" (carriage return) control code (0x0d)
* `\t` outputs the "tab" control code (0x09)
* `\v` outputs the "vertical tab" control code (0x0b)

* `\u{<hexdigits>}` is used to represent a Unicode character, with 1-6 hex digits.
* `\<` followed by a LaTeX entity name followed by `>` outputs that character or sequence if the name is valid.
* `\:` followed by an Emoji name followed by `:` outputs that character or sequence (if a valid name)
* `\&` followed by an HTML entity name followed by `;` outputs that character or sequence (if a valid name)
* `\N{` followed by a Unicode entity name (case-insensitive!) followed by a `}` outputs that Unicode character (if a valid name)

* `\(expression)` simply interpolates the value of the expression, the same as `$(expression)` in standard Julia string literals.
* `\%<ccc><formatcode>(arguments)` is interpolated as a call to `cfmt("<cccc><formatcode>",arguments)`, where `<ccc><formatcode>` is a C-style format string.

* `\%(arguments)` is interpolated as a call to `fmt(arguments)`.
This is especially useful when defaults have been set for the type of the first argument.

* `fmt_default!{T}(::Type{T}, syms::Symbol...; kwargs...)` sets the defaults for a particular type.
* `fmt_default!(syms::Symbol...; kwargs...)` sets the defaults for all types.

Symbols that can currently be used are: `:ljust` or `:left`, `:rjust` or `:right`, `:commas`, `:zpad` or `:zeropad`, and `:ipre` or `:prefix`.
* `reset!{T}(::Type{T})` resets the defaults for a particular type.
* `defaultSpec(x)` will return the defaults for the type of x, and
* `defaultSpec{T}(::Type{T})` will return the defaults for the given type.

There is currently support for Python style formatting, although that is a work-in-progress,
and I am intending to improve the syntax to make it as close as possible to Python's 3.6 format strings.
Currently, the syntax is `\{<formatstring>}(expression)`, however I plan on changing it shortly to `\{expression}` (equivalent to `pyfmt("", expression)`, and `\{expression;formatstring}` (equivalent to `pyfmt("formatstring", expression)`.
