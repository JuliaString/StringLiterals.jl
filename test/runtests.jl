using StringLiterals
using Format

@static VERSION < v"0.7.0-DEV" ? (using Base.Test) : (using Test)
eval_parse(s) = eval((@static VERSION < v"0.7.0-DEV.2995" ? parse : Meta.parse)(s))
const ErrorType = @static VERSION < v"0.7.0-DEV" ? ArgumentError : LoadError

ts(io) = String(take!(io))

@testset "LaTeX Entities" begin
    @test f"\<dagger>" == "†"
    #@test f"\<mscrl>" == "𝓁" # \U1f4c1
    @test f"\<c_l>" == "𝓁" # \U1f4c1
    @test f"\<nleqslant>" == "⩽̸" # \u2a7d\u338
end
@testset "Emoji Entities" begin
    @test f"\:sailboat:" == "\u26f5"
    @test f"\:ring:"     == "\U1f48d"
    @test f"\:flag-us:"  == "\U1f1fa\U1f1f8"
end
@testset "Unicode Entities" begin
    @test f"\N{end of text}" == "\x03" # \3
    @test f"\N{TIBETAN LETTER -A}" == "\u0f60"
    @test f"\N{LESS-THAN OR SLANTED EQUAL TO}" == "\u2a7d"
    @test f"\N{REVERSED HAND WITH MIDDLE FINGER EXTENDED}" == "\U1f595"
end
@testset "HTML Entities" begin
    @test f"\&nle;"    == "\u2270"
    @test f"\&Pscr;"   == "\U1d4ab"
    @test f"\&lvnE;"   == "\u2268\ufe00"
end
@testset "Unicode constants" begin
    @test f"\u{3}"     == "\x03"
    @test f"\u{f60}"   == "\u0f60"
    @test f"\u{2a7d}"  == "\u2a7d"
    @test f"\u{1f595}" == "\U0001f595"
end
@testset "Interpolation" begin
    scott = 123
    @test f"\(scott)" == "123"
end
@testset "\$ not interpolation" begin
    @test f"I have $10, $spj$" == "I have \$10, \$spj\$"
end
@testset "Valid quoted characters" begin
    @test f"\$" == "\$"
    @test f"\"" == "\""
    @test f"\'" == "\'"
    @test f"\\" == "\\"
    @test f"\0" == "\0"
    @test f"\a" == "\a"
    @test f"\b" == "\b"
    @test f"\e" == "\e"
    @test f"\f" == "\f"
    @test f"\n" == "\n"
    @test f"\r" == "\r"
    @test f"\t" == "\t"
    @test f"\v" == "\v"
end
@testset "Invalid quoted characters" begin
    for ch in "cdghijklmopqsuwxy"
        @test_throws ErrorType eval_parse(string("f\"\\", ch, '"'))
    end
    for ch in 'A':'Z'
        @test_throws ErrorType eval_parse(string("f\"\\", ch, '"'))
    end
end

@testset "Legacy mode only sequences" begin
    # Check for ones allowed in legacy mode
    for s in ("f\"\\x\"", "f\"\\x7f\"", "f\"\\u\"", "f\"\\U\"", "f\"\\U{123}\"")
        @test_throws ErrorType eval_parse(s)
    end
end

@testset "Legacy mode Hex constants" begin
    @test F"\x3"     == "\x03"
    @test F"\x7f"    == "\x7f"
    @test_throws ErrorType eval_parse("F\"\\x\"")
    @test_throws ErrorType eval_parse("F\"\\x!\"")
end

@testset "Legacy mode Unicode constants" begin
    @test F"\u3"     == "\x03"
    @test F"\uf60"   == "\u0f60"
    @test F"\u2a7d"  == "\u2a7d"
    @test F"\U1f595" == "\U0001f595"
    @test F"\u{1f595}" == "\U0001f595"
    @test_throws ErrorType eval_parse("F\"\\U\"")
    @test_throws ErrorType eval_parse("F\"\\U!\"")
    @test_throws ErrorType eval_parse("F\"\\U{123}\"")
end

@testset "Legacy mode valid quoted characters" begin
    @test f"\$" == "\$"
    @test f"\"" == "\""
    @test f"\'" == "\'"
    @test f"\\" == "\\"
    @test f"\0" == "\0"
    @test f"\a" == "\a"
    @test f"\b" == "\b"
    @test f"\e" == "\e"
    @test f"\f" == "\f"
    @test f"\n" == "\n"
    @test f"\r" == "\r"
    @test f"\t" == "\t"
    @test f"\v" == "\v"
end

@testset "Legacy mode \$ interpolation" begin
    scott = 123
    @test F"$scott" == "123"
    @test F"$(scott+1)" == "124"
end

@testset "Quoted \$ in Legacy mode" begin
    @test F"I have \$10, \$spj\$" == "I have \$10, \$spj\$"
end

@testset "C Formatting" begin
    @testset "int" begin
        @test f"\%d(typemax(Int64))" == "9223372036854775807"
        @test f"\%a(typemax(Int64))" == "0x7.fffffffffffffffp+60"
        @test f"\%A(typemax(Int64))" == "0X7.FFFFFFFFFFFFFFFP+60"
    end
    @testset "printing an int value" begin
        for num in (UInt16(42), UInt32(42), UInt64(42), UInt128(42),
                    Int16(42), Int32(42), Int64(42), Int128(42))
            @test f"\%i(num)"       == "42"
            @test f"\%u(num)"       == "42"
            @test f"Test: \%i(num)" == "Test: 42"
            @test f"\%#x(num)"      == "0x2a"
            @test f"\%#o(num)"      == "052"
            @test f"\%x(num)"       == "2a"
            @test f"\%X(num)"       == "2A"
            @test f"\% i(num)"      == " 42"
            @test f"\%+i(num)"      == "+42"
            @test f"\%4i(num)"      == "  42"
            @test f"\%-4i(num)"     == "42  "
            @test f"\%a(num)"       == "0x2.ap+4"
            @test f"\%A(num)"       == "0X2.AP+4"
            @test f"\%20a(num)"     == "            0x2.ap+4"
            @test f"\%-20a(num)"    == "0x2.ap+4            "
            @test f"\%f(num)"       == "42.000000"
            @test f"\%g(num)"       == "42"
        end
    end
    @testset "pointers" begin
        @static if Sys.WORD_SIZE == 64
                    @test f"\%20p(0)"  == "  0x0000000000000000"
                    @test f"\%-20p(0)" == "0x0000000000000000  "
                elseif Sys.WORD_SIZE == 32
                    @test f"\%20p(0)"  == "          0x00000000"
                    @test f"\%-20p(0)" == "0x00000000          "
                else
                    @test false
                end
    end
    @testset "float / BigFloat" begin
        for num in (1.2345, big"1.2345")
            @test f"\%7.2f(num)"  == "   1.23"
            @test f"\%-7.2f(num)" == "1.23   "
            @test f"\%07.2f(num)" == "0001.23"
            @test f"\%.0f(num)"   == "1"
            @test f"\%#.0f(num)"  == "1."
            @test f"\%.4e(num)"   == "1.2345e+00"
            @test f"\%.4E(num)"   == "1.2345E+00"
            @test f"\%.2a(num)"   == "0x1.3cp+0"
            @test f"\%.2A(num)"   == "0X1.3CP+0"
        end
    end
    @testset "Inf / NaN handling" begin
        bf = big"Inf"
        bn = big"NaN"
        @test f"\%f(Inf)" == "Inf"
        @test f"\%f(NaN)" == "NaN"
        @test f"\%f(bf)"  == "Inf"
        @test f"\%f(bn)"  == "NaN"
    end
    @testset "scientific notation" begin
        fv = 3e142
        bv = big"3e142"
        @test f"\%.0e(fv)"  == "3e+142"
        @test f"\%#.0e(fv)" == "3.e+142"
        @test f"\%.0e(bv)"  == "3e+142"
        @test f"\%#.0e(bv)" == "3.e+142"
        bv = big"3e1042"
        @test f"\%.0e(bv)"   == "3e+1042"
        @test f"\%e(3e42)"   == "3.000000e+42"
        @test f"\%E(3e42)"   == "3.000000E+42"
        @test f"\%e(3e-42)"  == "3.000000e-42"
        @test f"\%E(3e-42)"  == "3.000000E-42"
        @test f"\%a(3e4)"    == "0x1.d4cp+14"
        @test f"\%A(3e4)"    == "0X1.D4CP+14"
        @test f"\%.4a(3e-4)" == "0x1.3a93p-12"
        @test f"\%.4A(3e-4)" == "0X1.3A93P-12"
    end
    @testset "%g" begin
        for (val, res) in (
            (12345678., "1.23457e+07"),
            (1234567.8, "1.23457e+06"),
            (123456.78, "123457"),
            (12345.678, "12345.7"),
            (12340000.0, "1.234e+07"),
            (big"12345678.", "1.23457e+07"),
            (big"1234567.8", "1.23457e+06"),
            (big"123456.78", "123457"),
            (big"12345.678", "12345.7"))
            @test f"\%.6g(val)" == res
        end
        for num in (123.4, big"123.4")
            @test f"\%10.5g(num)"   == "     123.4"
            @test f"\%+10.5g(num)"  == "    +123.4"
            @test f"\% 10.5g(num)"  == "     123.4"
            @test f"\%#10.5g(num)"  == "    123.40"
            @test f"\%-10.5g(num)"  == "123.4     "
            @test f"\%-+10.5g(num)" == "+123.4    "
            @test f"\%010.5g(num)"  == "00000123.4"
        end
        bv = big"-123.4"
        b2 = big"12340000.0"
        @test f"\%10.5g(-123.4)"    == "    -123.4"
        @test f"\%010.5g(-123.4)"   == "-0000123.4"
        @test f"\%.6g(12340000.0)"  == "1.234e+07"
        @test f"\%#.6g(12340000.0)" == "1.23400e+07"
        @test f"\%10.5g(bv)"        == "    -123.4"
        @test f"\%010.5g(bv)"       == "-0000123.4"
        @test f"\%.6g(b2)"          == "1.234e+07"
        @test f"\%#.6g(b2)"         == "1.23400e+07"
        @test f"\%.5g(42)"          == "42"
        @test f"\%#.2g(42)"         == "42."
        @test f"\%#.5g(42)"         == "42.000"
    end

    @testset "hex float" begin
        bv = big"1.5"
        @test f"\%a(1.5)"    == "0x1.8p+0"
        @test f"\%a(1.5f0)"  == "0x1.8p+0"
        @test f"\%a(bv)"     == "0x1.8p+0"
        @test f"\%#.0a(1.5)" == "0x2.p+0"
        @test f"\%+30a(1/3)" == "         +0x1.5555555555555p-2"
    end

    @testset "chars" begin
        @test f"\%c(65)"    == "A"
        @test f"\%c('A')"   == "A"
        @test f"\%3c('A')"  == "  A"
        @test f"\%-3c('A')" == "A  "
        @test f"\%c(248)"   == "ø"
        @test f"\%c('ø')"   == "ø"
    end

    @testset "type width specifier parsing (ignored)" begin
        @test f"\%llf(1.2)" == "1.200000"
        @test f"\%Lf(1.2)"  == "1.200000"
        @test f"\%hhu(1)"   == "1"
        @test f"\%hu(1)"    == "1"
        @test f"\%lu(1)"    == "1"
        @test f"\%llu(1)"   == "1"
        @test f"\%Lu(1)"    == "1"
        @test f"\%zu(1)"    == "1"
        @test f"\%ju(1)"    == "1"
        @test f"\%tu(1)"    == "1"
    end

    @testset "strings" begin
        s1 = "test"
        s2 = "tést"

        @test f"\%s(s1)"   == s1
        @test f"\%s(s2)"   == s2

        @test f"\%8s(s1)"  == "    test"
        @test f"\%-8s(s1)" == "test    "

        # This was broken in v0.5
        @static if VERSION >= v"0.6-"
            @test f"\%8.3s(s1)"    == "     tes"
            @test f"\%#8.3s(s1)"   == "     \"te"
            @test f"\%-8.3s(s1)"   == "tes     "
            @test f"\%#-8.3s(s1)"  == "\"te     "
            @test f"\%.3s(s1)"     == "tes"
            @test f"\%#.3s(s1)"    == "\"te"
            @test f"\%-.3s(s1)"    == "tes"
            @test f"\%#-.3s(s1)"   == "\"te"
        end
    end

    @testset "type based formatting" begin
        fmt_default!()        # resets all defaults

        # some basic functionality testing
        x = 1234.56789

        @test f"\%(x)"             == "1234.567890"
        @test f"\%(x;prec=2)"      == "1234.57"
        @test f"\%(x,10,3)"        == "  1234.568"
        @test f"\%(x,10,3,:left)"  == "1234.568  "
        @test f"\%(x,10,3,:ljust)" == "1234.568  "
        @test f"\%(x,:commas)"     == "1,234.567890"

        i = 1234567

        @test f"\%(i)" == "1234567"
        @test f"\%(i,:commas)" == "1,234,567"

        fmt_default!(Int, :commas, width = 12)
        @test f"\%(i)" == "   1,234,567"
        @test f"\%(x)" == "1234.567890"  # default hasn't changed

        fmt_default!(:commas)
        @test f"\%(i)" == "   1,234,567"
        @test f"\%(x)" == "1,234.567890"  # width hasn't changed, but added commas

        fmt_default!(Int) # resets Integer defaults
        @test f"\%(i)" == "1234567"
        @test f"\%(i,:commas)" == "1,234,567"
    end
end

@testset "Python Formatting" begin
    @testset "Format string" begin
        s = "abc"
        @test f"\{}(s)"     == "abc"
        @test f"\{s}(s)"    == "abc"
        @test f"\{2s}(s)"   == "abc"
        @test f"\{5s}(s)"   == "abc  "
        @test f"\{>5s}(s)"  == "  abc"
        @test f"\{*>5s}(s)" == "**abc"
        @test f"\{*<5s}(s)" == "abc**"
    end

    @testset "Format Char" begin
        @test f"\{}('c')"     == "c"
        @test f"\{c}('c')"    == "c"
        @test f"\{3c}('c')"   == "c  "
        @test f"\{>3c}('c')"  == "  c"
        @test f"\{*>3c}('c')" == "**c"
        @test f"\{*<3c}('c')" == "c**"
    end

    @testset "Format integer" begin
        @test f"\{}(1234)" == "1234"
        @test f"\{d}(1234)" == "1234"
        @test f"\{n}(1234)" == "1234"
        @test f"\{x}(0x2ab)" == "2ab"
        @test f"\{X}(0x2ab)" == "2AB"
        @test f"\{o}(0o123)" == "123"
        @test f"\{b}(0b1101)" == "1101"

        @test f"\{d}(0)" == "0"
        @test f"\{d}(9)" == "9"
        @test f"\{d}(10)" == "10"
        @test f"\{d}(99)" == "99"
        @test f"\{d}(100)" == "100"
        @test f"\{d}(1000)" == "1000"

        @test f"\{06d}(123)" == "000123"
        @test f"\{+6d}(123)" == "  +123"
        @test f"\{+06d}(123)" == "+00123"
        @test f"\{ d}(123)" == " 123"
        @test f"\{ 6d}(123)" == "   123"
        @test f"\{<6d}(123)" == "123   "
        @test f"\{>6d}(123)" == "   123"
        @test f"\{*<6d}(123)" == "123***"
        @test f"\{*>6d}(123)" == "***123"
        @test f"\{< 6d}(123)" == " 123  "
        @test f"\{<+6d}(123)" == "+123  "
        @test f"\{> 6d}(123)" == "   123"
        @test f"\{>+6d}(123)" == "  +123"

        @test f"\{+d}(-123)" == "-123"
        @test f"\{-d}(-123)" == "-123"
        @test f"\{ d}(-123)" == "-123"
        @test f"\{06d}(-123)" == "-00123"
        @test f"\{<6d}(-123)" == "-123  "
        @test f"\{>6d}(-123)" == "  -123"
    end

    @testset "Format floating point (f)" begin

        @test f"\{}(0.125)" == "0.125"
        @test f"\{f}(0.0)" == "0.000000"
        @test f"\{f}(0.001)" == "0.001000"
        @test f"\{f}(0.125)" == "0.125000"
        @test f"\{f}(1.0/3)" == "0.333333"
        @test f"\{f}(1.0/6)" == "0.166667"
        @test f"\{f}(-0.125)" == "-0.125000"
        @test f"\{f}(-1.0/3)" == "-0.333333"
        @test f"\{f}(-1.0/6)" == "-0.166667"
        @test f"\{f}(1234.5678)" == "1234.567800"
        @test f"\{8f}(1234.5678)" == "1234.567800"

        @test f"\{8.2f}(8.376)" == "    8.38"
        @test f"\{<8.2f}(8.376)" == "8.38    "
        @test f"\{>8.2f}(8.376)" == "    8.38"
        @test f"\{8.2f}(-8.376)" == "   -8.38"
        @test f"\{<8.2f}(-8.376)" == "-8.38   "
        @test f"\{>8.2f}(-8.376)" == "   -8.38"

        @test f"\{<08.2f}(8.376)" == "00008.38"
        @test f"\{>08.2f}(8.376)" == "00008.38"
        @test f"\{<08.2f}(-8.376)" == "-0008.38"
        @test f"\{>08.2f}(-8.376)" == "-0008.38"
        @test f"\{*<8.2f}(8.376)" == "8.38****"
        @test f"\{*>8.2f}(8.376)" == "****8.38"
        @test f"\{*<8.2f}(-8.376)" == "-8.38***"
        @test f"\{*>8.2f}(-8.376)" == "***-8.38"

        @test f"\{.2f}(0.999)" == "1.00"
        @test f"\{.2f}(0.996)" == "1.00"
        # Floating point error can upset this one (i.e. 0.99500000 or 0.994999999)
        @test (f"\{.2f}(0.995)" == "1.00" || f"\{.2f}(0.995)" == "0.99")
        @test f"\{.2f}(0.994)" == "0.99"
    end

    @testset "Format floating point (e)" begin

        @test f"\{E}(0.0)" == "0.000000E+00"
        @test f"\{e}(0.0)" == "0.000000e+00"
        @test f"\{e}(0.001)" == "1.000000e-03"
        @test f"\{e}(0.125)" == "1.250000e-01"
        @test f"\{e}(100/3)" == "3.333333e+01"
        @test f"\{e}(-0.125)" == "-1.250000e-01"
        @test f"\{e}(-100/6)" == "-1.666667e+01"
        @test f"\{e}(1234.5678)" == "1.234568e+03"
        @test f"\{8e}(1234.5678)" == "1.234568e+03"

        @test f"\{<12.2e}(13.89)" == "1.39e+01    "
        @test f"\{>12.2e}(13.89)" == "    1.39e+01"
        @test f"\{*<12.2e}(13.89)" == "1.39e+01****"
        @test f"\{*>12.2e}(13.89)" == "****1.39e+01"
        @test f"\{012.2e}(13.89)" == "00001.39e+01"
        @test f"\{012.2e}(-13.89)" == "-0001.39e+01"
        @test f"\{+012.2e}(13.89)" == "+0001.39e+01"

        @test f"\{.1e}(0.999)" == "1.0e+00"
        @test f"\{.1e}(0.996)" == "1.0e+00"
        # Floating point error can upset this one (i.e. 0.99500000 or 0.994999999)
        @test (f"\{.1e}(0.995)" == "1.0e+00" || f"\{.1e}(0.995)" == "9.9e-01")
        @test f"\{.1e}(0.994)" == "9.9e-01"
        @test f"\{.1e}(0.6)" == "6.0e-01"
        @test f"\{.1e}(0.9)" == "9.0e-01"
    end

    @testset "Format special floating point value" begin

        @test f"\{f}(NaN)" == "NaN"
        @test f"\{e}(NaN)" == "NaN"
        @test f"\{f}(NaN32)" == "NaN"
        @test f"\{e}(NaN32)" == "NaN"

        @test f"\{f}(Inf)" == "Inf"
        @test f"\{e}(Inf)" == "Inf"
        @test f"\{f}(Inf32)" == "Inf"
        @test f"\{e}(Inf32)" == "Inf"

        @test f"\{f}(-Inf)" == "-Inf"
        @test f"\{e}(-Inf)" == "-Inf"
        @test f"\{f}(-Inf32)" == "-Inf"
        @test f"\{e}(-Inf32)" == "-Inf"

        @test f"\{<5f}(Inf)" == "Inf  "
        @test f"\{>5f}(Inf)" == "  Inf"
        @test f"\{*<5f}(Inf)" == "Inf**"
        @test f"\{*>5f}(Inf)" == "**Inf"
    end

    @testset "test commas..." begin
        @test f"\%'d(1000)" == "1,000"
        @test f"\%'d(-1000)" == "-1,000"
        @test f"\%'d(100)" == "100"
        @test f"\%'d(-100)" == "-100"
        @test f"\%'f(Inf)" == "Inf"
        @test f"\%'f(-Inf)" == "-Inf"
        @test f"\%'s(1000.0)" == "1,000.0"
        @test f"\%'s(1234567.0)" == "1.234567e6"
    end # testset test commas
end

@testset "Print macro support" begin
    io = IOBuffer()
    scott = 123
    pr"\(io)This is a test with \(scott)"
    @test ts(io) == "This is a test with 123"
end

@testset "escape, unescape" begin
    @test s_escape_string(f"' \" \\ \u{7f} \u{20ac} \u{1f596} \u{e0000}") ==
        "' \\\" \\\\ \\u{7f} € 🖖 \\u{e0000}"
    @test s_unescape_string(f"' \\\" \\\\ \\u{7f} € 🖖 \\u{e0000}") ==
        "' \" \\ \x7f € 🖖 \Ue0000"
    io = IOBuffer()
    s_print_escaped(io, f"' \" \\ \u{7f} \u{20ac} \u{1f596} \u{e0000}", "")
    @test ts(io) == f"' \" \\\\ \\u{7f} € 🖖 \\u{e0000}"
    io = IOBuffer()
    s_print_unescaped(io, f"' \" \\\\ \\u{7f} € 🖖 \\u{e0000}")
    @test ts(io) == "' \" \\ \x7f € 🖖 \Ue0000"
end
