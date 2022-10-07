# Analyse CrystFEL/indexamajig's profiling information

module ProfileAnalysis

export TimeTree, parsetimetree, loadprofiles, flattentimetree
export averagetimes
using ParserCombinator


struct TimeTree
    name::AbstractString
    time::Real
    children::Vector{TimeTree}
end

TimeTree(name::AbstractString, time::Real) = TimeTree(name, time, [])
TimeTree(l::Vector{Any}) = TimeTree(l[1], l[2], l[3:end])

function Base.show(io::IO, t::TimeTree)
    print(io, "(", t.name, " ", t.time)
    for child in t.children
        print(io, " ", child)
    end
    print(io, ")")
end


# Parser for time tree S-expressions
time_expr = Delayed()
spc = Drop(Star(Space()))
word = p"[a-z,A-Z,0-9,\-]+"
single_time = E"(" + word + spc + PFloat64() + E")" > TimeTree
time_with_children = E"(" + word + spc + PFloat64() +
                     spc + Repeat(spc+time_expr) + E")" |> TimeTree
time_expr.matcher = single_time | time_with_children
parse_time_tree(str::AbstractString) = parse_one(str, time_expr+Eos())[1]


function loadprofiles(filename::String)
    timetrees = TimeTree[]
    open(filename, "r") do fh
        for line in eachline(fh)

            sp = findfirst(' ', line)
            worker = SubString(line, 1, sp)
            lp = parse_time_tree(SubString(line, 1+sp))
            push!(timetrees, lp)

            let n = length(timetrees)
                if n % 1000 == 0
                    println(n, " profiles loaded")
                end
                if n == 5000
                    return timetrees
                end
            end

        end
    end

    timetrees
end


function recursive_flatten(t::Dict, tree::TimeTree)
    total = 0
    for subtree in tree.children
        total += subtree.time
        recursive_flatten(t, subtree)
    end
    t[tree.name] = tree.time - total
end

function flattentimetree(tree::TimeTree)
    t = Dict{String,Float64}()
    recursive_flatten(t, tree)
    t
end


function mapblocks(f, input::Vector{T}, blocksize::Integer) where T
    output = Vector{T}(length(input))
    for blk in 1:blocksize:length(input)
        push!(output, f(view(input, blk:blk+blocksize-1)))
    end
    output
end

function meanblock(blk::Vector{T}) where T
    totals = T()
    n = 0
    for timedict in blk
        for t in keys(timedict)
            totals[t] = timedict[t] + get(totals, t, 0)
        end
        n += 1
    end
    averages = T()
    for t in keys(totals)
        averages[t] = totals[t] / n
    end
    averages
end

function averagetimes(r::Vector{Dict{String,Float64}}, blocksize::Int64)
    mapblocks(meanblock, r, blocksize)
end


function significanttimes(r::Vector{Dict{String,Float64}})
    fd
end


end  # of module
