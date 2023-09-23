function trampoline (fn)
    while (type(fn) == 'function') do
        fn = fn();
    end

    return fn;
end

function fib(n)
    if(n <= 2) then return 1 else return function() return trampoline(fib(n-1)) + trampoline(fib(n-2)) end end
end

function fib2(n, a, b)
    if(n == 0) then return a else return fib2(n - 1, b, a + b) end
end

::test::
print('a')
goto test

print(trampoline(fib(100000)))