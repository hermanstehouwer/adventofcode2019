module intcode
    using Match
    using Combinatorics

    function runprogram(program::String,input::Array{Int64,1})
        memory::Array{Int64,1} = []
        idx::Int64 = 1
        running::Bool = true
        print::Bool = true
        base::Int64 = 1
        output::Array{Int64,1} = []

        function parseAndAdd(s::String)
            for i in split(s,",")
                push!(memory, parse(Int64, i))
            end
        end

        function acheck(address::Int64)
            l = length(memory)
            if address > length(memory)
                resize!(memory,address)
                #for x in l+1:address
                #    memory[x] = 0
                #end
            end
        end

        # halt
        function op99(op::Tuple{Int64,Int64,Int64,Int64})
            running = false
        end

        # add
        function op1(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(idx+1,op[2])
            b = getval(idx+2,op[3])
            address = getloc(idx+3,op[4])
            acheck(address)
            memory[address] = a + b
            idx += 4
        end

        # mult
        function op2(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(idx+1,op[2])
            b = getval(idx+2,op[3])
            address = getloc(idx+3,op[4])
            acheck(address)
            memory[address] = a * b
            idx += 4
        end

        #input
        function op3(op::Tuple{Int64,Int64,Int64,Int64})
            address = getloc(idx+1,op[2])
            acheck(address)
            memory[address] = pop!(input)
            idx += 2
        end

        #output
        function op4(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(idx+1,op[2])
            push!(output,a)
            #println("Output: $a")
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
            acheck(address)
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
            acheck(address)
            if a == b
                memory[address] = 1
            else
                memory[address] = 0
            end
            idx += 4
        end

        #adjust relative base
        function op9(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(idx+1,op[2])
            #println("9: modifying $base with $a")
            base += a
            idx += 2
        end

        function noop()
            error = true
            running = false
        end

        function splitopcode(opcode::Int64)
            op::Int64 = opcode % 100
            a::Int64 = (opcode % 1000 - op)
            b::Int64 = (opcode % 10000 - (a + op))
            c::Int64 = (opcode - (a + b + op))
            a /= 100
            b /= 1000
            c /= 10000
            return (op,a,b,c)
        end

        function getval(pos::Int64,mode::Int64)
            rpos = pos
            if mode == 0
                rpos = memory[pos]+1
            end
            if mode == 2
                #println("Accessing in M2: $(base+memory[pos])  ( $base $(memory[pos]) )")
                rpos = base + memory[pos]
            end
            acheck(rpos)
            return memory[rpos]
        end

        function getloc(pos::Int64,mode::Int64)
            if mode == 0
                return memory[pos]+1
            end
            if mode == 2
                #println("loc in M2: $(base+pos)")
                return base + memory[pos]
            end
            return pos+1
        end

        function execute()
            op = splitopcode(memory[idx])
            #println("Processing OP: $op")
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
                9  => op9(op)
                _  => noop()
            end
        end

        for line in eachline(program)
            parseAndAdd(line)
        end

        while running
            execute()
        end
        return output
    end
end

#Day5,part2:   intcode.runprogram("/Users/herste/Desktop/julia/2019/5/input.txt",[5])
#println("Testing if still valid with day 5 input")
#@assert  intcode.runprogram("/Users/herste/Desktop/julia/2019/5/input.txt",[5]) == 9436229

println("Testing using the part1 tests")
#TEST, should give 109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99:
#intcode.runprogram("/Users/herste/Desktop/julia/2019/9/t1.txt",[5])
#intcode.runprogram("/Users/herste/Desktop/julia/2019/9/t2.txt",[5])
intcode.runprogram("/Users/herste/Desktop/julia/2019/9/t3.txt",[5])
