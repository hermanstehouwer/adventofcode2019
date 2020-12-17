module shuffle
    using Match

    function run(instructions::String, decksize::Int64)

        deck::Array{Int64} = [0:decksize-1;]

        function newstack()
            reverse!(deck)
        end

        function cut(c::Int64)
            if c > 0
                while c > 0
                    t = popfirst!(deck)
                    push!(deck, t)
                    c -= 1
                end
            else
                while c < 0
                    t = pop!(deck)
                    pushfirst!(deck,t)
                    c += 1
                end
            end
        end

        function deal(c::Int64)
            ndeck::Array{Int64} = zeros(length(deck))
            idx = 1
            while length(deck) > 0
                i = popfirst!(deck)
                ndeck[idx] = i
                idx = idx + c
                if idx > length(ndeck)
                    idx -= length(ndeck)
                end
            end
            deck = ndeck
        end

        function execute(instruction::String)
            if instruction == "deal into new stack"
                newstack()
            elseif startswith(instruction, "cut ")
                c = split(instruction, " ")
                cut(parse(Int64, pop!(c)))
            elseif startswith(instruction, "deal with increment ")
                c = split(instruction, " ")
                deal(parse(Int64, pop!(c)))
            end
        end

        for instruction in eachline(instructions)
            execute(instruction)
        end

        if decksize > 100
            for i in 1:length(deck)
                if deck[i] == 2019
                    return i-1
                end
            end
        end
        println(deck)
        return deck
    end

    function run2(filename, pos, l = 10007, repeats = 1)
        instructions::Array{String} = []
        for instruction in eachline(filename)
            push!(instructions, instruction)
        end

        # Find the composition of inverses first
        f = (BigInt(1), BigInt(0)) # f = (a, b) = id

        for instruction in reverse(instructions)
            if instruction == "deal into new stack"
                f = (mod(-f[1], l), mod(-f[2] - 1 + l, l))
            elseif startswith(instruction, "cut ")
                c = split(instruction, " ")
                N = mod(parse(BigInt, pop!(c)), l)
                f = (mod(f[1], l), mod(f[2] + N, l))
            elseif startswith(instruction, "deal with increment ")
                c = split(instruction, " ")
                N = mod(parse(BigInt, pop!(c)), l)
                N = invmod(N, l)
                f = (mod(N * f[1], l), mod(N * f[2], l))
            else
                error("Bad instruction: $instruction")
            end
        end
        # Apply it k times
        ak = powermod(f[1], repeats, l)
        geo = if f[1] != 1 (ak - 1) * invmod(f[1] - 1, l) else repeats end
        return mod(ak * pos + geo * f[2], l)
    end
end

@assert shuffle.run("/Users/herste/Desktop/julia/2019/22/t1.txt",10) == [0,3,6,9,2,5,8,1,4,7]
@assert shuffle.run("/Users/herste/Desktop/julia/2019/22/t2.txt",10) == [3,0,7,4,1,8,5,2,9,6]
@assert shuffle.run("/Users/herste/Desktop/julia/2019/22/t3.txt",10) == [6,3,0,7,4,1,8,5,2,9]
@assert shuffle.run("/Users/herste/Desktop/julia/2019/22/t4.txt",10) == [9,2,5,8,1,4,7,0,3,6]
# shuffle.run("/Users/herste/Desktop/julia/2019/22/input.txt",10007)

# shuffle.run2("/Users/herste/Desktop/julia/2019/22/input.txt",2020,119315717514047,101741582076661)
