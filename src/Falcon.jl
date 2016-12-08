__precompile__()

module Falcon

using OhMyJulia
using Insane
import Base: start, next, done, iteratorsize, eltype, getindex, show, ==, hash, write

include("mut.jl")
include("read.jl")
include("bam.jl")
include("sam.jl")
include("vcf.jl")
include("cube.jl")
include("bymut.jl")

end
