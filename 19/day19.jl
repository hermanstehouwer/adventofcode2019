module intcode
    using Match
    using Combinatorics

    mutable struct processorState
        memory::Array{Int64,1}
        idx::Int64
        base::Int64
        moves::Int64
    end

    function run()
        running::Bool = true
        #Build initial processor
        cp = processorState([],1,1,0)

        last::Array{Int64} = [0,0]

        function parseAndAdd(s::String)
            for i in split(s,",")
                push!(cp.memory, parse(Int64, i))
            end
        end

        for l in eachline("/Users/herste/Desktop/julia/2019/19/input.txt")
            parseAndAdd(l)
        end
        cp2 = deepcopy(cp)


        ### Maze Search functions
        inputs::Array{Int64} = []
        for x in 0:49
            for y in 0:49
                push!(inputs,x)
                push!(inputs,y)
            end
        end
        println(inputs)
        count::Int64 = 0
        function giveoutput(a::Int64)
            count += a
            #println("GOT $a for location $last")
        end

        function getinput()::Int64
            if length(inputs) > 0
                ret = popfirst!(inputs)
                push!(last,ret)
                popfirst!(last)
                return ret
            end
            running = false
        end
        ### / BOT

        function acheck(address::Int64)
            l = length(cp.memory)
            if address > length(cp.memory)
                resize!(cp.memory,address)
            end
        end

        # halt
        function op99(op::Tuple{Int64,Int64,Int64,Int64})
            if length(inputs) > 0
                cp = deepcopy(cp2)
            else
                running = false
            end
        end

        # add
        function op1(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            address = getloc(cp.idx+3,op[4])
            acheck(address)
            cp.memory[address] = a + b
            cp.idx += 4
        end

        # mult
        function op2(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            address = getloc(cp.idx+3,op[4])
            acheck(address)
            cp.memory[address] = a * b
            cp.idx += 4
        end

        #input
        function op3(op::Tuple{Int64,Int64,Int64,Int64})
            address = getloc(cp.idx+1,op[2])
            acheck(address)
            cp.memory[address] = getinput()
            cp.idx += 2
        end

        #output
        function op4(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            cp.idx += 2
            giveoutput(a)
        end

        #jit
        function op5(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            if a != 0
                cp.idx = b+1
            else
                cp.idx+=3
            end
        end

        #jif
        function op6(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            if a == 0
                cp.idx = b+1
            else
                cp.idx += 3
            end
        end

        #lt
        function op7(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            address = getloc(cp.idx+3,op[4])
            acheck(address)
            if a < b
                cp.memory[address] = 1
            else
                cp.memory[address] = 0
            end
            cp.idx += 4
        end

        #eq
        function op8(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            address = getloc(cp.idx+3,op[4])
            acheck(address)
            if a == b
                cp.memory[address] = 1
            else
                cp.memory[address] = 0
            end
            cp.idx += 4
        end

        #adjust relative base
        function op9(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            #println("9: modifying $base with $a")
            cp.base += a
            cp.idx += 2
        end

        function noop()
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
                rpos = cp.memory[pos]+1
            end
            if mode == 2
                #println("Accessing in M2: $(base+memory[pos])  ( $base $(memory[pos]) )")
                rpos = cp.base + cp.memory[pos]
            end
            acheck(rpos)
            return cp.memory[rpos]
        end

        function getloc(pos::Int64,mode::Int64)
            if mode == 0
                return cp.memory[pos]+1
            end
            if mode == 2
                #println("loc in M2: $(base+pos)")
                return cp.base + cp.memory[pos]
            end
            return pos+1
        end

        function execute()
            op = splitopcode(cp.memory[cp.idx])
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
        while running
            execute()
        end
        println("COUNT $count")
    end

    function run2()
        running::Bool = true
        #Build initial processor
        cp = processorState([],1,1,0)

        function parseAndAdd(s::String)
            for i in split(s,",")
                push!(cp.memory, parse(Int64, i))
            end
        end

        for l in eachline("/Users/herste/Desktop/julia/2019/19/input.txt")
            parseAndAdd(l)
        end
        cp2 = deepcopy(cp)


        ### Maze Search functions
        tl::Array{Int64} = [10,1]
        inputs::Array{Int64} = deepcopy(tl)
        state::Int64 = 0

        function movedown()
            tl[2] += 1
            inputs = deepcopy(tl)
            state = 0
        end

        function moveright()
            tl[1] += 1
            inputs = deepcopy(tl)
            state = 0
        end

        function checkbl()
            inputs = deepcopy(tl)
            inputs[2] += 99
            state = 1
        end

        function checktr()
            inputs = deepcopy(tl)
            inputs[1] += 99
            state = 2
        end

        function found()
            println(tl)
            println(tl[1]*10000 + tl[2])
            running = false
        end

        #Checking the top-left (the base of everything!)
        function state0(a::Int64)
            if a == 0
                movedown()
            else
                checkbl()
            end
        end

        #Checking the bottom-left (the base of everything!)
        function state1(a::Int64)
            if a == 0
                moveright()
            else
                checktr()
            end
        end

        #Checking the top-right (the base of everything!)
        function state2(a::Int64)
            if a == 0
                movedown()
            else
                found()
            end
        end


        function giveoutput(a::Int64)
            @match state begin
                0 => state0(a)
                1  => state1(a)
                2  => state2(a)
            end
            cp = deepcopy(cp2)
        end

        function getinput()::Int64
            ret = popfirst!(inputs)
            return ret
        end
        ### / BOT

        function acheck(address::Int64)
            l = length(cp.memory)
            if address > length(cp.memory)
                resize!(cp.memory,address)
            end
        end

        # halt
        function op99(op::Tuple{Int64,Int64,Int64,Int64})
            if length(inputs) > 0
                cp = deepcopy(cp2)
            else
                running = false
            end
        end

        # add
        function op1(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            address = getloc(cp.idx+3,op[4])
            acheck(address)
            cp.memory[address] = a + b
            cp.idx += 4
        end

        # mult
        function op2(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            address = getloc(cp.idx+3,op[4])
            acheck(address)
            cp.memory[address] = a * b
            cp.idx += 4
        end

        #input
        function op3(op::Tuple{Int64,Int64,Int64,Int64})
            address = getloc(cp.idx+1,op[2])
            acheck(address)
            cp.memory[address] = getinput()
            cp.idx += 2
        end

        #output
        function op4(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            cp.idx += 2
            giveoutput(a)
        end

        #jit
        function op5(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            if a != 0
                cp.idx = b+1
            else
                cp.idx+=3
            end
        end

        #jif
        function op6(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            if a == 0
                cp.idx = b+1
            else
                cp.idx += 3
            end
        end

        #lt
        function op7(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            address = getloc(cp.idx+3,op[4])
            acheck(address)
            if a < b
                cp.memory[address] = 1
            else
                cp.memory[address] = 0
            end
            cp.idx += 4
        end

        #eq
        function op8(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            b = getval(cp.idx+2,op[3])
            address = getloc(cp.idx+3,op[4])
            acheck(address)
            if a == b
                cp.memory[address] = 1
            else
                cp.memory[address] = 0
            end
            cp.idx += 4
        end

        #adjust relative base
        function op9(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            #println("9: modifying $base with $a")
            cp.base += a
            cp.idx += 2
        end

        function noop()
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
                rpos = cp.memory[pos]+1
            end
            if mode == 2
                #println("Accessing in M2: $(base+memory[pos])  ( $base $(memory[pos]) )")
                rpos = cp.base + cp.memory[pos]
            end
            acheck(rpos)
            return cp.memory[rpos]
        end

        function getloc(pos::Int64,mode::Int64)
            if mode == 0
                return cp.memory[pos]+1
            end
            if mode == 2
                #println("loc in M2: $(base+pos)")
                return cp.base + cp.memory[pos]
            end
            return pos+1
        end

        function execute()
            op = splitopcode(cp.memory[cp.idx])
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
        while running
            execute()
        end
        println("COUNT $count")
    end
end
