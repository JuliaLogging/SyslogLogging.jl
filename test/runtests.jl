using SyslogLogging
using Test
using Logging

function do_logging()
    @debug("hello syslog")
    @info("hello syslog")
    @warn("hello syslog")
    @error("hello syslog")
    @debug("hello syslog", param1="param1", param2=100, dict=Dict("abc"=>12, "def"=>20))
    @info("hello syslog", param1="param1", param2=100, dict=Dict("abc"=>12, "def"=>20))
    @warn("hello syslog", param1="param1", param2=100, dict=Dict("abc"=>12, "def"=>20))
    @error("hello syslog", param1="param1", param2=100, dict=Dict("abc"=>12, "def"=>20))
    nothing
end

function test_single_logger()
    logger = SyslogLogger("sysloglogger")
    with_logger(do_logging, logger)
end

function test_multiple_loggers()
    lck = ReentrantLock()
    logger1 = SyslogLogger("sysloglogger1"; lck=lck)
    logger2 = SyslogLogger("sysloglogger2"; lck=lck)
    @sync begin
        @async with_logger(do_logging, logger1)
        @async with_logger(do_logging, logger2)
    end
end

test_single_logger()
test_multiple_loggers()
