export write_vcf_head, write_vcf_line, write_txt_head, write_txt_line

immutable Variable{T}
    name::Symbol
    desc::String
    deps::Vector{Symbol}
    func::Expr
end

function write_vcf_head(f::IO, rules)
    vars = Dict(v.name => v for r in rules for v in r.var)
    info = join(info_head(vars[anno]) for r in rules for anno in r.anno)
    filters = join(filter_head(r) for r in rules if r.soft && !isempty(r.filt))

    f << """
    ##fileformat=VCFv4.2
    ##fileDate=$(Dates.format(now(), "yyyymmdd"))
    ##source=FalconV0.0.1
    """ << info << filters << """
    ##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
    ##FORMAT=<ID=RD,Number=1,Type=Integer,Description="Depth of reference-supporting bases">
    ##FORMAT=<ID=AD,Number=1,Type=Integer,Description="Depth of variant-supporting bases">
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

anno_info{T}(f, var::Variable{Vector{T}})         = :( $f << $(Meta.quot(var.name)) << '='; join($f, $(var.name), ','); $f << ';' )
anno_info{T<:Integer}(f, var::Variable{T})        = :( $f << $(Meta.quot(var.name)) << '=' << $(var.name) << ';' )
anno_info{T<:AbstractFloat}(f, var::Variable{T})  = :( $f << $(Meta.quot(var.name)) << '=' << $(var.name) << ';' )
anno_info{T<:AbstractString}(f, var::Variable{T}) = :( $f << $(Meta.quot(var.name)) << '=' << $(var.name) << ';' )
anno_info(f, var::Variable{Bool})                 = :( ($(var.name) && $f << $(Meta.quot(var.name))); $f << ';' )

_info_head(var, n, t) = "##INFO=<ID=$(var.name),Number=$n,Type=$t,Description=\"$(var.desc)\">\n"
info_head{T<:Integer}(var::Variable{Vector{T}})        = _info_head(var, 'A', "Integer")
info_head{T<:AbstractFloat}(var::Variable{Vector{T}})  = _info_head(var, 'A', "Float")
info_head{T<:AbstractString}(var::Variable{Vector{T}}) = _info_head(var, 'A', "String")
info_head{T<:Integer}(var::Variable{T})                = _info_head(var,   1, "Integer")
info_head{T<:AbstractFloat}(var::Variable{T})          = _info_head(var,   1, "Float")
info_head{T<:AbstractString}(var::Variable{T})         = _info_head(var,   1, "String")
info_head(var::Variable{Bool})                         = _info_head(var,   0, "Flag")

filter_head(rule) = "##Filter=<ID=$(rule.name),Description=\"$(rule.desc)\">\n"
