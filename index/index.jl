export get_index, ensure_index

typealias BamIndex Dict{String, IntRangeDict{i32, i32}}

function get_index(bam::AbstractBam)::BamIndex
    index = load_index(bam)
    index.isnull ? make_index(bam) : index.value
end

function make_index(bam::AbstractBam)::BamIndex
    index = BamIndex()
    chr = -2
    local dict::IntRangeDict{i32, i32}
    for (idx, read) in enumerate(bam) @when read.refID >= 0
        if read.refID != chr
            chr = read.refID
            index[bam.refs[chr+1] |> car] = dict = IntRangeDict{i32, i32}()
        end

        start = read.pos |> i32
        stop = read.pos + calc_distance(read) - 1 |> i32

        push!(dict[start:stop], i32(idx))
    end
    index
end

function save_index(bam::AbstractBam, index::BamIndex)
    if isempty(bam.file)
        error("cannot save index of stream bam")
    end

    bamtime = mtime(bam.file)
    f = open(bam.file * ".fbi", "w")

    f << b"FBIv1"
    write(f, bamtime)

    f = ZlibDeflateOutputStream(f)

    for (key, value) in index
        f << key << '\0'
        save(f, value)
    end

    close(f)
end

function load_index(bam::AbstractBam)::Nullable{BamIndex}
    if isempty(bam.file) || !isfile(bam.file * ".fbi")
        nothing
    end

    bamtime = mtime(bam.file)
    f = open(bam.file * ".fbi")

    try
        index = BamIndex()
        @assert f >> 5 == b"FBIv1"
        @assert f >> f64 == bamtime

        f = ZlibInflateInputStream(f)

        while !eof(f)
            name = readuntil(f, '\0') |> del_end!
            dict = IntRangeDict{i32, i32}(f)
            index[name] = dict
        end
        index
    catch
        nothing
    finally
        close(f)
    end
end

function ensure_index(bam::AbstractBam)
    if isempty(bam.file)
        error("cannot save index of stream bam")
    end

    bamtime = mtime(bam.file)

    if isfile(bam.file * ".fbi")
        try
            open(bam.file * ".fbi") do f
                f >> 5 == b"FBIv1" && f >> f64 == bamtime
            end && return
        end
    end

    save_index(bam, make_index(bam))
end
