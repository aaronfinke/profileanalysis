# Analyse CrystFEL/indexamajig's profiling information
module ProfileAnalysis

using DataStructures
using Plots
using RecipesBase

export loadprofiles, ProfileTimes, plottimes
export averagetimes, significanttimes, allkeys


ProfileTimes = OrderedDict{String,Float64}

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


function plottimes(times::AbstractVector{ProfileTimes})
    keys = allkeys(times)
    data = Matrix{Float64}(undef, length(times), length(keys))
    for (j, key) in enumerate(keys)
        for (i, profile) in enumerate(times)
            data[i,j] = get(profile, key, 0.0)
        end
    end
    areaplot(data,
             labels=reshape([k for k in keys], (1,:)),
             legend=:outerright,
             ylabel="Time / s",
             xlabel="Frame number")
end


end  # of module
