__precompile__()

module Falcon

using OhMyJulia
using Insane
# using StatsBase
# using HypothesisTests
using Libz
using JsonBuilder
import Base: start, next, done, iteratorsize, eltype,
             getindex, setindex!, show, ==, hash, write

include("mut.jl")
include("read.jl")
include("bam.jl")
include("sam.jl")
include("pair.jl")
include("rule.jl")
include("vcf.jl")
include("stat.jl")
include("pileup.jl")
include("driver.jl")

end # module
