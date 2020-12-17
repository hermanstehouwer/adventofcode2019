module mooons

    mutable struct moon
        pos::Tuple{Int64,Int64,Int64}
        vel::Tuple{Int64,Int64,Int64}
    end

    function run(test::Bool)
        moons::Array{moon} = []

        function applyGravity(m::moon,n::moon)
            cvel::Array{Int64} = zeros(3)
            for i in 1:3
                if  m.pos[i] < n.pos[i]
                    cvel[i] = m.vel[i] + 1
                elseif  m.pos[i] > n.pos[i]
                    cvel[i] = m.vel[i] - 1
                else
                    cvel[i] = m.vel[i]
                end
            end
            m.vel = Tuple(cvel)
        end

        function gravity()
            for m in moons
                for n in moons
                    if !(m === n)
                        applyGravity(m,n)
                    end
                end
            end
        end

        function moveMoon(m::moon)
            np = zeros(3)
            for i in 1:3
                np[i] =  m.pos[i] + m.vel[i]
            end
            m.pos = Tuple(np)
        end

        function move()
            for m in moons
                moveMoon(m)
            end
        end

        function step()
            gravity()
            move()
        end

        if test
            push!(moons, moon((-8,-10,0),(0,0,0)))
            push!(moons, moon((5,5,10),(0,0,0)))
            push!(moons, moon((2,-7,3),(0,0,0)))
            push!(moons, moon((9,-8,-3),(0,0,0)))
            for i in 1:100
                step()
                if i%10 == 0
                    println("After $i steps")
                    for m in moons
                        println(m)
                    end
                end
            end

        else
            push!(moons, moon((6,-2,-7),(0,0,0)))
            push!(moons, moon((-6,-7,-4),(0,0,0)))
            push!(moons, moon((-9,11,0),(0,0,0)))
            push!(moons, moon((-3,-4,6),(0,0,0)))
            for i in 1:1000
                step()
            end
        end

        function nrg(m::moon)
            spos = 0
            svel = 0
            for i in 1:3
                spos += abs(m.pos[i])
                svel += abs(m.vel[i])
            end
            return spos * svel
        end

        return sum(map(x -> nrg(x),moons))
    end

    function run2(test::Bool)
        moons::Array{moon} = []

        function applyGravity(m::moon,n::moon,idx::Int64)
            cvel::Array{Int64} = zeros(3)
            if  m.pos[idx] < n.pos[idx]
                cvel[idx] = m.vel[idx] + 1
            elseif  m.pos[idx] > n.pos[idx]
                cvel[idx] = m.vel[idx] - 1
            else
                cvel[idx] = m.vel[idx]
            end
            m.vel = Tuple(cvel)
        end

        function gravity(idx::Int64)
            for m in moons
                for n in moons
                    if !(m === n)
                        applyGravity(m,n,idx)
                    end
                end
            end
        end

        function moveMoon(m::moon,idx::Int64)
            np = zeros(3)
            for i in 1:3
                np[i] =  m.pos[i]
            end
            np[idx] =  m.pos[idx] + m.vel[idx]
            m.pos = Tuple(np)
        end

        function move(idx::Int64)
            for m in moons
                moveMoon(m,idx)
            end
        end

        function step(idx::Int64)
            gravity(idx)
            move(idx)
        end

        function makeMoons()
            moons = []
            push!(moons, moon((6,-2,-7),(0,0,0)))
            push!(moons, moon((-6,-7,-4),(0,0,0)))
            push!(moons, moon((-9,11,0),(0,0,0)))
            push!(moons, moon((-3,-4,6),(0,0,0)))
        end

        function findCycle(idx::Int64)::Int64
            t::Dict{String,Bool} = Dict{String,Bool}()
            c::Int64 = 0
            function moons2S(idx)
                o::Array{String} = []
                for m in moons
                    push!(o,string(m.pos[idx]))
                    push!(o,string(m.vel[idx]))
                end
                return join(o)
            end

            while get(t, moons2S(idx), true)
                t[moons2S(idx)] = false
                c += 1
                step(idx)
            end
            return c
        end
        times::Array{Int64} = []
        for i in 1:3
            makeMoons()
            push!(times,findCycle(i))
        end

        function nrg(m::moon)
            spos = 0
            svel = 0
            for i in 1:3
                spos += abs(m.pos[i])
                svel += abs(m.vel[i])
            end
            return spos * svel
        end

        return lcm(times[1],lcm(times[2],times[3]))
    end
end

#intcode.run("/Users/herste/Desktop/julia/2019/11/input.txt")
