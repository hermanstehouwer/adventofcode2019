function day1part1()
    total::Int64 = 0

    function parseAndAdd(s::String)
        toadd::Int64 = parse(Int64,s)
        total += toadd
    end

    for line in eachline("/Users/herste/Desktop/julia/2018/1/input1.txt")
        parseAndAdd(line)
    end
    return total
end

function day1part2()
    current::Int64 = 0
    input::Vector{Int64} = []
    check::Dict{Int64,Bool} = Dict(current=>true)

    for line in eachline("/Users/herste/Desktop/julia/2018/1/input1.txt")
        push!(input, parse(Int64,line))
    end

    while true
        for i in input
            current += i
            if haskey(check, current)
                return current
            end
            check[current] = true
        end
    end
end

println( @time day1part1())
println( @time day1part2())
