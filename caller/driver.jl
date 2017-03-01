export filter_reads, filter_muts

function _plot_stat(dir)
    dir == nothing ? nothing : function(args...)
        open(joinpath(dir, string(join(map(x->x.name, args[1:length(args)÷2]), '_'), ".html")), "w") do f
            plot_stat(f, args...)
        end
    end
end

function filter_reads(rules, reads; statdir=nothing, debug=false)
    out = Read[]
    build_rule_func(false, rules, function(read, pass)
        if !pass
            read.flag |= 0x0200
        end
        push!(out, read)
    end, _plot_stat(statdir), debug=debug)(reads)
    out
end

function filter_muts(f, rules, bam, reads; statdir=nothing, debug=false)
    build_rule_func(true, rules, function(reads, chr, mut, info, filters)
        dp = length(reads)
        ad = count(reads) do r
            map_to_read(mut, r) in r.muts
        end
        rd = dp - ad
        write_vcf_line(f, bam, chr, mut, info, filters, (dp, rd, ad))
    end, _plot_stat(statdir), debug=debug)(@task pileup(reads))
end
