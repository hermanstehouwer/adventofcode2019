module intcode
    using Match
    using Combinatorics

    function findmaxampvalue(program::String,numamps::Int64)
        maxval::Int64 = 0
        maxcomb::Array{Int64,1} = []
        for comb in permutations(0:(numamps-1))
            #println("Trying combination: $comb")
            pval = 0
            ic::Channel{Int64} = Channel{Int64}(3)
            oc::Channel{Int64} = Channel{Int64}(3)
            f::Channel{Bool} = Channel{Bool}(2)

            for phase in comb
                ic = Channel{Int64}(3)
                oc = Channel{Int64}(3)
                put!(ic,phase)
                put!(ic,pval)
                runprogramChannels(program,ic,oc,0)
                pval = take!(oc)
            end
            if pval > maxval
                maxval = pval
                maxcomb = copy(comb)
            end
        end
        println("Found combination $maxcomb for value $maxval")
        return maxval
    end

    function runprogram(program::String,input::Array{Int64,1})
        ic = Channel{Int64}(length(input))
        oc = Channel{Int64}(3)
        for i in input
            put!(ic,i)
        end
        intcode.runprogramChannels(program,ic,oc,0)
        pval = take!(oc)
        return pval
    end

    function runprogramChannels(program::String,input::Channel{Int64},output::Channel{Int64},label::Int64)
        memory::Array{Int64,1} = []
        idx::Int64 = 1
        running::Bool = true
        print::Bool = true

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
            memory[address] = take!(input)
            if label == 1 && print
                #WHYYYYYYYY
                sleep(0.001)
                print = false
            end
            idx += 2
        end

        #output
        function op4(op::Tuple{Int64,Int64,Int64,Int64})
            a = getval(idx+1,op[2])
            put!(output,a)
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

        for line in eachline(program)
            parseAndAdd(line)
        end

        while running
            execute()
        end
        return
    end

    function findmaxampvalueFBL(program::String,numamps::Int64)
        amps::Channel{Tuple{Int64,Channel{Int64},Channel{Int64},Int64}} = Channel{Tuple{Int64,Channel{Int64},Channel{Int64},Int64}}(numamps)

        function launchAmp()
            # phase, inputchannel, outputchannel
            job::Tuple{Int64,Channel{Int64},Channel{Int64},Int64} = take!(amps)
            phase = job[1]
            ic = job[2]
            oc = job[3]
            ampNum = job[4]
            #println("Starting AMP [$ampNum] with phase $phase")
            put!(ic, phase)
            if ampNum == 1
                put!(ic, 0)
            end
            runprogramChannels(program,ic,oc,ampNum)
        end

        maxval::Int64 = 0
        maxcomb::Array{Int64,1} = []
        for comb in permutations(5:(5+numamps-1))
            # program, phase, inputchannel, outputchannel, number
            amps = Channel{Tuple{Int64,Channel{Int64},Channel{Int64},Int64}}(numamps)
            oc = Channel{Int64}(3)
            startChannel = oc
            ampNum::Int64 = 1
            for phase in comb[1:numamps-1]
                ic = oc
                oc = Channel{Int64}(3)
                put!(amps,(phase,ic,oc,ampNum))
                ampNum += 1
            end
            ic = oc
            oc = startChannel
            phase = comb[numamps]
            put!(amps,(phase,ic,oc,ampNum))
            #Magic parrallel and producer/consumer amps
            @sync for i in 1:numamps
                @async launchAmp()
            end
            pval = take!(startChannel)
            if pval > maxval
                maxval = pval
                maxcomb = copy(comb)
            end
        end
        println("Found combination $maxcomb for value $maxval")
        return maxval
    end
end

#Day5,part2:   intcode.runprogram("/Users/herste/Desktop/julia/2019/5/input.txt",[5])
println("Testing if still valid with day 5 input")
@assert  intcode.runprogram("/Users/herste/Desktop/julia/2019/5/input.txt",[5]) == 9436229

println("Testing using the part1 tests")
#TEST, should give 43210 [4,3,2,1,0]: intcode.findmaxampvalue("/Users/herste/Desktop/julia/2019/7/t1.txt",5)
@assert intcode.findmaxampvalue("/Users/herste/Desktop/julia/2019/7/t1.txt",5) == 43210
#TEST, should give 54321 [0,1,2,3,4]: intcode.findmaxampvalue("/Users/herste/Desktop/julia/2019/7/t2.txt",5)
@assert intcode.findmaxampvalue("/Users/herste/Desktop/julia/2019/7/t2.txt",5) == 54321
#TEST, should give 65210 [1,0,4,3,2]: intcode.findmaxampvalue("/Users/herste/Desktop/julia/2019/7/t3.txt",5)
@assert intcode.findmaxampvalue("/Users/herste/Desktop/julia/2019/7/t3.txt",5) == 65210
#PART1: intcode.findmaxampvalue("/Users/herste/Desktop/julia/2019/7/input.txt",5)

println("Testing using the part2 tests")
#TEST, should give 139629729 [9,8,7,6,5] intcode.findmaxampvalueFBL("/Users/herste/Desktop/julia/2019/7/t4.txt",5)
@assert intcode.findmaxampvalueFBL("/Users/herste/Desktop/julia/2019/7/t4.txt",5) == 139629729
#TEST should give 18216 for [9,7,8,5,6] intcode.findmaxampvalueFBL("/Users/herste/Desktop/julia/2019/7/t5.txt",5)
@assert intcode.findmaxampvalueFBL("/Users/herste/Desktop/julia/2019/7/t5.txt",5) == 18216

#Part2: intcode.findmaxampvalueFBL("/Users/herste/Desktop/julia/2019/7/input.txt",5)
