module FFT

    function run(program::String)::String

        in::Array{BigInt,1} = []
        pattern::Array{Int64,1} = [0,1,0,-1]
        function parseLine(s::String)
            for i in split(s,"")
                push!(in,parse(BigInt,i))
            end
        end

        for line in eachline(program)
            parseLine(line)
        end

        function exec()
            for i in 1:length(in)
                # Index of new value to calculate
                skip::Bool = true
                repeat::Int64 = i
                calc::BigInt = 0
                idx::Int64 = 1 # Idx for 1:length(pattern)
                repeated::Int64 = 1
                # #repeat on pattern
                for j in 1:length(in)
                    # j index to calculate
                    if repeated > repeat
                        idx += 1
                        if idx > length(pattern)
                            idx = 1
                        end
                        repeated = 1
                    end
                    repeated += 1
                    if skip
                        skip = false
                        if repeated > repeat
                            idx += 1
                            if idx > length(pattern)
                                idx = 1
                            end
                            repeated = 1
                        end
                        repeated += 1
                    end

                    #println("FOR $i doing $(in[j]) * $(pattern[idx])")
                    calc += in[j] * pattern[idx]
                end
                in[i] = calc
            end
            #println("After round b: $in")
            for i in 1:length(in)
                in[i] = abs(in[i] % 10)
            end
            #println("After round: $in")
        end

        for i in 1:100
            exec()
        end
        #println(in)
        return join(in[1:8])
    end

    function run2(program::String)::String

        in::Array{Int64,1} = []
        offset::Int64 = 0

        function parseLine(s::String)
            for i in split(s,"")
                push!(in,parse(BigInt,i))
            end
        end

        for line in eachline(program)
            parseLine(line)
        end

        function exec()
            for i in length(in)-1:-1:1
                # Index of new value to calculate

                in[i] = (in[i] + in[i+1])% 10
            end
        end

        offset = parse(Int64,join(in[1:7]))
        offset += 1
        in = repeat(in,10000)

        for i in 1:100
            exec()
            #println("$i")
        end
        return join(in[offset:offset+7])
    end
end

#@assert FFT.run("/Users/herste/Desktop/julia/2019/16/t0.txt") == "01029498"
@assert FFT.run("/Users/herste/Desktop/julia/2019/16/t1.txt") == "24176176"
@assert FFT.run("/Users/herste/Desktop/julia/2019/16/t2.txt") == "73745418"
@assert FFT.run("/Users/herste/Desktop/julia/2019/16/t3.txt") == "52432133"
#FFT.run("/Users/herste/Desktop/julia/2019/16/input.txt")
#FFT.run2("/Users/herste/Desktop/julia/2019/16/input.txt")
