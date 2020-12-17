module donut
    using DataStructures

    mutable struct mazePath
        to::String
        steps::Int64
    end

    function getgrid(maze::String)::Array{Array{Char}}
        grid::Array{Array{Char}} = []
        for l in eachline(maze)
            line::Array{Char} = []
            for c in split(l, "")
                push!(line, c[1])
            end
            push!(grid, line)
        end
        return grid
    end

    function getgate(grid,y,x)::Tuple{Int64,Int64,String}
        if isletter(grid[y-2][x]) && isletter(grid[y-1][x])
            return (y,x,String([grid[y-2][x],grid[y-1][x]]))
        elseif isletter(grid[y+2][x]) && isletter(grid[y+1][x])
            return (y,x,String([grid[y+1][x],grid[y+2][x]]))
        elseif isletter(grid[y][x-2]) && isletter(grid[y][x-1])
            return (y,x,String([grid[y][x-2],grid[y][x-1]]))
        elseif isletter(grid[y][x+2]) && isletter(grid[y][x+1])
            return (y,x,String([grid[y][x+1],grid[y][x+2]]))
        end
        return (0,0,"")
    end

    function hasgate(grid,y,x)::Bool
        return getgate(grid,y,x)[1] != 0
    end

    function getgates(grid::Array{Array{Char}})::Array{Tuple{Int64,Int64,String}}
        out::Array{Tuple{Int64,Int64,String}} = []
        for y in 3:length(grid)-2
            for x in 3:length(grid[y])-2
                if grid[y][x] == '.'
                    ##ONLY .s are potential starting points (with length 1)
                    # Lovely thing about our input is that there is space around all of it. No needs for bounds-checking!
                    pg::Tuple{Int64,Int64,String} = getgate(grid,y,x)
                    if pg[1] != 0
                        push!(out, pg)
                    end
                end
            end
        end
        return out
    end

    function getAdjecentDots(grid,y,x)
        out = []
        if grid[y-1][x] == '.'
            push!(out, (y-1,x))
        end
        if grid[y+1][x] == '.'
            push!(out, (y+1,x))
        end
        if grid[y][x-1] == '.'
            push!(out, (y,x-1))
        end
        if grid[y][x+1] == '.'
            push!(out, (y,x+1))
        end
        return out
    end

    function getPaths(y,x,steps,lbl::String,grid::Array{Array{Char}},visited::Set{Tuple{Int64,Int64}})::Array{mazePath}
        v2 = deepcopy(visited)
        push!(v2, (y,x))
        if hasgate(grid,y,x) && getgate(grid,y,x)[3] != lbl
            return [mazePath(getgate(grid,y,x)[3],steps)]
        end
        out::Array{mazePath} = []
        for idx in getAdjecentDots(grid,y,x)
            if idx in v2
            else
                for p in getPaths(idx[1],idx[2],steps+1,lbl,grid,v2)
                    push!(out, p)
                end
            end
        end
        return out
    end

    function getPaths2(y,x,steps,lbl::String,grid::Array{Array{Char}},visited::Set{Tuple{Int64,Int64}},gateLookup::Dict{Tuple{Int64,Int64},String})::Array{mazePath}
        v2 = deepcopy(visited)
        push!(v2, (y,x))
        if haskey(gateLookup,(y,x)) && gateLookup[(y,x)] != lbl
            return [mazePath(gateLookup[(y,x)],steps)]
        end
        out::Array{mazePath} = []
        for idx in getAdjecentDots(grid,y,x)
            if idx in v2
            else
                for p in getPaths2(idx[1],idx[2],steps+1,lbl,grid,v2,gateLookup)
                    push!(out, p)
                end
            end
        end
        return out
    end

    function buildgraph(maze::String)::Dict{String,Array{mazePath}}
        grid::Array{Array{Char}} = getgrid(maze)
        gateLocations::Array{Tuple{Int64,Int64,String}} = getgates(grid)
        out::Dict{String,Array{mazePath}} = Dict{String,Array{mazePath}}()
        for gl in gateLocations
            lbl = gl[3]
            y = gl[1]
            x = gl[2]
            paths::Array{mazePath} = getPaths(y,x,0,lbl,grid,Set{Tuple{Int64,Int64}}())
            addto = get(out,lbl,[])
            for p in paths
                push!(addto, p)
            end
            out[lbl] = addto
        end
        return out
    end

    function buildgraph2(maze::String)::Dict{String,Array{mazePath}}
        grid::Array{Array{Char}} = getgrid(maze)
        gateLocations::Array{Tuple{Int64,Int64,String}} = getgates(grid)
        out::Dict{String,Array{mazePath}} = Dict{String,Array{mazePath}}()
        gateLookup::Dict{Tuple{Int64,Int64},String} = Dict{Tuple{Int64,Int64},String}()
        for gl in gateLocations
            lbl = gl[3]
            y = gl[1]
            x = gl[2]
            if y <= 3 || y >= (length(grid) - 3) || x <= 3 || x >= (length(grid[1]) - 3)
                #Outer gate
                gateLookup[(y,x)] = "$(lbl)O"
            else
                #inner gate
                gateLookup[(y,x)] = "$(lbl)I"
            end
        end
        for gl in keys(gateLookup)
            ########
            y = gl[1]
            x = gl[2]
            lbl = gateLookup[gl]
            paths::Array{mazePath} = getPaths2(y,x,0,lbl,grid,Set{Tuple{Int64,Int64}}(),gateLookup)
            addto = get(out,lbl,[])
            for p in paths
                push!(addto, p)
            end
            out[lbl] = addto
        end
        return out
    end

    function findShortestPathLength(graph,start::String,target::String)::Int64
        # NOOT: each node "hop" has cost 1
        # Dijkstra
        queue::PriorityQueue{String, Int64} = PriorityQueue{String, Int64}()
        dists::Dict{String,Int64} = Dict{String,Int64}()

        for lbl in keys(graph)
            dists[lbl] = 999999999999999
        end
        dists[start] = 0
        enqueue!(queue, start, 0)

        while length(queue) > 0
            curr = dequeue!(queue)
            if curr == target
                return dists[target]-1
            end
            paths = graph[curr]
            for p in paths
                if (p.steps + dists[curr] + 1) < dists[p.to]
                    dists[p.to] = (p.steps + dists[curr] + 1)
                    queue[p.to] = (p.steps + dists[curr] + 1)
                end
            end
        end
        # Because of the hop cost: last hop to target is not a hop, substract 1
        return dists[target]-1
    end

    function findShortestPathLength2(graph,start::String,target::String)::Int64
        # NOOT: each node "hop" has cost 1; level jumping is free
        # CAN hop dimensions!
        # Dijkstra
        queue::PriorityQueue{Tuple{String,Int64}, Int64} = PriorityQueue{String, Int64}()
        dists::Dict{Tuple{String,Int64},Int64} = Dict{Tuple{String,Int64},Int64}()
        dists[(start,0)] = 0
        enqueue!(queue, (start,0), 0)

        while length(queue) > 0
            curr, lvl = dequeue!(queue)
            paths = graph[curr]
            for p in paths
                if (p.steps + dists[(curr,lvl)] + 1) < get(dists, (p.to,lvl), 9999999999)
                    if p.to == target && lvl > 0 # Gate Closed
                    elseif p.to == start && lvl > 0 # Gate Closed
                    elseif p.to == target && lvl == 0 # FOUND!
                        dists[(p.to,lvl)] = (p.steps + dists[(curr,lvl)] + 1)
                        return dists[(p.to,lvl)] -1
                    else
                        dists[(p.to,lvl)] = (p.steps + dists[(curr,lvl)] + 1)
                        if p.to[3] == 'O'
                            #Outer $O connects to $I on lvl-1
                            #I.e. if on lvl0: BLOCK
                            if lvl > 0
                                nlbl = string(p.to[1:2],"I")
                                dists[(nlbl,lvl-1)] = dists[(p.to,lvl)]
                                queue[(nlbl,lvl-1)] = dists[(p.to,lvl)]
                            end
                        else
                            #Inner $I connects to $O on lvl+1)
                            nlbl = string(p.to[1:2],"O")
                            dists[(nlbl,lvl+1)] = dists[(p.to,lvl)]
                            queue[(nlbl,lvl+1)] = dists[(p.to,lvl)]
                        end
                    end
                end
            end
        end
    end

    function part1(maze::String)::Int64
        #Find minimum path from AA to ZZ
        graph = buildgraph(maze)
        return findShortestPathLength(graph,"AA","ZZ")
    end

    function part2(maze::String)::Int64
        graph = buildgraph2(maze)
        return findShortestPathLength2(graph,"AAO","ZZO")
    end
end

@assert donut.part1("/Users/herste/Desktop/julia/2019/20/t1.txt") == 23
@assert donut.part1("/Users/herste/Desktop/julia/2019/20/t2.txt") == 58
# Part1: donut.part1("/Users/herste/Desktop/julia/2019/20/input.txt")


@assert donut.part2("/Users/herste/Desktop/julia/2019/20/t3.txt") == 396
# Part2: donut.part2("/Users/herste/Desktop/julia/2019/20/input.txt")
