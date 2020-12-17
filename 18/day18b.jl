module vault

    mutable struct relation
        to::Char
        len::Int64
    end

    mutable struct node
        label::Char
        relations::Array{relation}
    end

    function run(program::String)::Int64
        #tovisit: x,y (target), input to give, processorstate
        start::Tuple{Int64,Int64} = (0,0)
        vault::Array{String} = []
        letters::String = ""

        x::Int64 = 1
        for line in eachline(program)
            y::Int64 = 1
            l::String = ""
            for i in line
                if i == '@'
                    println("FOUND")
                    start = (x,y)
                    i = "."
                end
                if isletter(i[1])
                    if ! (lowercase(i[1]) in letters)
                        letters = string(letters,lowercase(i[1]))
                    end
                end
                l = string(l, i)
                y += 1
            end
            push!(vault,l)
            x += 1
        end
        println("Start: $start letters: $letters")
        for l in vault
            println(l)
        end
        println()



end

@assert vault.run("/Users/herste/Desktop/julia/2019/18/t1.txt") == 8
@assert vault.run("/Users/herste/Desktop/julia/2019/18/t2.txt") == 86
@assert vault.run("/Users/herste/Desktop/julia/2019/18/t3.txt") == 132
@assert vault.run("/Users/herste/Desktop/julia/2019/18/t4.txt") == 136
@assert vault.run("/Users/herste/Desktop/julia/2019/18/t5.txt") == 81

#vault.run("/Users/herste/Desktop/julia/2019/18/input.txt")
