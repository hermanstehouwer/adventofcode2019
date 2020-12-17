using BenchmarkTools

function Day2(noun::Int64, verb::Int64)

    memory::Array{Int64} = []
    idx::Int64 = 1
    running = true

    function parseAndAdd(s::String)
        for i in split(s,",")
            push!(memory, parse(Int64, i))
        end
    end

    function execute()
        opcode::Int64 = memory[idx]
        if opcode == 99
            running = false
            return
        elseif opcode == 1
            memory[memory[idx+3]+1] = memory[memory[idx+1]+1] + memory[memory[idx+2]+1]
        elseif opcode == 2
            memory[memory[idx+3]+1] = memory[memory[idx+1]+1] * memory[memory[idx+2]+1]
        else
            error = true
            running = false
            return
        end
        idx = (idx+4)
    end


    for line in eachline("/Users/herste/Desktop/julia/2019/2/input.txt")
        parseAndAdd(line)
    end

    memory[2] = noun
    memory[3] = verb

    while running
        execute()
    end

    return memory[1]
end

function Day22()
    for x in 0:99
        for y in 0:99
            if Day2(x,y) == 19690720
                return 100*x+y
            end
        end
    end
end

println( @time Day2(12,2))

println( @time Day22())
