function write_vcf_head(f::IO, info::String, filters::String)
    f << """
    ##fileformat=VCFv4.2
    ##fileDate=$(Dates.format(now(), "yyyymmdd"))
    ##source=FalconV0.0.1
    """ << info << filters << """
    ##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
    ##FORMAT=<ID=RD,Number=1,Type=Integer,Description="Depth of reference-supporting bases (reads1)">
    ##FORMAT=<ID=AD,Number=1,Type=Integer,Description="Depth of variant-supporting bases (reads2)">
    #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tCFDNA
    """
end

function write_vcf_line(f::IO, bam::Bam, chr::Int32, m::Mut, info::String, filters::Vector{String}, data::NTuple{3, Int})
    f << (chr == -1 ? '*' : car(bam.refs[chr+1])) << '\t'
    f << (isa(m, Deletion) ? m.pos-1 : m.pos) << '\t'
    f << '.'   << '\t' # ID, don't know what's that though
    λ"""switch(m
        (isa . SNP)       (write f m.ref   '\t' m.alt   '\t')
        (isa . Insertion) (write f '.'     '\t' m.bases '\t')
        (isa . Deletion)  (write f m.bases '\t' '.'     '\t'))
    """
    f << '.' << '\t' # Qual
    f << (isempty(filters) ? "PASS" : join(filters, ';')) << '\t'
    f << info << '\t'
    f << "DP:RD:AD" << '\t'
    f << data[1] << ':' << data[2] << ':' << data[3] << '\n'
end

function write_txt_head(f::IO, info::String, filters::String)

end

function write_txt_line(f::IO, bam::Bam, chr::Int32, m::Mut, info::String, filters::Vector{String}, data::NTuple{3, Int})

end

anno_info(f, var::Variable{Vector})  = :( $f << $(Meta.quot(var.name)) << '='; join($f, $(var.name), ','); $f << ';' )
anno_info(f, var::Variable{Int32})   = :( $f << $(Meta.quot(var.name)) << '=' << $(var.name) << ';' )
anno_info(f, var::Variable{Float32}) = :( $f << $(Meta.quot(var.name)) << '=' << $(var.name) << ';' )
anno_info(f, var::Variable{String})  = :( $f << $(Meta.quot(var.name)) << '=' << $(var.name) << ';' )
anno_info(f, var::Variable{Bool})    = :( ($(var.name) && $f << $(Meta.quot(var.name))); $f << ';' )
