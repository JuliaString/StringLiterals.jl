using StringLiterals
using Base.Test

@testset "LaTeX Entities" begin
    @test f"\<dagger>" == "†"
    @test f"\<mscrl>" == "𝓁" # \U1f4c1
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
@testset "Valid quoted characters" begin
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
        @test_throws ArgumentError eval(parse(string("f\"\\", ch, '"')))
    end
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
        @static if VERSION >= v"0.6-dev"
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
