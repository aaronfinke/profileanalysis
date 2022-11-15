# Analyse CrystFEL/indexamajig's profiling information
module ProfileAnalysis

using DataStructures
using Plots

export loadprofiles, loadworkerprofiles, ProfileTimes, plottimes
export averagetimes, significanttimes, allkeys


struct ProfileTimes <: AbstractDict{String,Float64}
   times::OrderedDict{String,Float64}
end
ProfileTimes() = ProfileTimes(OrderedDict{String,Float64}())
Base.getindex(a::ProfileTimes, b) = Base.getindex(a.times, b)
Base.get(a::ProfileTimes, b, c) = Base.get(a.times, b, c)
Base.sort(a::ProfileTimes; args...) = ProfileTimes(Base.sort(a.times; args...))
Base.setindex!(a::ProfileTimes, b, c) = ProfileTimes(Base.setindex!(a.times, b, c))
Base.keys(a::ProfileTimes) = Base.keys(a.times)
Base.iterate(a::ProfileTimes) = Base.iterate(a.times)
Base.iterate(a::ProfileTimes, b) = Base.iterate(a.times, b)
Base.length(a::ProfileTimes) = Base.length(a.times)


include("timetree.jl")


function mapblocks(f, input::Vector{T}, blocksize::Integer) where T
    output = Vector{T}()
    for blk in blocksize:blocksize:length(input)
        push!(output, f(view(input, blk-blocksize+1:blk)))
    end
    output
end


function meanofblock(blk::AbstractVector{T}) where T
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


"""
    averagetimes(times, blocksize)

Average `times` (a vector of ProfileTimes objects) in blocks of `blocksize`.

If `length(times)` is not a multiple of `blocksize`, the remaining ProfileTimes
will be discarded.
"""
function averagetimes(flattenedtimes::AbstractVector, blocksize)
    mapblocks(meanofblock, flattenedtimes, blocksize)
end


function significanttimes(times, nsig=10)
    sorted = sort(times, byvalue=true, rev=true, alg=PartialQuickSort(nsig))
    rval = ProfileTimes()
    n = 1
    other = 0
    for w in sorted
        if n <= nsig
            push!(rval, w)
        else
            other += w.second
        end
        n += 1
    end
    push!(rval, "other" => other)
end


function allkeys(vec::Vector{V}) where V <: AbstractDict{T, U} where {T, U}
    allkeys = OrderedSet{T}()
    for i in vec
        for k in keys(i)
            push!(allkeys, k)
        end
    end
    allkeys
end


pinned_keys = ["other",

               "asapo-get-next",
               "asapo-fetch",
               "read-asapo-data",
               "zmq-fetch",
               "read-zmq-data",
               "seedee-deserialize",
               "seedee-panel",

               "malloc-copy",
               "H5Dread",
               "load-image-data",
               "load-masks",
               "flag-values",

               "peak-search",
               "pf8-mask",
               "pf8-rstats",
               "pf8-search",

               "process-image",
               "asdf-search",
               "asdf-findcell",
               "prerefine-cell-check"]

pinned_colours = distinguishable_colors(30)[1:length(pinned_keys)]
colourkey = Dict(pinned_keys .=> pinned_colours)

function plottimes(t::AbstractVector{ProfileTimes}, blocksize=100)
    times = map(significanttimes, averagetimes(t, blocksize))
    keys = allkeys(times)
    data = Matrix{Float64}(undef, length(times), length(keys))
    colours = Matrix{Colors.Colorant}(undef, 1, length(keys))
    labels = Matrix{String}(undef, 1, length(keys))
    for (j, key) in enumerate(keys)
        for (i, profile) in enumerate(times)
            data[i,j] = get(profile, key, 0.0)
        end
        labels[j] = key
        colours[j] = get(colourkey, key, RGB(0,0,0))
        if key != "other" && colours[j] == RGB(0,0,0)
            println("WARNING: No colour for ", key)
        end
    end
    areaplot(blocksize:blocksize:(1+length(times))*blocksize-1,
             data,
             labels=labels,
             seriescolor=colours,
             legend=:outerright,
             ylabel="Time / s",
             xlabel="Frame number",
             linewidth=0)
end


end  # of module
