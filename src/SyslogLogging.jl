module SyslogLogging

using Syslogs
using Logging
using Sockets

import Logging: shouldlog, min_enabled_level, catch_exceptions, handle_message
export SyslogLogger

const last_ident = String[""]
function open_syslog(ident::String, facility::Symbol)
    Syslogs.openlog(ident, 0, Syslogs.FACILITIES[facility])
    global last_ident
    last_ident[1] = ident
    nothing
end

function set_syslog_identity(ident::String, facility::Symbol)
    global last_ident
    (last_ident[1] === ident) || open_syslog(ident, facility)
end

"""
Logs messages to a syslog facility.
"""
struct SyslogLogger <: AbstractLogger
    ident::String
    facility::Symbol
    syslog::Syslog
    min_level::LogLevel
    message_limits::Dict{Any,Int}
    lck::Union{Nothing,ReentrantLock}

    function SyslogLogger(ident::String, level=Logging.Info; facility::Symbol=:user, host::Union{Nothing,IPAddr,AbstractString}=nothing, port::Union{Nothing,Int}=nothing, tcp::Bool=false, lck::Union{Nothing,ReentrantLock}=nothing)
        syslog = (host === nothing) ? Syslog(facility) :
                 (port === nothing) ? Syslog(host, facility; tcp=tcp) :
                 Syslog((typeof(host) <: AbstractString) ? getaddrinfo(host) : host, port, facility; tcp=tcp)
        new(ident, facility, syslog, level, Dict{Any,Int}(), lck)
    end
end

idlock(fn, logger::SyslogLogger) = (logger.lck === nothing) ? fn() : lock(fn, logger.lck)

shouldlog(logger::SyslogLogger, level, _module, group, id) =
    get(logger.message_limits, id, 1) > 0

min_enabled_level(logger::SyslogLogger) = logger.min_level

catch_exceptions(logger::SyslogLogger) = false

function handle_message(logger::SyslogLogger, level, message, _module, group, id,
                        filepath, line; maxlog=nothing, kwargs...)
    if maxlog !== nothing && maxlog isa Integer
        remaining = get!(logger.message_limits, id, maxlog)
        logger.message_limits[id] = remaining - 1
        remaining > 0 || return
    end
    buf = IOBuffer()
    iob = IOContext(buf, logger.syslog)
    levelstr = level == Logging.Warn ? "Warning" : string(level)
    print(iob, levelstr, ": ", chomp(string(message)))
    print(iob, " [", something(_module, "nothing"), " ", something(filepath, "nothing"), ":", something(line, "nothing"), "]")
    if !isempty(kwargs)
        for (key, val) in kwargs
            print(iob, ", [", key, "=", val, "]")
        end
    end
    syslog_level = (level === Logging.Debug) ? :debug :
                   (level === Logging.Info) ? :info :
                   (level === Logging.Warn) ? :warn :
                   :error
    idlock(logger) do
        set_syslog_identity(logger.ident, logger.facility)
        println(logger.syslog, syslog_level, String(take!(buf)))
    end
    nothing
end

end # module
