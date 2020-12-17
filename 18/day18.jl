module vault
    using Combinatorics

    mutable struct path
        vault::Array{String}
        pos::Tuple{Int64,Int64}
        letters::String
        length::Int64
    end

    function run(program::String)::Int64
        #tovisit: x,y (target), input to give, processorstate
        start::Tuple{Int64,Int64} = (0,0)
        vault::Array{String} = []
        letters::String = ""


        x::Int64 = 1
        for line in eachline(program)
            y::Int64 = 1
            l::String = ""
            for i in line
                if i == '@'
                    println("FOUND")
                    start = (x,y)
                    i = "."
                end
                if isletter(i[1])
                    if ! (lowercase(i[1]) in letters)
                        letters = string(letters,lowercase(i[1]))
                    end
                end
                l = string(l, i)
                y += 1
            end
            push!(vault,l)
            x += 1
        end
        println("Start: $start letters: $letters")
        for l in vault
            println(l)
        end
        println()

        ### INIT DONE ####


        minPath::Int64 = 999999
        cp::path = path(vault,start,"",0)
        completed::Array{path} = []
        tovisit::Array{path} = [cp]

        cache::Dict{String,Int64} = Dict{String,Int64}()

        function genNextPaths(cpath::path)
            #vault, pos, length
            gvisited::Array{Tuple{Int64,Int64}} = [cpath.pos]
            gtovisit::Array{path} = []

            function genNext(p::path)
                for pp in [(p.pos[1]-1,p.pos[2]),(p.pos[1]+1,p.pos[2]),(p.pos[1],p.pos[2]-1),(p.pos[1],p.pos[2]+1)]
                    if pp in gvisited
                    else
                        if isletter(p.vault[pp[1]][pp[2]]) && islowercase(p.vault[pp[1]][pp[2]])
                            tgt::Char = p.vault[pp[1]][pp[2]]
                            found::path = deepcopy(p)
                            found.vault[pp[1]] = replace(found.vault[pp[1]], tgt => ".")
                            for i in 1:length(found.vault)
                                found.vault[i] = replace(found.vault[i], "$(uppercase(tgt))" => ".")
                            end
                            found.pos = pp
                            found.length += 1
                            found.letters = found.letters * string(tgt)
                            #found.letters = join(sort(collect(found.letters)))
                            #println("found possible path: $(found.letters)")
                            if found.length > get(cache,found.letters,99999999999999)
                                #println("Different! $found $cache")
                            else
                                cache[found.letters] = found.length
                                if length(found.letters) == length(letters)
                                    push!(completed,found)
                                else
                                    push!(tovisit,found)
                                end
                            end
                        elseif p.vault[pp[1]][pp[2]] == '.'
                            top = deepcopy(p)
                            top.pos = pp
                            top.length += 1
                            push!(gtovisit,top)
                            push!(gvisited,pp)
                        else
                            #Clearly a #
                        end
                    end
                end
            end
            genNext(cpath)
            while length(gtovisit) > 0
                genNext(pop!(gtovisit))
            end
        end


        while length(tovisit) > 0
            genNextPaths(pop!(tovisit))
        end

        for p in completed
            if p.length < minPath
                minPath = p.length
            end
        end

        println("$minPath")
        return minPath
    end
end

@assert vault.run("/Users/herste/Desktop/julia/2019/18/t1.txt") == 8
@assert vault.run("/Users/herste/Desktop/julia/2019/18/t2.txt") == 86
@assert vault.run("/Users/herste/Desktop/julia/2019/18/t3.txt") == 132
@assert vault.run("/Users/herste/Desktop/julia/2019/18/t4.txt") == 136
@assert vault.run("/Users/herste/Desktop/julia/2019/18/t5.txt") == 81

#vault.run("/Users/herste/Desktop/julia/2019/18/input.txt")
