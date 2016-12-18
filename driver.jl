function _plot_stat(dir)
    dir == nothing ? nothing : function(var, data)
        open(joinpath(dir, string(var.name, ".html")), "w") do f
            plot_stat(f, var, data)
        end
    end
end

function filter_reads(rules, reads, statdir=nothing)
    out = Read[]
    build_rule_func(false, rules, function(read, pass)
        if !pass
            read.flag |= 0x0200
        end
        push!(out, read)
    end, _plot_stat(statdir))(reads)
    out
end

function filter_muts(f, rules, bam, reads, statdir=nothing)
    build_rule_func(true, rules, function(reads, chr, mut, info, filters)
        dp = length(reads)
        ad = count(reads) do r
            map_to_read(mut, r) in r.muts
        end
        rd = dp - ad
        write_vcf_line(f, bam, chr, mut, info, filters, (dp, rd, ad))
    end, _plot_stat(statdir))(@task pileup(reads))
end
