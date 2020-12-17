module game_of_life

    function readGame(gamestate::String)::Dict{Tuple{Int64,Int64,Int64},Int64}
        out::Dict{Tuple{Int64,Int64,Int64},Int64} = Dict{Tuple{Int64,Int64,Int64},Int64}()
        y = 1
        for l in eachline(gamestate)
            x = 1
            for i in split(l,"")
                if i[1] == '#'
                    out[(y,x,1)] = 1
                end
                x += 1
            end
            y += 1
        end
        return out
    end

    function printState(game::Dict{Tuple{Int64,Int64,Int64},Int64})
        for y in 1:5
            l = []
            for x in 1:5
                push!(l,get(game,(y,x,1),0))
            end
            println(join(l,""))
        end
    end

    function seenBefore!(mem::Dict{Int64,Bool},state::Dict{Tuple{Int64,Int64,Int64},Int64})::Bool
        val = stateToScore(state)
        ret = get(mem, val, false)
        mem[val] = true
        return ret
    end

    function stateToScore(state::Dict{Tuple{Int64,Int64,Int64},Int64})::Int64
        i = 1
        sum::Int64 = 0
        for y in 1:5
            for x in 1:5
                v = get(state,(y,x,1),0)
                sum += i * v
                i = i * 2
            end
        end
        return sum
    end

    function countBugs(state::Dict{Tuple{Int64,Int64,Int64},Int64})::Int64
        return length(keys(state))
    end

    function getNeighbours(idx::Tuple{Int64,Int64,Int64},multiDim::Bool)::Array{Tuple{Int64,Int64,Int64}}
        out::Array{Tuple{Int64,Int64,Int64}} = []
        if ! multiDim
            push!(out,(idx[1]-1,idx[2],idx[3]))
            push!(out,(idx[1]+1,idx[2],idx[3]))
            push!(out,(idx[1],idx[2]-1,idx[3]))
            push!(out,(idx[1],idx[2]+1,idx[3]))
        else
            # go left
            if idx[2] == 1
                #left edge
                push!(out, (3,2,idx[3]-1))
            elseif idx[2] == 4 && idx[1] == 3
                #left is middle piece
                for y in 1:5
                    push!(out, (y,5,idx[3]+1))
                end
            else
                push!(out, (idx[1], idx[2]-1, idx[3]))
            end
            # go right
            if idx[2] == 5
                #right edge
                push!(out, (3,4,idx[3]-1))
            elseif idx[2] == 2 && idx[1] ==3
                #right is middle piece
                for y in 1:5
                    push!(out, (y,1,idx[3]+1))
                end
            else
                push!(out, (idx[1], idx[2]+1, idx[3]))
            end
            # go top
            if idx[1] == 1
                push!(out, (2,3,idx[3]-1))
            elseif idx[1] == 4 && idx[2] == 3
                for x in 1:5
                    push!(out, (5,x,idx[3]+1))
                end
            else
                push!(out, (idx[1]-1, idx[2], idx[3]))
            end
            # go bottom
            if idx[1] == 5
                push!(out, (4,3,idx[3]-1))
            elseif idx[1] == 2 && idx[2] == 3
                for x in 1:5
                    push!(out, (1,x,idx[3]+1))
                end
            else
                push!(out, (idx[1]+1, idx[2], idx[3]))
            end
        end
        return out
    end

    function step!(state::Dict{Tuple{Int64,Int64,Int64},Int64},multiDim::Bool)::Dict{Tuple{Int64,Int64,Int64},Int64}
        counts::Dict{Tuple{Int64,Int64,Int64},Int64} = Dict{Tuple{Int64,Int64,Int64},Int64}()
        for idx in keys(state)
            for cidx in getNeighbours(idx,multiDim)
                counts[cidx] = get(counts, cidx, 0) + 1
            end
        end
        out = Dict{Tuple{Int64,Int64,Int64},Int64}()
        for cidx in keys(counts)
            if cidx[1] >= 1 && cidx[1] <= 5 && cidx[2] >= 1 && cidx[2] <= 5
                if counts[cidx] == 1
                    out[cidx] = 1
                end
                if counts[cidx] == 2 && get(state, cidx, 0) == 0
                    out[cidx] = 1
                end
            end
        end
        return out
    end

#=Solution part two: At first this looked totally insane but once I started thinking about it it turned out to be relatively straight forward. You just have to consider what cells are actually neighbours, given x,y, and how to handle the infinity. Pen and paper certainly helped with the former. I'm not sure if there is some super clean way to do it. My code to check neighbours turned out around 20 lines. I basically just check if you have neighbours on an above or below level, which you only do if you are at certain specific positions, as well as the ones on your current level.

To handle the infinity I keep a HashSet of the positions (x,y,z) of all current bugs. In each iteration, I loop over all of the bugs, find the neighbours of each of them and increment a neighbour-counter for all of those neighbours stored in a HashMap. This way, you ignore all the infinite amount of empty tiles with zero neighbours and only look at the potentially interesting tiles. You can even mutate the cells in-place instead of copying it each iteration.

I think my implementation is relatively efficient, finishes in around 65ms on my machine.

=#

    function part1(initial_state)::Int64
        game = readGame(initial_state)
        memory::Dict{Int64,Bool} = Dict{Int64,Bool}()
        count = 1
        while ! seenBefore!(memory, game)
            game = step!(game,false)
            if count %10000 == 0
                println("Generation: $count")
            end
            count += 1
        end
        return stateToScore(game)
    end

    function part2(initial_state::String, rounds::Int64)::Int64
        game = readGame(initial_state)
        memory::Dict{Int64,Bool} = Dict{Int64,Bool}()
        for i in 1:rounds
            game = step!(game,true)
        end
        return countBugs(game)
    end

    function test(num::Int)
        game = readGame("/Users/herste/Desktop/julia/2019/24/t1.txt")
        printState(game)
        for i in 1:num
            game = step!(game,false)
            println("\n\n After $i minutes:\n ")
            printState(game)
            println(stateToScore(game))
        end
    end
end

#part1: game_of_life.part1("/Users/herste/Desktop/julia/2019/24/input.txt")
#part2: game_of_life.part2("/Users/herste/Desktop/julia/2019/24/input.txt",200)

@assert game_of_life.part1("/Users/herste/Desktop/julia/2019/24/t1.txt") == 2129920
@assert game_of_life.part2("/Users/herste/Desktop/julia/2019/24/t1.txt",10) == 99
