immutable VCFWriter
    bam::Bam
    io::IO
end

function open_vcf(filename::AbstractString, bam::Bam, with_header=true)
    x = VCFWriter(bam, open(filename, "w"))
    with_header && write_head(x)
    x
end

function open_vcf(f::Function, filename::AbstractString, bam::Bam, with_header=true)
    x = open_vcf(filename, bam, with_header)
    try
        f(x)
    finally
        close(x.io)
    end
end

function write_head(f::VCFWriter)
    f.io << """
    ##fileformat=VCFv4.2
    ##fileDate=$(Dates.format(now(), "yyyymmdd"))
    ##source=FalconV0.0.1
    ##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
    ##FORMAT=<ID=RD,Number=1,Type=Integer,Description="Depth of reference-supporting bases (reads1)">
    ##FORMAT=<ID=AD,Number=1,Type=Integer,Description="Depth of variant-supporting bases (reads2)">
    #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tCFDNA
    """
end

function write(f::VCFWriter, chr::Int32, m::Mut, data::Dict{String, Any})
    f.io << (chr == -1 ? '*' : car(f.bam.refs[chr+1])) << '\t'
    f.io << m.pos << '\t'
    f.io << '.'   << '\t' # ID, don't know what's that though
    λ"""switch(m
        (isa . SNP)       (write f.io m.ref         '\t' m.alt   '\t')
        (isa . Insertion) (write f.io (car m.bases) '\t' m.bases '\t')
        (isa . Deletion)  (write f.io m.bases       '\t' '.'     '\t'))
    """
    f.io << '.'    << '\t' # Qual
    f.io << "PASS" << '\t'
    f.io << '\t' # Info
    f.io << "DP:RD:AD" << '\t'
    f.io << data["DP"] << ':' << data["RD"] << ':' << data["AD"] << '\n'
end

