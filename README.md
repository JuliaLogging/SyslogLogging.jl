# SyslogLogging

[![Build Status](https://travis-ci.org/tanmaykm/SyslogLogging.jl.png)](https://travis-ci.org/tanmaykm/SyslogLogging.jl)
[![Coverage Status](https://coveralls.io/repos/github/tanmaykm/SyslogLogging.jl/badge.svg?branch=master)](https://coveralls.io/github/tanmaykm/SyslogLogging.jl?branch=master)

Provides an implementation of `AbstractLogger` that can log into syslog. The syslog interface is based on [Syslogs.jl](https://github.com/invenia/Syslogs.jl).

### Usage:

```julia
julia> using SyslogLogging, Logging

julia> logger = SyslogLogger("myapplication", Logging.Info);

julia> with_logger(logger) do
           @info("hello syslog")
           @warn("hello", p1=100, d=Dict("a"=>1, "b"=>2))
       end

shell> tail -2 /var/log/syslog
Mar 18 18:30:33 tanlto myapplication: Info: hello syslog [Main REPL[4]:2]
Mar 18 18:30:33 tanlto myapplication: Warning: hello [Main REPL[4]:3], [p1=100], [d=Dict("a"=>1,"b"=>2)]
```

#### Using Remote Syslog Servers

To use a remote syslog server, provide the connection parameters in addition to the logging identity.

```
julia> logger = SyslogLogger("myapplication", Logging.Info; host=ip"127.0.0.1", port=514, tcp=false)
```

#### Using Multiple Instances

Applications should ideally have only one instance of `SyslogLogger`, and use keywords instead to differentiate between log identities. But if an application must use multiple instances of `SyslogLogger` with different identities to operate parallely, it may provide a lock to be used by the loggers. Otherwise, because the underlying syslog library provides only one context, there is a chance that the identities may get mixed up. Providing a `ReentrantLock` with the `lck` keyword would prevent that. E.g.:

```julia
julia> using SyslogLogging, Logging

julia> lck = ReentrantLock();

julia> logger1 = SyslogLogger("sysloglogger1"; lck=lck);

julia> logger2 = SyslogLogger("sysloglogger2"; lck=lck);
```

