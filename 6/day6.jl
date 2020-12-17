module Day6
    mutable struct tnalpha
        name::String
        depth::Int64
        children::Array{tnalpha,1}
    end

    function day6func(orbits::String,part2::Bool)
        nodes::Dict{String,tnalpha} = Dict{String,tnalpha}()

        function hasVal(p::tnalpha,val::String)::Bool
            if p.name == val
                return true
            end
            for c in p.children
                if hasVal(c,val)
                    return true
                end
            end
            return false
        end

        function findLen(p::tnalpha,val::String,d::Int64)::Int64
            if p.name == val
                return d
            end
            if length(p.children) == 0
                return 0
            end
            return foldl(+,map(x -> findLen(x,val,d+1), p.children))
        end

        function hasYou(p::tnalpha)::Bool
            return hasVal(p,"YOU")
        end

        function hasSan(p::tnalpha)::Bool
            return hasVal(p,"SAN")
        end

        function findYouAndSan(p::tnalpha)::tnalpha
            for c in p.children
                if hasYou(c) && hasSan(c)
                    return findYouAndSan(c)
                end
            end
            return p
        end

        function findroot()::tnalpha
            for n in values(nodes)
                if n.depth == 0
                    return n
                end
            end
        end

        function walkandcorrect(parent::tnalpha,newdepth)
            parent.depth = newdepth
            for c in parent.children
                walkandcorrect(c, newdepth+1)
            end
        end

        function buildtree(parent::tnalpha,child::String)
            c = tnalpha(child,parent.depth+1,[])
            if child in keys(nodes)
                c = nodes[child]
                walkandcorrect(c,parent.depth+1)
            end
            nodes[child] = c
            push!(parent.children,c)
        end

        function buildtree(parent::String,child::String)
            if parent in keys(nodes)
                buildtree(nodes[parent],child)
                return
            end
            p = tnalpha(parent,0,[])
            nodes[parent] = p
            buildtree(p,child)
        end

        function parseAndAdd(line)
            o = split(line,")")
            buildtree(string(o[1]),string(o[2]))
        end

        for line in eachline(orbits)
            parseAndAdd(line)
        end

        if part2
            p = findroot()
            p = findYouAndSan(p)
            return findLen(p,"YOU",-1) + findLen(p,"SAN",-1)
        end

        return foldl(+,map(x -> x.depth, values(nodes)))

    end

end

#Day6.day6func("/Users/herste/Desktop/julia/2019/6/input.txt",false)
