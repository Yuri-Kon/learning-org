-- task 描述要做什么
-- schedual 描述如何调度

-- mechanism

local function sleep(ticks)
    coroutine.yield("sleep", ticks)
end

local function yield_now()
    coroutine.yield("yield_now")
end

local function get_tick()
    return coroutine.yield("get_tick")
end

local function wait(name)
    return coroutine.yield("wait", name)
end

local function emit(name, value)
    return coroutine.yield("emit", name, value)
end

local function spawn(fn)
    return {
        co = coroutine.create(fn),
        wake_at = 0,
        waiting = nil,
        resume_value = nil
    }
end


local function consumer()
    print("consumer waiting")
    local value = wait("data")
    print("consumer received:", value)
end

local function producer()
    print("producer start")
    sleep(3)
    print("producer emit")
    emit("data", 42)
    print("producer done")
end

-- scheduler
-- 行为全部交给 scheduler

tasks = {
    spawn(consumer),
    spawn(consumer)    
}

local current_tick = 0
local events = {}

local function run()
    while #tasks > 0 do
        local alive = {}

        for _, task in ipairs(tasks) do
            local ready =
                task.waiting == nil
                and current_tick >= task.wake_at

            if ready then
                local ok, op, a, b =
                    coroutine.resume(
                    task.co,
                    task.resume_value
                    )

                task.resume_value = nil

                if not ok then
                    error(op)
                end

                if coroutine.status(task.co) ~= "dead" then
                    if op == "sleep" then
                        task.wake_at =
                            current_tick + a

                    elseif op == "yield" then
                        task.wake_at =
                            current_tick + 1

                    elseif op == "get_tick" then
                        task.resume_value =
                            current_tick

                        task.wake_at =
                            current_tick + 1

                    elseif op == "wait" then
                        task.waiting = a

                    elseif op == "emit" then
                        events[#events + 1] = {
                            name = a,
                            value = b,
                        }

                        task.wake_at =
                            current_tick + 1

                    else
                        error(
                            "unknown scheduler operation: "
                                .. tostring(op)
                        )
                    end

                    alive[#alive + 1] = task
                end
            else
                alive[#alive + 1] = task
            end
        end

        tasks = alive
        for _, event in ipairs(events) do
            for _, task in ipairs(tasks) do
                if task.waiting == event.name then
                    task.waiting = nil
                    task.resume_value = event.value
                    task.wake_at = current_tick + 1
                end
            end
        end
        events = {}
        current_tick = current_tick + 1
    end
end

run()
