__precompile__()

module Falcon

using OhMyJulia
using Insane
import Base: start, next, done, iteratorsize, eltype, getindex, show, ==, hash

include("mut.jl")
include("read.jl")
include("bam.jl")
include("sam.jl")
include("cube.jl")

end
