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


function recursive_flatten(t, tree::TimeTree)
    total = 0
    for subtree in tree.children
        total += subtree.time
        recursive_flatten(t, subtree)
    end
    t[tree.name] = tree.time - total
end

function flatten(tree::TimeTree)
    t = ProfileTimes()
    recursive_flatten(t, tree)
    t
end


function readprofiles(filename)
    Channel() do ch
        open(filename, "r") do fh
            for line in eachline(fh)
                sp = findfirst(' ', line)
                worker = parse(Int, SubString(line, 1, sp))
                lp = parse_time_tree(SubString(line, 1+sp))
                put!(ch, (worker,flatten(lp)))
            end
        end
    end
end


"""
    loadprofiles(filename[, nmax][, worker=n])

Load profiling information in indexamajig S-expression time tree format.

If `nmax` is unspecified, load the entire file.  Otherwise, return up to `nmax`
profiles.

If `worker` is specified, returns information only for the given worker process.
Otherwise, returns everything, in the order it appears in the file.
"""
function loadprofiles(filename, nmax=nothing; worker=nothing)
    profiles = ProfileTimes[]
    ch = readprofiles(filename)
    nloaded = 0
    for (nw,profile) in ch
        if isnothing(worker) || (nw == worker)
            push!(profiles, profile)
            nloaded += 1
            if nloaded % 1000 == 0
                println(nloaded, " profiles loaded")
            end
            if nloaded == nmax
                return profiles
            end
        end
    end
    return profiles
end

    timetrees
end
