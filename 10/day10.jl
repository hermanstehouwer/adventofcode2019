module astroids
    mutable struct Coord
        x::Int64
        y::Int64
        angle::Float64
    end

    function astroidfieldFindBest(input::String,part1::Bool)
        astroids::Array{Array{Char,1},1} = []
        coords::Array{Coord} = []

        function hasAstroid(x::Int64,y::Int64)::Bool
            return astroids[x][y] == '#'
        end

        function fillCoords(base::Tuple{Int64,Int64})
            for i in 1:length(astroids)
                for j in 1:length(astroids[i])
                    if (i,j) != base &&
                        hasAstroid(i,j) &&
                        sightNotBlocked(base[1],base[2],i,j)
                        push!(coords,Coord(i,j,getAngle(base,(i,j))))
                    end
                end
            end

        end

        function getAngle(base::Tuple{Int64,Int64},tgt::Tuple{Int64,Int64})::Float64
            Y = tgt[1] - base[1]
            X = tgt[2] - base[2]
            a::Float64 = atand(Y,X)
            a += 90.0
            a < 0.0 ? (return a = (360.0 + a)) : (return a)
        end

        function sightNotBlocked(x1::Int64,y1::Int64,x2::Int64,y2::Int64)::Bool
            dx::Int64 = abs(x2 - x1)
            dy::Int64 = abs(y2 - y1)
            g::Int64 = gcd(dx,dy)
            if dy == 1 || dx == 1
                return true
            end
            if g == 1 # Both x and y differences are not really divisable
                return true
            end
            for d in 2:g
                if dx%d == 0 && dy%d == 0
                    for rd in 1:(d-1)
                        cx::Int64 = x1 + ((x2 - x1)/d)*rd
                        cy::Int64 = y1 + ((y2 - y1)/d)*rd
                        if hasAstroid(cx, cy)
                            return false
                        end
                    end
                end
            end
            return true
        end

        function countastroids(x::Int64,y::Int64)
            count = 0
            for i in 1:length(astroids)
                for j in 1:length(astroids[i])
                    if (i,j) != (x,y) &&
                        hasAstroid(i,j) &&
                        sightNotBlocked(x,y,i,j)
                        count += 1
                    end
                end
            end
            return count
        end

        function parseAndAdd(s::String)
            line::Array{Char,1} = []
            for i in 1:length(s)
                push!(line, s[i])
            end
            push!(astroids,line)
        end

        for line in eachline(input)
            parseAndAdd(line)
        end

        maxcount::Int64 = 0
        station::Tuple{Int64,Int64} = (0,0)
        for i in 1:length(astroids)
            for j in 1:length(astroids[i])
                if hasAstroid(i,j)
                    count = countastroids(i,j)
                    if count > maxcount
                        maxcount = count
                        station = (i,j)
                    end
                end
            end
        end
        if(part1)
            return maxcount
        end
        fillCoords(station)
        sort!(coords, by = x -> x.angle)
        return (coords[200].y-1)*100+(coords[200].x-1)
    end
end

@assert astroids.astroidfieldFindBest("/Users/herste/Desktop/julia/2019/10/t1.txt",true) == 8
@assert astroids.astroidfieldFindBest("/Users/herste/Desktop/julia/2019/10/t2.txt",true) == 33
@assert astroids.astroidfieldFindBest("/Users/herste/Desktop/julia/2019/10/t3",true) == 35
@assert astroids.astroidfieldFindBest("/Users/herste/Desktop/julia/2019/10/t4.txt",true) == 41
@assert astroids.astroidfieldFindBest("/Users/herste/Desktop/julia/2019/10/t5.txt",true) == 210

@assert astroids.astroidfieldFindBest("/Users/herste/Desktop/julia/2019/10/t5.txt",false) == 802

# Solve part 1: astroids.astroidfieldFindBest("/Users/herste/Desktop/julia/2019/10/input.txt",true)
# Solve part 2: astroids.astroidfieldFindBest("/Users/herste/Desktop/julia/2019/10/input.txt",false)
