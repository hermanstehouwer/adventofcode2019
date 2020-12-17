using BenchmarkTools
using Match

mutable struct wire
    instructions::Array{Tuple{Char,Int64}}
end

function Day3(file::String, fd::Bool)::Int64
    wires::Array{wire} = []
    paths::Array{Array{Tuple{Int64,Int64}}} = []
    crossings::Array{Tuple{Int64,Int64}} = []
    counts::Dict{Tuple{Int64,Int64},Int64} = Dict{Tuple{Int64,Int64},Int64}()

    function manhattan(x1::Int64,y1::Int64,x2::Int64,y2::Int64)::Int64
        a = abs(x2 - x1)
        b = abs(y2 - y1)
        #println("CALCULATING FROM $x1,$y1 to $x2,$y2 for value $(a+b)")
        return a+b
    end

    function findmhc(crossings::Array{Tuple{Int64,Int64}})::Int64
        min::Int64 = 999999999
        for crossing in crossings
            if abs(crossing[1]) + abs(crossing[2]) < min
                min = abs(crossing[1]) + abs(crossing[2])
            end
        end
        return min
    end

    function finddistance(crossings)
        min = 999999999999
        for crossing in crossings
            if counts[crossing] < min
                min = counts[crossing]
            end
        end
        return min
    end

    function parseAndAdd(s::String)::wire
        w::wire = wire([])
        for i in split(s,",")
            push!(w.instructions, (i[1], parse(Int64, i[2:length(i)])))
        end
        return w
    end

    function runwire(w::wire)::Array{Tuple{Int64,Int64}}
        x = 0
        y = 0
        wirelength=0
        ret::Array{Tuple{Int64,Int64}} = []
        for i in w.instructions
            direction::Char = i[1]
            for c in 1:i[2]
                @match direction begin
                    'U' => (y += 1)
                    'D' => (y -= 1)
                    'L' => (x -= 1)
                    'R' => (x += 1)
                end
                wirelength += 1
                push!(ret,(x,y))
                counts[(x,y)] = get(counts, (x,y), 0) + wirelength
            end
        end
        return ret
    end

    function runwires()
        for w in wires
            push!(paths,runwire(w))
        end
    end

    for line in eachline(file)
        push!(wires,parseAndAdd(line))
    end

    runwires()

    crossings = intersect(paths[1],paths[2])

    if fd
        return finddistance(crossings)
    end

    return findmhc(crossings)
end

#1,8 offset
@assert Day3("/Users/herste/Desktop/julia/2019/3/test0",false) == 6

@assert Day3("/Users/herste/Desktop/julia/2019/3/test2",false) == 135

@assert Day3("/Users/herste/Desktop/julia/2019/3/test1",false) == 159

println( @time Day3("/Users/herste/Desktop/julia/2019/3/input.txt",false))

@assert Day3("/Users/herste/Desktop/julia/2019/3/test0",true) == 30

@assert Day3("/Users/herste/Desktop/julia/2019/3/test1",true) == 610

@assert Day3("/Users/herste/Desktop/julia/2019/3/test2",true) == 410

println( @time Day3("/Users/herste/Desktop/julia/2019/3/input.txt",true))
