export Read, @tag_str, calc_distance, calc_ref_pos, calc_read_pos, map_to_read, map_to_ref, phred_to_prob, prob_to_phred

const seqcode = b"=ACMGRSVTWYHKDBN"

macro tag_str(x)
    reinterpret(u16, x.data)[1]
end

#===
NOTE: about pos of indels:
      relpos of insertion: first base of the insertion
      refpos of insertion: the base before the insertion
      relpos of deletion:  the base before the deletion
      refpos of deletion:  fitst base of the deletion
all positions are 1-based
===#

type Read
    refID::i32
    pos::i32
    mapq::Byte
    flag::u16
    next_refID::i32
    next_pos::i32
    tlen::i32
    qname::String
    cigar::Vector{u32}
    seq::Bytes
    qual::Bytes
    tags::Dict{u16, Any}
    muts::Vector{Mut}
    mate::Read

    function Read(f::IO)
        block_size = f >> i32
        refID      = f >> i32
        pos        = f >> i32
        l_qname    = f >> Byte
        mapq       = f >> Byte
        n_cigar_op = f >>> u16 >> u16
        flag       = f >> u16
        l_seq      = f >> i32
        next_refID = f >> i32
        next_pos   = f >> i32
        tlen       = f >> i32
        qname      = f >> l_qname |> del_end! |> String

        cigar = read(f, u32, n_cigar_op)

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
        tags = f >> (block_size - 32 - l_qname - 4*n_cigar_op - (l_seq+1)÷2 - l_seq) |> parse_tags

        muts = if n_cigar_op != 0
            if haskey(tags, tag"MD")
                try
                    reconstruct_mut_by_md(cigar, tags[tag"MD"], seq)
                catch
                    Mut[]
                end
            else
                println(STDERR, "no `MD` found, try with --reference")
                Mut[]
            end
        else
            Mut[]
        end

        new(refID, pos+1, mapq, flag, next_refID, next_pos+1, tlen, qname, cigar, seq, qual, tags, muts)
    end
end

function hastag(r::Read, tag::u16)
    tag in r.tags
end

function getindex(r::Read, tag::u16)
    get(r.tags, tag, nothing)
end

function setindex!(r::Read, value, tag)
    r.tags[reinterpret(u16, string(tag).data)[1]] = value
end

function parse_tags(x::Bytes)
    f    = IOBuffer(x)
    tags = Dict{u16, Any}()

    while !eof(f)
        tag = f >> u16
        c   = f >> Byte
        value = c == Byte('Z') ? readuntil(f, '\0') |> del_end! :
                c == Byte('i') ? f >> Int32 :
                c == Byte('I') ? f >> UInt32 :
                c == Byte('c') ? f >> Int8 :
                c == Byte('C') ? f >> UInt8 :
                c == Byte('s') ? f >> Int16 :
                c == Byte('S') ? f >> UInt16 :
                c == Byte('f') ? f >> Float32 :
                c == Byte('A') ? f >> Byte |> Char :
                c == Byte('H') ? error("TODO") :
                c == Byte('B') ? error("TODO") :
                error("unknown tag type $(Char(c))")
        tags[tag] = value
    end

    tags
end

function show(io::IO, r::Read)
    io << r.qname << '\n'

    @printf(io, "ChrID: %-2d  Pos(1-based): %-9d  MapQ(0-60): %-d\n", r.refID,      r.pos,      r.mapq)
    @printf(io, "RNext: %-2d  PNext       : %-9d  TempLength: %-d\n", r.next_refID, r.next_pos, r.tlen)

    io << "Cigar: "
    isempty(r.cigar) ? io << '*' : for i in r.cigar
        io << (i >> 4) << cigarcode[i&0x0f+1]
    end
    @printf(io, "  Flag: %d (", r.flag)
    showflag(io, r.flag)
    io << ")\n"

    io << r.seq << '\n'
    io << (r.qual[1] == 0xff ? '*' : map(x->x+0x21, r.qual)) << '\n'

    for (k,v) in r.tags
        write(io, k)
        io << ':' << tagtype(v) << ':' << v << "  "
    end

    io << '\n'
    for i in r.muts
        io << i << ' '
    end

    io << '\n'
end

function showflag(io::IO, flag::u16)
    is_first = true
    interpunct() = is_first ? (is_first=false; "") : " · "
    flag & 0x0001 != 0 && io << interpunct() << "pair_seq"
    flag & 0x0002 != 0 && io << interpunct() << "aligned"
    flag & 0x0004 != 0 && io << interpunct() << "unmapped"
    flag & 0x0008 != 0 && io << interpunct() << "mate_unmapped"
    flag & 0x0010 != 0 && io << interpunct() << "reverse"
    flag & 0x0020 != 0 && io << interpunct() << "mate_reverse"
    flag & 0x0040 != 0 && io << interpunct() << "r1"
    flag & 0x0080 != 0 && io << interpunct() << "r2"
    flag & 0x0100 != 0 && io << interpunct() << "secondary"
    flag & 0x0200 != 0 && io << interpunct() << "not_pass_filter"
    flag & 0x0400 != 0 && io << interpunct() << "duplicate"
    flag & 0x0800 != 0 && io << interpunct() << "supplementary"
    io
end

"distance between the first and last base in ref"
function calc_distance(r::Read)
    reduce(0, r.cigar) do len, cigar
        ifelse(cigar&0b1101 == 0, len + cigar>>4, len)
    end
end

# return (ref_pos, cigar_op)
function calc_ref_pos(r::Read, relpos::Integer)
    refpos = r.pos - 1
    for cigar in r.cigar
        λ"""
        switch((& cigar 0x0f)
               *0 .((min (>> cigar 4) relpos)
                    ?((== relpos .)
                      return('((+ refpos .) 0x00))
                      >(=(relpos (- relpos .))
                        =(refpos (+ refpos .)))))
               *1 .((min (>> cigar 4) relpos)
                    ?((== relpos .)
                      return('(refpos 0x01))
                      =(relpos (- relpos .))))
               *2 =(refpos (+ refpos (>> cigar 4)))
               *4 .((min (>> cigar 4) relpos)
                    ?((== relpos .)
                      return('(refpos 0x04))
                      =(relpos (- relpos .))))
               *5 >()
               (error "TODO: cigar op not supported"))
        """
    end
    i32(0), 0xff
end

function calc_read_pos(r::Read, refpos::Integer)
    relpos, refpos = 0, refpos - r.pos + 1
    for cigar in r.cigar
        λ"""
        switch((& cigar 0x0f)
               *0 .((min (>> cigar 4) refpos)
                    ?((== refpos .)
                      return('((+ relpos .) 0x00))
                      >(=(relpos (+ relpos .))
                        =(refpos (- refpos .)))))
               *1 =(relpos (+ relpos (>> cigar 4)))
               *2 .((min (>> cigar 4) refpos)
                    ?((== refpos .)
                      return('(relpos 0x02))
                      =(refpos (- refpos .))))
               *4 =(relpos (+ relpos (>> cigar 4)))
               *5 >()
               (error "TODO: cigar op not supported"))
        """
    end
    i32(0), 0xff
end

map_to_read(x::SNP, r::Read)       = SNP(car(calc_read_pos(r, x.pos)), x.ref, x.alt)
map_to_read(x::Insertion, r::Read) = Insertion(car(calc_read_pos(r, x.pos))+1, x.bases)
map_to_read(x::Deletion, r::Read)  = Deletion(car(calc_read_pos(r, x.pos)), x.bases)
map_to_ref(x::SNP, r::Read)        = SNP(car(calc_ref_pos(r, x.pos)), x.ref, x.alt)
map_to_ref(x::Insertion, r::Read)  = Insertion(car(calc_ref_pos(r, x.pos)), x.bases)
map_to_ref(x::Deletion, r::Read)   = Deletion(car(calc_ref_pos(r, x.pos))+1, x.bases)

phred_to_prob(x) = 10 ^ (-i64(x) / 10)
prob_to_phred(x) = rount(Byte, -10 * log(10, x))

function del_end!(s::Bytes)
    ccall(:jl_array_del_end, Void, (Any, UInt), s, 1)
    return s
end

function del_end!(s::String)
    ccall(:jl_array_del_end, Void, (Any, UInt), s.data, 1)
    return s
end

