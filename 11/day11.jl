module intcode
    using Match
#    using Combinatorics

    function runprogramChannels(program::String,input::Array{Int64},output::Array{Int64},syncC::Condition)
        memory::Array{Int64,1} = []
        idx::Int64 = 1
        running::Bool = true
        print::Bool = true
        base::Int64 = 1

        function parseAndAdd(s::String)
            for i in split(s,",")
                push!(memory, parse(Int64, i))
            end
        end

        function acheck(address::Int64)
            l = length(memory)
            if address > length(memory)
                resize!(memory,address)
            end
        end

        # halt
        function op99(op::Tuple{Int64,Int64,Int64,Int64})
            running = false
            push!(output,99)
            notify(outc)
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
            println("Waiting for input")
            wait(syncC)
            memory[address] = pop!(input)
            println("Processing input $(memory[address])")
            idx += 2
        end

        #output
        function op4(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(idx+1,op[2])
            println("writing instruction: $a")
            push!(output,a)
            notify(syncC)
            println("written")
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

    function runRobot(input::Array{Int64},output::Array{Int64},syncC::Condition)
        hull::Array{Array{Int64}} = []
        visited::Dict{Tuple{Int64,Int64},Bool} = Dict{Tuple{Int64,Int64},Bool}()
        direction::Int64 = 0 #0 = up, 1 = right, 2 = down, 3 = left
        location::Tuple{Int64,Int64} = (50,50)
        running = true

        for i in 1:100
            push!(hull,zeros(100))
        end

        function ppp(paint::Int64)
            hull[location[1]][location[2]] = paint
            visited[location] = true
            println("r: painted")
        end

        #0 = up, 1 = right, 2 = down, 3 = left
        function domove()
            if direction == 0
                location = (location[1]-1,location[2])
            elseif direction == 1
                location = (location[1],location[2]+1)
            elseif direction == 2
                location = (location[1]+1,location[2])
            else
                location = (location[1],location[2]-1)
            end
        end

        function move(turn::Int64)
            if turn == 0
                direction -= 1
                if direction == -1
                    direction = 3
                end
            else
                direction = (direction +1) % 4
            end
            domove()
        end

        function execute()
            println("prebeep")
            push!(output,hull[location[1]][location[2]])
            notify(syncC)
            println("beep")
            wait(syncC)
            paint = pop!(input)
            println("r: paint $paint")
            if paint != 99
                println("r: going to painting")
                ppp(paint)
            else
                println("r: END")
                running = false
                return
            end
            println("r: getting turn")
            println("r: r")
            wait(syncC)
            println(input)
            turn = pop!(input)
            printlnt("r: turn $turn")
            if turn != 99
                move(turn)
            else
                println("r: END")
                running = false
                return
            end
            println("boop")
        end

        while running
            execute()
        end
        print(lenght(visited))
    end

    function run(program::String)
        amps::Channel{Tuple{Array{Int64},Array{Int64},Condition,Condition}} = Channel{Tuple{Array{Int64},Array{Int64},Condition,Condition}}(3)

        function launchprogram()
            # phase, inputchannel, outputchannel
            job::Tuple{Array{Int64},Array{Int64},Condition,Condition} = take!(amps)
            ic = job[1]
            oc = job[2]
            ac = job[3]
            #println("Starting AMP [$ampNum] with phase $phase")
            runprogramChannels(program,ic,oc,ac)
        end

        function launchrobot()
            # phase, inputchannel, outputchannel
            job::Tuple{Array{Int64},Array{Int64},Condition,Condition} = take!(amps)
            ic = job[1]
            oc = job[2]
            ac = job[3]
            #println("Starting AMP [$ampNum] with phase $phase")
            runRobot(ic,oc,ac)
        end

        a::Array{Int64} = []
        b::Array{Int64} = []
        c::Condition = Condition()
        d::Condition = Condition()
        put!(amps,(a,b,c,d))
        put!(amps,(b,a,c,d))
        @sync begin
            @async launchprogram()
            @async launchrobot()
        end
    end
end

#intcode.run("/Users/herste/Desktop/julia/2019/11/input.txt")
