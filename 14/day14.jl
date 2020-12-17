module mining

    mutable struct reaction
        output::Tuple{String,Int64}
        input::Array{Tuple{String,Int64},1}
    end

    function run(program::String,numfuel::Int64)::Int64
        ore::Int64 = 0
        reactions::Dict{String,reaction} = Dict{String,reaction}()


        function parseLine(s::String)
            in, out = split(s," => ")
            input::Array{Tuple{String,Int64},1} = []
            for i in split(in, ", ")
                c, r = split(i, " ")
                push!(input, (r,parse(Int64,c)))
            end
            c, r = split(out, " ")
            output = (r,parse(Int64,c))
            reactions[r] = reaction(output,input)
        end

        for line in eachline(program)
            parseLine(line)
        end

        leftover::Dict{String,Int64} = Dict{String,Int64}()
        # Produce at least X of out (maybe more)
        # Stops recursing on "ORE"
        function produce(out::String, num::Int64)
            if num <= get(leftover, out, 0)
                leftover[out] = get(leftover, out, 0) - num
                return
            end
            num = num - get(leftover, out, 0)
            leftover[out] = 0
            r = reactions[out]
            factor::Int64 = ceil( num / r.output[2] )
            left = (r.output[2]*factor) - num
            leftover[out] = left
            for to_p in r.input
                if to_p[1] == "ORE"
                    #println("USING $(to_p[2]*factor) ORE")
                    ore += to_p[2]*factor
                else
                    #println("Trying to produce $(to_p[2]*factor) $(to_p[1])")
                    produce(to_p[1],to_p[2]*factor)
                end
            end
        end

        produce("FUEL", numfuel)

        return ore
    end

    # 1672134
    function part2(program::String)::Int64
        start::Int64 = 1
        factors = 1000000, 500000, 100000, 50000,10000,5000,1000,500,100,50,10,1
        for f in factors
            while run(program,start) < 1000000000000
                start += f
            end
            start -= f
        end
        return start
    end
end

#intcode.run("/Users/herste/Desktop/julia/2019/11/input.txt")
# t1: 31
@assert mining.run("/Users/herste/Desktop/julia/2019/14/t1.txt",1) == 31
# t2: 165
@assert mining.run("/Users/herste/Desktop/julia/2019/14/t2.txt",1) == 165
# t3: 13312
@assert mining.run("/Users/herste/Desktop/julia/2019/14/t3.txt",1) == 13312
# t4: 180697
@assert mining.run("/Users/herste/Desktop/julia/2019/14/t4.txt",1) == 180697
# t5: 2210736
@assert mining.run("/Users/herste/Desktop/julia/2019/14/t5.txt",1) == 2210736

println("Part1: $(mining.run("/Users/herste/Desktop/julia/2019/14/input.txt",1))")
println("Part2: $(mining.part2("/Users/herste/Desktop/julia/2019/14/input.txt"))")
