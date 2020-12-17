using BenchmarkTools
using Match

function Day5(input::Array{Int64,1})

    memory::Array{Int64} = []
    idx::Int64 = 1
    running = true

    function parseAndAdd(s::String)
        for i in split(s,",")
            push!(memory, parse(Int64, i))
        end
    end

    # halt
    function op99(op)
        running = false
    end

    # add
    function op1(op::Tuple{Int64,Int64,Int64,Int64})
        a = getval(idx+1,op[2])
        b = getval(idx+2,op[3])
        address = getloc(idx+3,op[4])
        memory[address] = a + b
        idx += 4
    end

    # mult
    function op2(op::Tuple{Int64,Int64,Int64,Int64})
        a = getval(idx+1,op[2])
        b = getval(idx+2,op[3])
        address = getloc(idx+3,op[4])
        memory[address] = a * b
        idx += 4
    end

    #input
    function op3(op::Tuple{Int64,Int64,Int64,Int64})
        address = getloc(idx+1,op[2])
        memory[address] = popfirst!(input)
        idx += 2
    end

    #output
    function op4(op::Tuple{Int64,Int64,Int64,Int64})
        a = getval(idx+1,op[2])
        println(a)
        idx += 2
    end

    #jit
    function op5(op::Tuple{Int64,Int64,Int64,Int64})
        a = getval(idx+1,op[2])
        b = getval(idx+2,op[3])
        if a != 0
            idx = b+1
        else
            idx+=3
        end
    end

    #jif
    function op6(op::Tuple{Int64,Int64,Int64,Int64})
        a = getval(idx+1,op[2])
        b = getval(idx+2,op[3])
        if a == 0
            idx = b+1
        else
            idx += 3
        end
    end

    #lt
    function op7(op::Tuple{Int64,Int64,Int64,Int64})
        a = getval(idx+1,op[2])
        b = getval(idx+2,op[3])
        address = getloc(idx+3,op[4])
        if a < b
            memory[address] = 1
        else
            memory[address] = 0
        end
        idx += 4
    end

    #eq
    function op8(op::Tuple{Int64,Int64,Int64,Int64})
        a = getval(idx+1,op[2])
        b = getval(idx+2,op[3])
        address = getloc(idx+3,op[4])
        if a == b
            memory[address] = 1
        else
            memory[address] = 0
        end
        idx += 4
    end

    function noop()
        error = true
        running = false
    end

    function splitopcode(opcode::Int64)
        op::Int64 = opcode % 100
        a::Int64 = opcode % 1000 - op
        b::Int64 = opcode % 10000 - (a + op)
        c::Int64 = opcode - (a + b + op)
        return (op,a,b,c)
    end

    function getval(pos,mode)
        if mode == 0
            return memory[memory[pos]+1]
        end
        return memory[pos]
    end

    function getloc(pos,mode)
        if mode == 0
            return memory[pos]+1
        end
        return pos+1
    end

    function execute()
        op = splitopcode(memory[idx])
        @match op[1] begin
            99 => op99(op)
            1  => op1(op)
            2  => op2(op)
            3  => op3(op)
            4  => op4(op)
            5  => op5(op)
            6  => op6(op)
            7  => op7(op)
            8  => op8(op)
            _  => noop()
        end
    end

    for line in eachline("/Users/herste/Desktop/julia/2019/5/input.txt")
        parseAndAdd(line)
    end

    while running
        execute()
    end

    return
end

@time Day5([1])

@time Day5([5])
