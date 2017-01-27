"""
Enhanced string literals

String literals with Swift-like format
C and Python like formatting
LaTex, Emoji, HTML, and Unicode names

Copyright 2016 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
"""
module StringLiterals

using Format
#export FormatSpec, FormatExpr, printfmt, printfmtln, format, generate_formatter
#export pyfmt, cfmt, fmt, fmt_default, fmt_default!, reset!, defaultSpec

using LaTeX_Entities, HTML_Entities, Unicode_Entities, Emoji_Entities

include("fixstrings.jl")
using .FixStrings

export @f_str, @sinterpolate
export s_unescape_string, s_escape_string, s_print_unescaped, s_print_escaped

"""
String macro with more Swift-like syntax, plus support for emojis and LaTeX names
"""
macro f_str(str) ; s_interp_parse(str) ; end

"""
Interpolates one or more strings using more Swift-like syntax
julia> x = "World"; @sinterpolate "Hello \\(x)"
"Hello World"
"""
macro sinterpolate(args...) ; s_interp_parse(args...) ; end

throw_arg_err(msg, s) = throw(ArgumentError(string(msg, repr(s))))

"""
Handle Unicode character constant, of form \\u{<hexdigits>}
"""
function s_parse_unicode(io, s,  i)
    done(s,i) &&
        throw_arg_err("Incomplete \\u{...} in ", s)
    c, i = next(s, i)
    c != '{' &&
        throw_arg_err("\\u missing opening { in ", s)
    done(s,i) &&
        throw_arg_err("Incomplete \\u{...} in ", s)
    c, i = next(s, i)
    n::UInt32 = 0
    k = 0
    while c != '}'
        done(s, i) &&
            throw_arg_err("\\u{ missing closing } in ", s)
        (k += 1) > 6 &&
            throw_arg_err("Unicode constant too long in ", s)
        n = n<<4 + c - ('0' <= c <= '9' ? '0' :
                        'a' <= c <= 'f' ? 'a' - 10 :
                        'A' <= c <= 'F' ? 'A' - 10 :
                        throw_arg_err("\\u missing closing } in ", s))
        c, i = next(s,i)
    end
    k == 0 &&
        throw_arg_err("\\u{} has no hex digits in ", s)
    ((0x0d800 <= n <= 0x0dfff) || n > 0x10ffff) &&
        throw_arg_err("Invalid Unicode character constant ", s)
    print(io, Char(n))
    i
end

"""
Handle Emoji character, of form \\:name:
"""
function s_parse_emoji(io, s,  i)
    beg = i # start location
    c, i = next(s, i)
    while c != ':'
        done(s, i) &&
            throw_arg_err("\\: missing closing : in ", s)
        c, i = next(s, i)
    end
    emojistr = Emoji_Entities.lookupname(s[beg:i-2])
    emojistr == "" &&
        throw_arg_err("Invalid Emoji name in ", s)
    print(io, emojistr)
    i
end

"""
Handle LaTeX character/string, of form \\<name>
"""
function s_parse_latex(io, s,  i)
    beg = i # start location
    c, i = next(s, i)
    while c != '>'
        done(s, i) &&
            throw_arg_err("\\< missing closing > in $(repr(s))")
        c, i = next(s, i)
    end
    latexstr = LaTeX_Entities.lookupname(s[beg:i-2])
    latexstr == "" &&
        throw_arg_err("Invalid LaTex name in ", s)
    print(io, latexstr)
    i
end

"""
Handle HTML character/string, of form \\&name;
"""
function s_parse_html(io, s,  i)
    beg = i # start location
    c, i = next(s, i)
    while c != ';'
        done(s, i) &&
            throw_arg_err("\\& missing ending ; in ", s)
        c, i = next(s, i)
    end
    htmlstr = HTML_Entities.lookupname(s[beg:i-2])
    htmlstr == "" &&
        throw_arg_err("Invalid HTML name in ", s)
    print(io, htmlstr)
    i
end

"""
Handle Unicode name, of form \\N{name}, from Python
"""
function s_parse_uniname(io, s,  i)
    done(s, i) &&
        throw_arg_err("\\N incomplete in ", s)
    c, i = next(s, i)
    c != '{' &&
        throw_arg_err("\\N missing initial { in ", s)
    done(s, i) &&
        throw_arg_err("\\N{ incomplete in ", s)
    beg = i # start location
    c, i = next(s, i)
    while c != '}'
        done(s, i) &&
            throw_arg_err("\\N{ missing closing } in ", s)
        c, i = next(s, i)
    end
    unistr = Unicode_Entities.lookupname(s[beg:i-2])
    unistr == "" &&
        throw_arg_err("Invalid Unicode name in ", s)
    print(io, unistr)
    i
end

"""
String interpolation parsing
Based on code resurrected from Julia base:
https://github.com/JuliaLang/julia/blob/deab8eabd7089e2699a8f3a9598177b62cbb1733/base/string.jl
"""
function s_print_unescaped(io, s::AbstractString)
    i = start(s)
    while !done(s,i)
        c, i = next(s,i)
        if !done(s,i) && c == '\\'
            c, i = next(s,i)
            if c == 'u'
                i = s_parse_unicode(io, s, i)
            elseif c == ':'	# Emoji
                i = s_parse_emoji(io, s, i)
            elseif c == '&'	# HTML
                i = s_parse_html(io, s, i)
            elseif c == '<'	# LaTex
                i = s_parse_latex(io, s, i)
            elseif c == 'N'	# Unicode name
                i = s_parse_uniname(io, s, i)
            else
                c = (c == '0' ? '\0' :
                     c == '"' ? '"'  :
                     c == '\'' ? '\'' :
                     c == '\\' ? '\\' :
                     c == 'a' ? '\a' :
                     c == 'b' ? '\b' :
                     c == 't' ? '\t' :
                     c == 'n' ? '\n' :
                     c == 'v' ? '\v' :
                     c == 'f' ? '\f' :
                     c == 'r' ? '\r' :
                     c == 'e' ? '\e' :
                     throw(ArgumentError(string("Invalid \\",c," sequence in ",repr(s)))))
                write(io, UInt8(c))
            end
        else
            print(io, c)
        end
    end
end

s_unescape_string(s::AbstractString) = sprint(endof(s), s_print_unescaped, s)

function s_print_escaped(io, s::AbstractString, esc::AbstractString)
    i = start(s)
    while !done(s,i)
        c, i = next(s, i)
        c == '\0'       ? print(io, "\\0") :
        c == '\e'       ? print(io, "\\e") :
        c == '\\'       ? print(io, "\\\\") :
        c in esc        ? print(io, '\\', c) :
        '\a' <= c <= '\r' ? print(io, '\\', "abtnvfr"[Int(c)-6]) :
        isprint(c)      ? print(io, c) :
        		  print(io, "\\u{", hex(c), "}")
    end
end

s_escape_string(s::AbstractString) = sprint(endof(s), s_print_escaped, s, "\"")

function s_interp_parse(s::AbstractString, unescape::Function, p::Function)
    sx = []
    i = j = start(s)
    while !done(s, j)
        c, k = next(s, j)
        if c == '\\' && !done(s, k)
            if s[k] == '('
                # Handle interpolation
                isempty(s[i:j-1]) ||
                    push!(sx, unescape(s[i:j-1]))
                ex, j = parse(s, k, greedy=false)
                isa(ex, Expr) && (ex.head === :continue) &&
                    throw(ParseError("Incomplete expression"))
                push!(sx, esc(ex))
                i = j
            elseif s[k] == '%'
                # Move past \\, c should point to '%'
                c, k = next(s, k)
                done(s, k) && throw(ParseError("Incomplete % expression"))
                # Handle interpolation
                if !isempty(s[i:j-1])
                    push!(sx, unescape(s[i:j-1]))
                end
                if s[k] == '('
                    # Need to find end to parse to
                    _, j = parse(s, k, greedy=false)
                    # This is a bit hacky, and probably doesn't perform as well as it could,
                    # but it works! Same below.
                    str = string("(fmt", s[k:j-1], ')')
                else
                    # Move past %, c should point to letter
                    beg = k
                    while true
                        c, k = next(s, k)
                        done(s, k) &&
                            throw(ParseError("Incomplete % expression"))
                        s[k] == '(' && break
                    end
                    _, j = parse(s, k, greedy=false)
                    str = string("(Format.cfmt(\"", s[beg-1:k-1], "\",", s[k+1:j-1], ")")
                end
                ex, _ = parse(str, 1, greedy=false)
                isa(ex, Expr) && (ex.head === :continue) &&
                    throw(ParseError("Incomplete expression"))
                push!(sx, esc(ex))
                i = j
            elseif s[k] == '{'
                # Move past \\, c should point to '{'
                c, k = next(s, k)
                done(s, k) &&
                    throw(ParseError("Incomplete {...} Python format expression"))
                # Handle interpolation
                isempty(s[i:j-1]) ||
                    push!(sx, unescape(s[i:j-1]))
                beg = k # start location
                c, k = next(s, k)
                while c != '}'
                    done(s, k) &&
                        throw_arg_err("\\{ missing closing } in ", s)
                    c, k = next(s, k)
                end
                c != '(' &&
                    throw(ParseError("Missing (expr) in Python format expression"))
                # Need to find end to parse to
                _, j = parse(s, k, greedy=false)
                # This is a bit hacky, and probably doesn't perform as well as it could,
                # but it works! Same below.
                str = string("(Format.pyfmt", s[k:j-1], ')')
                ex, _ = parse(str, 1, greedy=false)
                isa(ex, Expr) && (ex.head === :continue) &&
                    throw(ParseError("Incomplete expression"))
                push!(sx, esc(ex))
                i = j
            else
                j = k
            end
        else
            j = k
        end
    end
    isempty(s[i:end]) ||
        push!(sx, unescape(s[i:j-1]))
    length(sx) == 1 && isa(sx[1], ByteStr) ? sx[1] : Expr(:call, :sprint, p, sx...)
end

s_interp_parse(s::AbstractString, u::Function) = s_interp_parse(s, u, print)
s_interp_parse(s::AbstractString) =
    s_interp_parse(s, x -> (isvalid(UTF8Str, s_unescape_string(x))
                            ? s_unescape_string(x)
                            : throw(ArgumentError("Invalid UTF-8 sequence"))))

end # module
