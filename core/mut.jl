export SNP, Insertion, Deletion

abstract Mut

immutable SNP <: Mut
    pos::i32
    ref::Byte
    alt::Byte
end

immutable Insertion <: Mut
    pos::i32
    bases::Bytes
end

immutable Deletion <: Mut
    pos::i32
    bases::Bytes
end

==(x::SNP, y::SNP)             = x.pos==y.pos && x.ref==y.ref && x.alt==y.alt
==(x::Insertion, y::Insertion) = x.pos==y.pos && x.bases==y.bases
==(x::Deletion, y::Deletion)   = x.pos==y.pos && x.bases==y.bases
hash(x::SNP, y::u64)           = hash(x.pos, hash(x.ref, hash(x.alt, y)))
hash(x::Insertion, y::u64)     = hash(x.pos, hash(x.bases, y))
hash(x::Deletion, y::u64)      = hash(x.pos, hash(x.bases, y))
show(io::IO, snp::SNP)         = io << "SNP(" << snp.pos << ":" << snp.ref << "->" << snp.alt << ')'
show(io::IO, indel::Insertion) = io << "Insertion(" << indel.pos << ":" << indel.bases << ')'
show(io::IO, indel::Deletion)  = io << "Deletion(" << indel.pos << ":" << indel.bases << ')'

macro advance_cigar()
    esc(quote
        i += 1
        i > length(cigar) && break
        op, len = cigar[i] & 0x0f, cigar[i] >> 4
    end)
end

substring2byte(s::SubString{String}) = s.string.data[s.offset+1]

function reconstruct_mut_by_md(cigar, md, seq)
    md = matchall(r"\d+|[ATCG]|\^[ATCG]+", md)
    i, j, r, p = 1, 1, 0, 1
    op, len = cigar[i] & 0x0f, cigar[i] >> 4
    r = parse(Int, md[j])
    muts = Mut[]

    while true
        # ‘MIDNSHP=X’→‘012345678’
        if op == 0
            if j % 2 == 0 # SNP
                push!(muts, SNP(p, substring2byte(md[j]), seq[p]))
                len -= 1
                j += 1
                r = parse(Int, md[j])
                p += 1
            else # match
                l = min(len, r)
                len -= l
                r -= l
                p += l
                if r == 0
                    j += 1
                end
            end
            len == 0 && @advance_cigar
        elseif op == 1
            push!(muts, Insertion(p, seq[p:p+len-1]))
            p += len
            @advance_cigar
        elseif op == 2
            s = md[j][2:end] |> String
            push!(muts, Deletion(p-1, s.data))
            @advance_cigar
            j += 1
            r = parse(Int, md[j])
        elseif op == 4 # NOTE: `md` doesn't contains info about softcliped bases
            p += len
            @advance_cigar
        elseif op == 5
            @advance_cigar
        else
            error("TODO: cigar op: $op")
        end
    end

    muts
end

function reconstruct_mut_by_ref()

end
