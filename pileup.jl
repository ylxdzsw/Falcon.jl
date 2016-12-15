using Base.Collections

type Pileuper
    reads::Vector{Read}
    window::PriorityQueue{Read, Int32, Base.Order.ForwardOrdering} # Read -> ref pos of last matching base
    muts::PriorityQueue{Mut, Int32, Base.Order.ForwardOrdering}    # Mut  -> pos
    chr::Int32
    Pileuper(x) = new(x, PriorityQueue(Read, Int32), PriorityQueue(Mut, Int32), -2)
end

pileup(x) = pileup(Pileuper(x))

function pileup(p::Pileuper)
    for r in p.reads
        if r.refID != p.chr
            flush_muts(p)
            p.chr = r.refID
        end
        add_muts(p, r)
    end
    flush_muts(p)
end

function produce_muts(p::Pileuper)
    produce((keys(p.window), p.chr, dequeue!(p.muts)))

    if !isempty(p.muts)
        pos = peek(p.muts).second
        while !isempty(p.window) && peek(p.window).second < pos
            dequeue!(p.window)
        end
    end
end

function flush_muts(p::Pileuper)
    while !isempty(p.muts)
        produce_muts(p)
    end
end

function add_muts(p::Pileuper, r::Read)
    while !isempty(p.muts) && peek(p.muts).second < r.pos
        produce_muts(p)
    end

    enqueue!(p.window, r, r.pos + calc_ref_length(r) - 1)

    for mut in r.muts
        mut = map_to_ref(mut, r)
        haskey(p.muts, mut) || enqueue!(p.muts, mut, mut.pos)
    end
end