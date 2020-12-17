module spaceImageFormat

    function spaceImageNumber(input::String,xsize::Int64,ysize::Int64)
        memory::Array{Int64,1} = []
        function parseAndAdd(s::String)
            for i in split(s,"")
                push!(memory, parse(Int64, i))
            end
        end

        for line in eachline(input)
            parseAndAdd(line)
        end
        layersize::Int64 = xsize*ysize
        layers::Int64 = length(memory) / layersize
        #find 0 layer
        function countX(ll::Int64,x::Int64)
            count::Int64 = 0
            for c in collect(memory[ Int(1+((ll-1)*layersize)) : Int((ll*layersize)) ])
                if c == x
                    count +=1
                end
            end
            return count
        end
        minzeros::Int64 = 9999999
        minlayer::Int64 = 1

        for l in 1:layers
            zcount = countX(l,0)
            if zcount < minzeros
                minzeros = zcount
                minlayer = l
            end
        end
        ones = countX(minlayer,1)
        twos = countX(minlayer,2)
        return ones * twos
    end
    function spaceImageNumber2(input::String,xsize::Int64,ysize::Int64)
        memory::Array{Int64,1} = []
        function parseAndAdd(s::String)
            for i in split(s,"")
                push!(memory, parse(Int64, i))
            end
        end

        for line in eachline(input)
            parseAndAdd(line)
        end
        layersize::Int64 = xsize*ysize
        layers::Int64 = length(memory) / layersize
        #find 0 layer
        out::Array{Int64} = zeros(ysize,xsize)
        #println("xs:$xsize, ys:$ysize, ll:$layers")
        for y in 1:ysize
            for x in 1:xsize
                det::Bool = false
                o::Int64 = 1
                for l in 1:layers
                    #println("x:$x, y:$y, l:$l")
                    if det == false
                        #println(memory)
                        tgt = memory[ (x+((y-1)*xsize)+((l-1)*layersize)) ]
                        #println("$tgt for position $(x+((y-1)*ysize)+((l-1)*layersize))")
                        if tgt != 2
                            det = true
                            o = tgt
                        end
                    end
                end
                out[y,x] = o
            end
        end
        return out
    end
end

@assert spaceImageFormat.spaceImageNumber("/Users/herste/Desktop/julia/2019/8/t1.txt",3,2) == 1
#spaceImageFormat.spaceImageNumber("/Users/herste/Desktop/julia/2019/8/input.txt",25,6)
#spaceImageFormat.spaceImageNumber2("/Users/herste/Desktop/julia/2019/8/input.txt",25,6)
