export Bam, BamLoader

abstract AbstractBam

immutable BamLoader <: AbstractBam
    file::AbstractString
    header_chunk::Bytes
    refs::Vector{Tuple{String, i32}}
    handle::IO

    function BamLoader(file::AbstractString)
        f = open(file) |> ZlibInflateInputStream
        @assert f >> 4 == [0x42, 0x41, 0x4d, 0x01]

        l_text = f >> i32
        text   = f >> l_text
        n_ref  = f >> i32

        refs   = Vector{Tuple{String, i32}}(n_ref)
        for i in 1:n_ref
            l_name  = f >> i32
            name    = f >> (l_name - 1)
            l_ref   = f >>> 1 >> i32
            refs[i] = name, l_ref
        end

        new(file, text, refs, f)
    end
end

start(bl::BamLoader)            = nothing
next(bl::BamLoader, ::Void)     = Read(bl.handle), nothing
done(bl::BamLoader, ::Void)     = eof(bl.handle)
iteratorsize(::Type{BamLoader}) = Base.SizeUnknown()
eltype(::Type{BamLoader})       = Read

show(io::IO, bl::BamLoader) = show(io, "BamLoader($(bl.file))")

immutable Bam <: AbstractBam
    file::AbstractString
    header_chunk::Bytes
    refs::Vector{Tuple{String, i32}}
    reads::Vector{Read}
end

Bam(file::AbstractString) = let bl = BamLoader(file)
    Bam(bl.file, bl.header_chunk, bl.refs, collect(bl))
end

start(bam::Bam)           = start(bam.reads)
next(bam::Bam, x)         = next(bam.reads, x)
done(bam::Bam, x)         = done(bam.reads, x)
iteratorsize(::Type{Bam}) = iteratorsize(Vector{Read})
eltype(::Type{Bam})       = eltype(Vector{Read})

show(io::IO, bam::Bam) = show(io, "Bam($(bam.file))")
