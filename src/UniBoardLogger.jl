module UniBoardLogger

using Term, RemoteREPL, UnicodePlots

global SYNC = Ref{Any}()

Base.@kwdef struct UniBoard{T1<:Union{AbstractVector,Nothing},T2,T3<:Union{Expr,Nothing}}
    index::T1
    trace::T2
    layout::T3=nothing
end

to_panel(p; kwargs...) = Panel(string(p; color=true); width=81, height=20, justify=:center, kwargs...)

function Base.string(ub::UniBoard)
    (; index, trace, layout) = ub
    ps = []
    for k in keys(trace)
        y = getindex(trace, k)
        x = isnothing(index) ? (1:length(y)) : index
        if length(index) == 0
            return ""
        end
        p = lineplot(x, y; width=64, height=16)
        push!(ps, (; title=string(k), plot=p))
    end
    panels = [to_panel(p.plot; title=p.title, box=:HEAVY) for p in ps]
    g = grid(panels; layout=layout)
    return string(Panel(g; title="UniBoard", box=:DOUBLE, style="blue"))
end

move_up(s::AbstractString) = move_up(stdout, s)
function move_up(stdout, s::AbstractString)
    move_up_n_lines(n) = "\u1b[$(n)F"
    string_height = length(collect(eachmatch(r"\n", s)))
    print(stdout, move_up_n_lines(string_height))
end

function hide_cursor(f)
    print("\u001B[?25l") # hide cursor
    retval = f()
    print("\u001B[?25h") # show cursor
    return retval
end

monitor(frame_delay::AbstractFloat=0.5) = monitor(() -> string(SYNC[]), frame_delay)
function monitor(gets::Function, frame_delay::AbstractFloat=0.5)
    hide_cursor() do 
        while true
            s = gets()
            print(s)
            sleep(frame_delay)
            move_up(s)
        end
    end
end

function sync_remote!(x)
    SYNC[] = deepcopy(x)
end

function serve_board()
    @async serve_repl()
end

function connect_board()
    connect_repl()
    RemoteREPL.send_and_receive(RemoteREPL._repl_client_connection, (:in_module, :UniBoardLogger))
end

monitor_remote(frame_delay::AbstractFloat=0.5) = monitor(() -> string(@remote(SYNC[])), frame_delay)

export UniBoard, hide_cursor, monitor, sync_remote!, serve_board, connect_board, monitor_remote

end # module