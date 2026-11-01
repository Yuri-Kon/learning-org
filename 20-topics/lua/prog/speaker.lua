local co = coroutine.create(
    function()
        local value = 1
        while true do
            local command = coroutine.yield(value)
            if command == "inc" then value = value + 1
            elseif command == "double" then value = value * 2
            elseif command == "get" then -- value 不变
            elseif command == "stop" then return value
            end
        end
    end
)

print(coroutine.resume(co))
print(coroutine.resume(co, "inc"))
print(coroutine.resume(co, "inc"))
print(coroutine.resume(co, "double"))
print(coroutine.resume(co, "get"))
print(coroutine.resume(co, "stop"))
