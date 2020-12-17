module intcode
    using Match
    using Combinatorics

    mutable struct processorState
        memory::Array{Int64,1}
        idx::Int64
        base::Int64
        moves::Int64
    end

    function runprogram()
        #tovisit: x,y (target), input to give, processorstate
        tovisit::Array{Tuple{Int64,Int64,Int64,processorState}} = []
        visited::Dict{Tuple{Int64,Int64},Int64} = Dict{Tuple{Int64,Int64},Int64}()
        visited[(0,0)] = -1 # -1 == start; 0 == wall; 1 == hallway; 2 == oxygen
        running::Bool = true
        tgt::Tuple{Int64,Int64} = (0,0)
        found::Int64 = -1
        oxy::Tuple{Int64,Int64} = (0,0)
        gen::Int64 = 0

        #Build initial processor
        cp = processorState([],1,1,0)

        function parseAndAdd(s::String)
            for i in split(s,",")
                push!(cp.memory, parse(Int64, i))
            end
        end

        for line in eachline("/Users/herste/Desktop/julia/2019/15/input.txt")
            parseAndAdd(line)
        end

        ### Maze Search functions
        function domove(a::Int64)
            visited[tgt] = a
            found = a
            cp.moves += 1
            if a == 2
                println("FOUND OXIGEN IN $(cp.moves)")
                oxy = tgt
            end
        end

        function generateVisits()
            for c in [(tgt[1]-1,tgt[2],1), (tgt[1]+1,tgt[2],2), (tgt[1],tgt[2]-1,3), (tgt[1],tgt[2]+1,4)]
                if ! haskey(visited,(c[1],c[2]))
                    push!(tovisit, (c[1],c[2],c[3],deepcopy(cp)))
                    gen += 1
                end
            end
        end

        function getinput(address::Int64)
            if found == 1 || found == 2 || found == -1
                generateVisits()
            end
            if length(tovisit) > 0
                n::Tuple{Int64,Int64,Int64,processorState} = pop!(tovisit)
                tgt = (n[1],n[2])
                cp = n[4]
                cp.memory[address] = n[3]
            else
                running = false
            end
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
            println("HALT")
            cp.running = false
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
            cp.idx += 2
            getinput(address)
        end

        #output
        function op4(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(cp.idx+1,op[2])
            cp.idx += 2
            domove(a)
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
        #println(visited)
        # -1 == start; 0 == wall; 1 == hallway; 2 == oxygen
        # visited::Dict{Tuple{Int64,Int64},Int64} = Dict{Tuple{Int64,Int64},Int64}()

        minutes = 0

        voxy::Dict{Tuple{Int64,Int64},Int64} = Dict{Tuple{Int64,Int64},Int64}()
        voxy[oxy] = 2
        tovoxy::Array{Tuple{Int64,Int64}} = []
        function generateVisitsOxy(from::Tuple{Int64,Int64})
            for c in [(from[1]-1,from[2]), (from[1]+1,from[2]), (from[1],from[2]-1), (from[1],from[2]+1)]
                if ( ! haskey(voxy, c) ) && visited[c] != 0
                    #x,y (target), input to give, processorstate
                    push!(tovoxy, c)
                end
            end
        end
        generateVisitsOxy(oxy)
        running = true
        while running
            tovoxy2 = deepcopy(tovoxy)
            tovoxy = []
            for c in tovoxy2
                voxy[c] = 2
                generateVisitsOxy(c)
            end
            minutes += 1
            if length(tovoxy) == 0
                running = false
            end
        end
        println("MINUTES: $minutes")
        println("Generated $gen processor copies")
    end
end
