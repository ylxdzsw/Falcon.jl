export pileup

using Base.Collections

type Pileuper{T}
    reads::T
    window::PriorityQueue{Read, Int32, Base.Order.ForwardOrdering} # Read -> ref pos of last matching base
    muts::PriorityQueue{Mut, Int32, Base.Order.ForwardOrdering}    # Mut  -> pos
    chr::Int32
    Pileuper(x::T) = new(x, PriorityQueue(Read, Int32), PriorityQueue(Mut, Int32), -2)
end

pileup{T}(x::T) = pileup(Pileuper{T}(x))

function pileup{T}(p::Pileuper{T})
    for r in p.reads
        if r.refID != p.chr
            flush_muts!(p)
            p.chr = r.refID
        end
        add_muts!(p, r)
    end
    flush_muts!(p)
end

function produce_muts!{T}(p::Pileuper{T})
    mut = dequeue!(p.muts)

    while !isempty(p.window) && peek(p.window).second < mut.pos
        dequeue!(p.window)
    end

    produce((keys(p.window), p.chr, mut))
end

function flush_muts!{T}(p::Pileuper{T})
    while !isempty(p.muts)
        produce_muts!(p)
    end

    # clear p.window by hack; not sure if this is faster than just allocating a new one
    empty!(p.window.xs)
    empty!(p.window.index)
end

function add_muts!{T}(p::Pileuper{T}, r::Read)
    while !isempty(p.muts) && peek(p.muts).second < r.pos
        produce_muts!(p)
    end

    enqueue!(p.window, r, r.pos + calc_distance(r) - 1)

    for mut in r.muts
        mut = map_to_ref(mut, r)
        haskey(p.muts, mut) || enqueue!(p.muts, mut, mut.pos)
    end
end
