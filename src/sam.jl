export write_sam

const cigarcode = b"MIDNSHP=X"

function write_sam(f::IO, bam::Bam, reads)
    f << bam.header_chunk
    for r in reads
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

        r[tag"XX"] # force parse tags

        for (k,v) in r.tags
            write(f, '\t', k)
            f << ':' << tagtype(v) << ':' << v
        end

        f << '\n'
    end
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