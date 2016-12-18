immutable Variable{T}
    name::Symbol
    desc::String
    deps::Vector{Symbol}
    func::Expr
end

immutable Filter
    desc::String
    deps::Vector{Symbol}
    func::Expr
end

immutable Rule
    name::String
    bymut::Bool # read or mut
    soft::Bool  # hard or soft
    desc::String
    var::Vector{Variable}
    filt::Vector{Filter}
    stat::Vector{Symbol}
    anno::Vector{Symbol}
end

vartype{T}(::Variable{T}) = T

function load_rule_file(filename)
    λ"""
    l(code (parse (* "module X\n" (open readstring filename) "\nend")))
    return*(=(rules ref(Rule)))
    local(rule)
    ∀(line ∈ (getfield ref(code.args 3) :args))
    switch(line.head
      *:line $(continue)
      *:macrocall >(
        l('(doc def) ?((isa ref(line.args 1) GlobalRef)
                     '(ref(line.args 2) (getfield ref(line.args 3) :args))
                     '("" line.args)))
        switch((car def)
          *(Symbol "@rule") (push! rules =(rule (Rule ref(def 2) (== ref(def 3) :bymut) (== ref(def 4) :soft)
                                                      doc ref(Variable) ref(Filter) ref(Symbol) ref(Symbol))))
          *(Symbol "@var") (push! rule.var (Variable{(eval (cadr (getfield (cadr def) :args)))}
                                 (car (getfield (cadr def) :args)) doc
                                 switch((car (getfield ref(def 3) :args))
                                   (isa . Symbol) ref(Symbol .)
                                   (isa . Expr) (collect ..args))
                                 (cadr (getfield ref(def 3) :args))))
          *(Symbol "@filt") (push! rule.filt (Filter doc
                                   switch((car (getfield (cadr def) :args))
                                     (isa . Symbol) ref(Symbol .)
                                     (isa . Expr) (collect ..args))
                                   (cadr (getfield (cadr def) :args))))
          *(Symbol "@stat") (push! rule.stat (cadr def))
          *(Symbol "@anno") (push! rule.anno (cadr def)))))
    """
end

function gen_var_factory(f, vars)
    new = Set(keys(vars))
    gen_var(v) = if v in new
        foreach(gen_var, vars[v].deps)
        push!(f, :(
            $v = $(reduce((x,y)->Expr(:||, :($y == nothing), x), false, vars[v].deps)) ? nothing : $(vars[v].func)
        ))
        delete!(new, v)
    end
end

function build_rule_func(bymut, rules, writeline, plotstat=nothing)
    f = []
    vars = Dict(v.name => v for r in rules for v in r.var)
    gen_var = gen_var_factory(f, vars)

    for rule in rules
        p = nothing
        for filt in rule.filt
            foreach(gen_var, filt.deps)
            p = :(
                !$(reduce((x,y)->Expr(:||, :($y == nothing), x), false, filt.deps)) && !$(filt.func) ?
                    $(rule.soft ? bymut ? :( push!(filters, $(rule.name)) ) : :( pass=false ) :
                                 :(continue)) : $p
            )
        end
        push!(f, p)

        plotstat != nothing && for stat in rule.stat
            push!(f, :( $stat != nothing && push!($(Symbol("stat_", stat)), $stat) ))
        end

        for anno in rule.anno
            push!(f, :( $anno != nothing && $( bymut ? anno_info(:info, vars[anno]) :
                                                     :(read[$(Meta.quot(anno))] = $anno) ) ))
        end
    end

    f = bymut ? quote function(x)
        $((plotstat != nothing ? (:( $(Symbol("stat_", s)) = $(vartype(vars[s]))[] ) for r in rules for s in r.stat) : ())...)
        for (reads, chr, mut) in x
            info = IOBuffer()
            filters = String[]
            $(f...)
            $writeline(reads, chr, mut, String(info.data[1:end-1]), filters)
        end
        $((plotstat != nothing ? (:( $plotstat($(vars[s]), $(Symbol("stat_", s))) ) for r in rules for s in r.stat) : ())...)
    end end : quote function(x)
        $((plotstat != nothing ? (:( $(Symbol("stat_", s)) = $(vartype(vars[s]))[] ) for r in rules for s in r.stat) : ())...)
        for read in x
            pass = true
            $(f...)
            $writeline(read, pass)
        end
        $((plotstat != nothing ? (:( $plotstat($(vars[s]), $(Symbol("stat_", s))) ) for r in rules for s in r.stat) : ())...)
    end end

    eval(Main, f)
end
