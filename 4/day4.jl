using BenchmarkTools
using StatsBase

function Day4(from::Int64, to::Int64)
    counter::Int64 = 0

    function checkadj(in::Int64)::Bool
        s::String = string(in)
        c::Dict{Char,Int64} = countmap([c for c in s])
        for v in values(c)
            if v >= 2
                return true
            end
        end
        return false
    end

    function checkincr(in::Int64)::Bool
        s::String = string(in)
        sorted::String = join(sort(collect(s)))
        return s == sorted
    end

    for i in from:to
        if checkadj(i) && checkincr(i)
            counter+=1
        end
    end
    return counter
end

println( @time Day4(245555,700000))
