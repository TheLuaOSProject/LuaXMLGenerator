local xml_gen = require("xml-generator")
local xml = xml_gen.xml
local ns = xml_gen.namespace "ns"
math.randomseed(os.time())

local header = xml_gen.component(function (args, ...)
    return xml.head {
        xml.title(args.title);
        xml.meta {
            name="viewport",
            content="width=device-width, initial-scale=1"
        };
        {...};
        args.css_framework;
    }
end)

local random_number = xml_gen.component(function (args)
    return xml.p(math.random(args.min, args.max))
end)

local rand_size = 10000000
local yield = coroutine.yield
local doc = xml_gen.declare_generator(function ()
---@diagnostic disable: undefined-global
    return html {charset="utf8"} {
        header {title="Hello, World!", css_framework=link {rel="stylesheet", href="..."}};

        body {
            h1 {class="text-center"} "Fritsite";
            main {class="container"} {
                p "Hello, World!";
                button {onclick="say_hi()"} "Say Hi!";
            };

            function ()
                for i = 1, rand_size do
                    yield(random_number {min=1, max=i})
                end
            end;

            ns.div {id="test div"} "hello"
        };
    }
---@diagnostic enable: undefined-global
end)

local accuratetime
if jit then
    local ffi = require("ffi")
    ffi.cdef [[
        typedef long time_t;
        struct timespec {
            time_t  tv_sec;
            long    tv_nsec;
        };
        typedef enum {
            CLOCK_REALTIME  = 0,
            
            CLOCK_MONOTONIC  = 6,
            
            
            CLOCK_MONOTONIC_RAW  = 4,
            
            CLOCK_MONOTONIC_RAW_APPROX  = 5,
            
            CLOCK_UPTIME_RAW  = 8,
            
            CLOCK_UPTIME_RAW_APPROX  = 9,
            
            
            CLOCK_PROCESS_CPUTIME_ID  = 12,
            
            CLOCK_THREAD_CPUTIME_ID  = 16
        } clockid_t;

        int clock_gettime(clockid_t _CLOCK_id, struct timespec *__tp);
    ]]

    accuratetime = {
        clock = function ()
            local spec = ffi.new("struct timespec[1]")
            if ffi.C.clock_gettime(ffi.C.CLOCK_MONOTONIC, spec) ~= 0 then return nil, "clock_gettime failed" end

            return tonumber(spec[0].tv_sec) + tonumber(spec[0].tv_nsec) * 1e-9
        end
    }
else
    accuratetime = require("accuratetime")
end

collectgarbage("stop")
collectgarbage("stop")

local start_time = accuratetime.clock()
xml_gen.expand_node(doc())
local end_time = accuratetime.clock()
io.stderr:write(string.format("Took %.2fs to expand", end_time-start_time), '\n')
io.stderr:write(string.format("%.2fKB used", collectgarbage("count")), '\n')
io.stderr:flush()

start_time = accuratetime.clock()
collectgarbage("collect")
end_time = accuratetime.clock()

io.stderr:write(string.format("Took %.2fs to collect garbage", end_time-start_time), '\n')
io.stderr:write(string.format("%.2fKB used", collectgarbage("count")), '\n')
io.stderr:flush()

start_time = accuratetime.clock()
_=tostring(doc())
end_time = accuratetime.clock()

io.stderr:write(string.format("Took %.2fs to expand+stringify", end_time-start_time), '\n')
io.stderr:write(string.format("%.2fKB used", collectgarbage("count")), '\n')
io.stderr:flush()

