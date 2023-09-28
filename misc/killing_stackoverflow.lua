--[[
function trampoline (fn)
    while (type(fn) == 'function') do
        fn = fn();
    end

    return fn;
end

function trampoline_add(a, b)
    if(type(a) == 'function' and type(b) == 'function') then
        -- print(a, b)
        return function() return trampoline_add(a(), b()) end
    end
    return function()
        print(a, trampoline(a), b)
        return trampoline(a) + b
    end
end

function fib(n)
    if(n <= 2) then
        return 1
    else
        return fib(n - 1) + fib(n - 2) end
    end
end

function fib2(n, a, b)
    if(n == 0) then
        return a
    else
        return fib2(n - 1, b, a + b)
    end
end

::test::
print('a')
goto test

--print(fib2(100000, 0, 1))
--print(trampoline(fib(30)))

local memoization = {}

function fib(n)
    function inner(n, cont)
        if(n < 2) then
            return cont(n)
        else
            if(memoization[n]) then
                return cont(memoization[n])
            end
            
            return inner(
                n - 1,
                function(a)
                    memoization[n - 1] = a
                    return inner(
                        n - 2,
                        function(b)
                            memoization[n - 2] = b
                            return cont(a + b)
                        end
                    )
                end
            )
        end
    end

    return inner(
        n,
        function(c)
            return c
        end
    )
end

inner(
    55,
    function(c)
        return c
    end
)
print('a', fib(55))

]]

local print = function (value)
    if(type(value) == 'Function') then
        print('<#Closure>')
    else
        print(value)
    end

    return value
end

function fib(n)
    function INTERNAL_INNER_FUNCTION_fib (n, INTERNAL_CONTINUATION)
        if (( n < 2 )) then
            return INTERNAL_CONTINUATION( print(n) )
        else
            return INTERNAL_INNER_FUNCTION_fib(
                ( n - 1 ),
                function(INTERNAL_CONTINUATION_RESULT_1)
                    return INTERNAL_INNER_FUNCTION_fib(
                        ( n - 2 ),
                        function(INTERNAL_CONTINUATION_RESULT_2)
                            return INTERNAL_CONTINUATION(
                                INTERNAL_CONTINUATION_RESULT_1 + INTERNAL_CONTINUATION_RESULT_2
                            )
                        end
                    )
                end
            )
        end
    end
    
    return INTERNAL_INNER_FUNCTION_fib(n, function(INTERNAL_X) return print(INTERNAL_X) end)
end

fib(260000000)