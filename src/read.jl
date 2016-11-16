export Read, @tag_str

const seqcode = b"=ACMGRSVTWYHKDBN"

type Read
    refID::Int32
    pos::Int32
    mapq::Byte
    flag::UInt16
    next_refID::Int32
    next_pos::Int32
    tlen::Int32
    qname::String
    cigar::Vector{UInt32}
    seq::Bytes
    qual::Bytes
    tags::Union{Bytes, Dict{UInt16, Any}}

    function Read(f::IO)
        block_size = f >> Int32
        refID      = f >> Int32
        pos        = f >> Int32
        l_qname    = f >> Byte
        mapq       = f >> Byte
        n_cigar_op = f >>> UInt16 >> UInt16
        flag       = f >> UInt16
        l_seq      = f >> Int32
        next_refID = f >> Int32
        next_pos   = f >> Int32
        tlen       = f >> Int32
        qname      = f >> l_qname |> del_end! |> String

        cigar = read(f, UInt32, n_cigar_op)

        seq = Bytes(l_seq)
        for i in 1:l_seq÷2
            c = f >> Byte
            seq[2i-1] = seqcode[c>>4+1]
            seq[2i] = seqcode[c&0x0f+1]
        end
        if isodd(l_seq)
            seq[l_seq] = seqcode[f>>Byte>>4+1]
        end

        qual = f >> l_seq
        tags = f >> (block_size - 32 - l_qname - 4*n_cigar_op - (l_seq+1)÷2 - l_seq)

        new(refID, pos, mapq, flag, next_refID, next_pos, tlen, qname, cigar, seq, qual, tags)
    end
end

macro tag_str(x)
    reinterpret(UInt16, x.data)[1]
end

function getindex(r::Read, tag::UInt16)
    if !isa(r.tags, Dict)
        r.tags = parse_tags(r.tags)
    end

    get(r.tags, tag, nothing)
end

function parse_tags(x::Bytes)
    f    = IOBuffer(x)
    tags = Dict{UInt16, Any}()

    while !eof(f)
        tag = f >> UInt16
        c   = f >> Byte
        value = c == Byte('A') ? f >> Byte |> Char :
                c == Byte('c') ? f >> Int8 :
                c == Byte('C') ? f >> UInt8 :
                c == Byte('s') ? f >> Int16 :
                c == Byte('S') ? f >> UInt16 :
                c == Byte('i') ? f >> Int32 :
                c == Byte('I') ? f >> UInt32 :
                c == Byte('f') ? f >> Float32 :
                c == Byte('Z') ? readuntil(f, '\0') |> del_end! :
                c == Byte('H') ? error("TODO") :
                c == Byte('B') ? error("TODO") :
                error("unknown tag type $(Char(c))")
        tags[tag] = value
    end

    tags
end

function del_end!(s::Bytes)
    ccall(:jl_array_del_end, Void, (Any, UInt), s, 1)
    return s
end

function del_end!(s::String)
    ccall(:jl_array_del_end, Void, (Any, UInt), s.data, 1)
    return s
end
