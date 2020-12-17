module intcode
    using Match
    using Combinatorics

    mutable struct processorState
        memory::Array{Int64,1}
        idx::Int64
        base::Int64
        rempty::Bool
        input::Array{Int64}
        output::Array{Int64}
    end

    function makeProcessor(program::String)::processorState
        ret = processorState([],1,1,false,[],[])
        for l in eachline(program)
            for i in split(l,",")
                push!(ret.memory, parse(Int64, i))
            end
        end
        return ret
    end

    function step!(cp::processorState)::processorState
        ### HOOKS
        function giveoutput(a::Int64)
            push!(cp.output, a)
        end

        function getinput()::Int64
            if length(cp.input) > 0
                cp.rempty = false
                return popfirst!(cp.input)
            else
                cp.rempty = true
                return -1
            end
        end
        ### / HOOKS

        function acheck(address::Int64)
            l = length(cp.memory)
            if address > length(cp.memory)
                resize!(cp.memory,address)
            end
        end

        # halt
        function op99(op::Tuple{Int64,Int64,Int64,Int64})
            println("HALT")
            running = false
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
        execute()
        return cp
    end

    function makeNetwork(program::String,numCPU::Int64)::Dict{Int64,processorState}
        network::Dict{Int64,processorState} = Dict{Int64,processorState}()
        for cpu_num in 0:(numCPU-1)
            cp = makeProcessor(program)
            push!(cp.input,cpu_num)
            network[cpu_num] = cp
        end
        return network
    end

    function part1(program::String,numCPU::Int64)::Int64
        println("Making network")
        network::Dict{Int64,processorState} = makeNetwork(program,numCPU)
        println("Network initialized")
        while true
            for cp_key in keys(network)
                cp = network[cp_key]
                step!(cp)
                if length(cp.output) == 3
                    addr = popfirst!(cp.output)
                    X = popfirst!(cp.output)
                    Y = popfirst!(cp.output)
                    if addr in keys(network)
                        tp = network[addr]
                        push!(tp.input, X)
                        push!(tp.input, Y)
                    else
                        if addr == 255
                            return Y
                        else
                            println("ERROR: CPU $addr X:$X Y:$Y")
                        end
                    end
                end
            end
        end
    end

    function part2(program::String,numCPU::Int64)::Int64
        network::Dict{Int64,processorState} = makeNetwork(program,numCPU)
        NAT::Array{Int64} = []
        seenNAT::Array{Int64} = []

        function allwaiting()::Bool
            for cp in values(network)
                if ! cp.rempty
                    return false
                end
            end
            return true
        end

        function processOutput!(cp)
            addr = popfirst!(cp.output)
            X = popfirst!(cp.output)
            Y = popfirst!(cp.output)
            if addr in keys(network)
                tp = network[addr]
                push!(tp.input, X)
                push!(tp.input, Y)
            else
                if addr == 255
                    NAT = [X,Y]
                else
                    println("ERROR: CPU $addr X:$X Y:$Y")
                end
            end
        end

        function sendNAT()
            push!(network[0].input, NAT[1])
            push!(network[0].input, NAT[2])
            push!(seenNAT, NAT[2])
            NAT = []
        end

        while true
            for cp_key in keys(network)
                cp = network[cp_key]
                step!(cp)
                if length(cp.output) == 3
                    processOutput!(cp)
                end
            end
            if allwaiting() && length(NAT) > 0
                if NAT[2] in seenNAT
                    return NAT[2]
                end
                sendNAT()
            end
        end
    end
end

# intcode.part1("/Users/herste/Desktop/julia/2019/23/input.txt",50)
