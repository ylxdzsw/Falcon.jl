function writeall(bam, filename; mindp=0, minad=0)
    open_vcf(filename, bam) do f
        for (reads, chr, mut) in @task pileup(bam)
            dp = length(reads)
            ad = count(reads) do r
                map_to_read(mut, r) in r.muts
            end
            (dp < mindp || ad < minad) && continue
            rd = dp - ad
            write(f, Int32(chr), mut, "", (dp, rd, ad))
        end
    end
end

function filter_reads(rules, reads)
    out = Read[]
    build_stat(false, rules, identity, function(read, pass)
        if !pass
            read.flag |= 0x0200
        end
        push!(out, read)
    end)(reads)
    out
end

function filter_muts(bam, filename)

end
