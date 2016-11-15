__precompile__()

module Falcon

using OhMyJulia
import Base: start, next, done, getindex

include("read.jl")
include("bam.jl")
include("cube.jl")

end
