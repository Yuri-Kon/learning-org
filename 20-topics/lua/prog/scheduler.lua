local function task(name, n)
    return coroutine.create(
        function()
            for i = 1, n do
                coroutine.yield(name, i)
            end
        end
    )
end

local tasks = {
    task("A", 3),
    task("B", 3),
}

while #tasks > 0 do -- 执行多轮轮询
    local alive = {}
    for _, co in ipairs(tasks) do
        local ok, name, value = coroutine.resume(co)
        if not ok then
            error(name)
        end

        if coroutine.status(co) ~= "dead" then
            print("scheduler received:", name, value)
            table.insert(alive, co)
        end
    end
    tasks = alive
end
