function writeall(bam, filename)
    open_vcf(filename, bam) do f
        for (reads, chr, mut) in @task pileup(bam)
            dp = length(reads)
            ad = count(reads) do r
                relpos = calc_read_pos(r, mut.pos) |> car
                Mut(mut, relpos) in r.muts
            end
            rd = dp - ad
            data = Dict{String, Any}("DP" => dp, "RD" => rd, "AD" => ad)
            write(f, Int32(chr), mut, data)
        end
    end
end
