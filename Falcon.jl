__precompile__()

module Falcon

using OhMyJulia
using Insane
using StatsBase
using HypothesisTests
using Libz
using JsonBuilder
using BioDataStructures
import Base: start, next, done, iteratorsize, eltype,
             getindex, setindex!, show, ==, hash, write

include("core/mut.jl")
include("core/read.jl")
include("core/bam.jl")
include("core/sam.jl")
include("core/pair.jl")
include("core/vcf.jl")
include("core/pileup.jl")

include("ui/stat.jl")

include("caller/rule.jl")
include("caller/driver.jl")

end # module
