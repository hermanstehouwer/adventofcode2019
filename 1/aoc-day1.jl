using BenchmarkTools

function Day1(calcFuel::Bool)
    total::Int64 = 0

    function fuel(start::Int64)
        start = floor(Int64, (start/3))
        start -= 2
        return start
    end

    function parseAndAdd(s::String)
        toadd::Int64 = fuel(parse(Int64,s))
        total += toadd
        while calcFuel
            toadd = fuel(toadd)
            if toadd > 0
                total += toadd
            else
                return
            end
        end

    end

    total = 0

    for line in eachline("/Users/herste/Desktop/julia/2019/1/input.txt")
        parseAndAdd(line)
    end
    return total
end

println( @time Day1(false))
println( @time Day1(true))

@benchmark Day1(true)
print(BenchmarkTools.Trial)
