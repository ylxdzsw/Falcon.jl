function filter_reads(rules, reads)
    out = Read[]
    build_stat(false, rules, function(read, pass)
        if !pass
            read.flag |= 0x0200
        end
        push!(out, read)
    end)(reads)
    out
end

function filter_muts(f, rules, bam, reads)
    build_stat(true, rules, function(reads, chr, mut, info, filters)
        dp = length(reads)
        ad = count(reads) do r
            map_to_read(mut, r) in r.muts
        end
        rd = dp - ad
        write_vcf_line(f, bam, chr, mut, info, filters, (dp, ad, rd))
    end)(@task pileup(reads))
end
