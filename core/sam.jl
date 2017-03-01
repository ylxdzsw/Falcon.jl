export write_sam_head, write_sam_line

const cigarcode = b"MIDNSHP=X"

function write_sam_head(f::IO, bam::Bam)
    f << bam.header_chunk
end

function write_sam_line(f::IO, bam::Bam, r)
    f << r.qname << '\t' << r.flag << '\t' << (r.refID == -1 ? '*' : car(bam.refs[r.refID+1]))
    f << '\t' << (r.pos + 1) << '\t' << Int(r.mapq) << '\t'

    isempty(r.cigar) ? f << '*' : for i in r.cigar
        f << (i >> 4) << cigarcode[i&0x000f+1]
    end

    f << '\t' << (r.next_refID == -1      ? '*' :
                  r.next_refID == r.refID ? '=' :
                  car(bam.refs[r.next_refID+1]))
    f << '\t' << (r.next_pos + 1) << '\t' << r.tlen << '\t' << r.seq
    f << '\t' << (r.qual[1] == 0xff ? '*' : map(x->x+0x21, r.qual))

    for (k,v) in r.tags
        write(f, '\t', k)
        if isa(v, Integer)
            v = i64(v)
        end
        f << ':' << tagtype(v) << ':' << v
    end

    f << '\n'
end

tagtype(::Char)    = Byte('A')
tagtype(::Integer) = Byte('i') # Sam only have "i" type
# tagtype(::Int8)    = Byte('c')
# tagtype(::UInt8)   = Byte('C')
# tagtype(::Int16)   = Byte('s')
# tagtype(::UInt16)  = Byte('S')
# tagtype(::Int32)   = Byte('i')
# tagtype(::UInt32)  = Byte('I')
tagtype(::Float32) = Byte('f')
tagtype(::String)  = Byte('Z')
