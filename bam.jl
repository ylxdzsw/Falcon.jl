immutable Bam
    header_chunk::Bytes
    refs::Vector{Tuple{String, Int32}}
    handle::IO

    function Bam(f::IO)
        check_magic(f)
        l_text = f >> Int32
        text   = f >> l_text
        n_ref  = f >> Int32

        refs   = Vector{Tuple{String, Int32}}(n_ref)
        for i in 1:n_ref
            l_name  = f >> Int32
            name    = f >> (l_name - 1)
            l_ref   = f >>> 1 >> Int32
            refs[i] = name, l_ref
        end

        new(text, refs, f)
    end
end

Bam(x::AbstractString) = Bam(open(x))

function check_magic(f::IO)
    a, b, c, d = f >> 4
    if a == 0x1f && b == 0x8b
        error("Falcon cannot deal with compressed bam, try with `gzip -cd`")
    elseif a == 0x42 && b == 0x41 && c == 0x4d
        d == 0x01 || error("unsupported bam version")
    elseif (a == 0xff && b == 0xfe) || (a == 0xfe && b == 0xff)
        error("Windows currently not supported, generate your file in *nix environment")
    else
        error("cannot recogize file type; is it a valid bam?")
    end
end

start(bam::Bam)           = nothing
next(bam::Bam, ::Void)    = Read(bam.handle), nothing
done(bam::Bam, ::Void)    = eof(bam.handle)
iteratorsize(::Type{Bam}) = Base.SizeUnknown()
eltype(::Type{Bam})       = Read

show(io::IO, bam::Bam) = show(io, "Bam($(bam.handle.name))")
