__precompile__()

module Falcon

using OhMyJulia
using Insane
using StatsBase
using HypothesisTests
using BufferedStreams
using Libz
using JsonBuilder
using BioDataStructures
import Base: start, next, done, iteratorsize, eltype, view,
             getindex, setindex!, show, ==, hash, write

include("core/mut.jl")
include("core/read.jl")
include("core/bam.jl")
include("core/sam.jl")

include("index/pair.jl")
include("index/pileup.jl")
include("index/index.jl")

include("cover/bed.jl")
include("cover/cover.jl")

include("ui/stat.jl")

include("caller/rule.jl")
include("caller/driver.jl")
include("caller/vcf.jl")

include("bamqc/cover.jl")
end # module
