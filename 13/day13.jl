module intcode
    using Match
    using Combinatorics

    function runprogram(program::String)
        memory::Array{Int64,1} = []
        idx::Int64 = 1
        running::Bool = true
        print::Bool = true
        base::Int64 = 1
        output::Array{Int64,1} = []
        input::Array{Int64,1} = []
        outputbuff::Array{Int64,1} = []
        ballpos::Array{Int64,1} = [0,0,0]
        paddlepos::Array{Int64,1} = [0,0,0]
        score::Int64 = 0

        ### BOT
        function domove()
            # -1, 0, score
            if outputbuff[1] == -1 && outputbuff[2] == 0
                score = outputbuff[3]
                println("Found new score $score")
            else
                # 4 ball
                if outputbuff[3] == 4
                    ballpos = copy(outputbuff)
                    # 3 paddle
                elseif outputbuff[3] == 3
                    paddlepos = copy(outputbuff)
                end
            end
            outputbuff = []
        end


        ### BOT
        function getinput()
            if length(input) == 0
                if paddlepos[1] > ballpos[1]
                    push!(input, -1)
                elseif paddlepos[1] < ballpos[1]
                    push!(input, 1)
                else
                    push!(input, 0)
                end
            end
        end
        ### / BOT

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
            println("HALT")
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
            getinput()
            memory[address] = pop!(input)
            idx += 2
        end

        #output
        function op4(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(idx+1,op[2])
            push!(output,a)
            push!(outputbuff,a)
            if length(outputbuff) == 3
                domove()
            end
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
            println("ERRRRRR")
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

        memory[1] = 2

        while running
            execute()
        end
        return score
    end
end
