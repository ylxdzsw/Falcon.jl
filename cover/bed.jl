function import_panel(name::AbstractString, bedfile::AbstractString)
    open(rel".." * "/data/panel/$name.panel", "w") do f
        chr, buf = "", IOBuffer()

        for line in eachline(bedfile) @when length(line) > 1
            c, a, b = split(line)
            if c != chr
                if chr != ""
                    data = takebuf_array(buf)
                    write(f, chr, '\0', length(data)>>3, data)
                end
                chr = c
            end

            a, b = parse(i32, a)+i32(1), parse(i32, b)
            write(buf, a, b)
        end

        data = takebuf_array(buf)
        write(f, chr, '\0', length(data)>>3, data)
    end
end

function load_panel(name::AbstractString)
    panel = Dict{String, IntRangeSet{i32}}()
    open(rel".." * "/data/panel/$name.panel") do f
        while !eof(f)
            chr = readuntil(f, '\0')[1:end-1]
            len = f >> i64
            buf = read(f, i32, 2len)

            p = panel[chr] = IntRangeSet{i32}()

            for i in 1:len
                push!(p, buf[2i-1]:buf[2i])
            end
        end
    end
    panel
end
