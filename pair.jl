export fast_pair!, full_pair!

"only find mates for primary reads (flag & 0x900 == 0)"
function fast_pair!(reads::Vector{Read})
    namedict = Dict{String, Read}()
    for r in reads
        r.flag & 0x900 == 0 || continue
        if r.qname in keys(namedict)
            r.mate = namedict[r.qname]
            namedict[r.qname].mate = r
            delete!(namedict, r.qname)
        else
            namedict[r.qname] = r
        end
    end
    reads
end

"mates are primary reads"
function full_pair!(reads::Vector{Read})
    error("TODO")
end
