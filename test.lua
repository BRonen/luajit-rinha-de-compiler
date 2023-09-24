local module = require('compile_script')

function sum_tables(a, b)
    local c = {}

    for _, entry in ipairs(a) do
        table.insert(c, entry)
    end

    for _, entry in ipairs(b) do
        table.insert(c, entry)
    end

    return c
end

function compare_sources(compiled_source, target_source_lines)
    local get_compiled_source_line = compiled_source:gmatch("[^\n]+")
    
    for k, target_line in ipairs(target_source_lines) do
        local compiled_line = get_compiled_source_line()

        --print("compiled_line", compiled_line, #compiled_line)
        --print("target_line", target_line, #target_line)
        if (target_line ~= compiled_line) then
            print('> error at line ' .. k .. ': ', target_line, compiled_line, #target_line, #compiled_line)
            
            return false, compiled_source, table.concat(target_source_lines, "\n")
        end
    end

    return true, compiled_source, table.concat(target_source_lines, "\n")
end

local default_headers = {
    "local ffi = require(\"ffi\")",
    "local ffi_new, INTERNAL_MEMOIZATION_TABLE, print = ffi.new, {}, function (...)",
    "    print(unpack({...}))",
    "    return unpack({...})",
    "end",
    "ffi.cdef(\"typedef struct { int32_t first, second; } INTERNAL_INTEGER_PAIR;\")",
}

local tests = {
    should_print_hello_world = function ()
        local target_source = sum_tables(
            default_headers, {
                "print(\"hello world\")"
            }
        )

        local source_ast = get_file_contents('./tests/print.json')
        local compiled_source = module.compile_script(source_ast)

        return compare_sources(compiled_source, target_source)
    end,
    should_print_tuple_values = function ()
        local target_source = sum_tables(
            default_headers, {
                "local optimized_tuple = { first = \"wasd\", second = 12 }",
                "local tuple = ffi_new(\"INTERNAL_INTEGER_PAIR\", {3, 4})",
                "function get_optimized_tuple(n, m)",
                "if(INTERNAL_MEMOIZATION_TABLE[\"get_optimized_tuple\" .. n .. \"-\" .. m]) then return INTERNAL_MEMOIZATION_TABLE[\"get_optimized_tuple\" .. n .. \"-\" .. m] end",
                "local INTERNAL_MEMOIZED_VALUE = { first = n, second = m }",
                "INTERNAL_MEMOIZATION_TABLE[\"get_optimized_tuple\" .. n .. \"-\" .. m] = INTERNAL_MEMOIZED_VALUE",
                "return INTERNAL_MEMOIZED_VALUE",
                "end",
                "function get_tuple()",
                "if(INTERNAL_MEMOIZATION_TABLE[\"get_tuple\"]) then return INTERNAL_MEMOIZATION_TABLE[\"get_tuple\"] end",
                "local INTERNAL_MEMOIZED_VALUE = { first = 7, second = \"8\" }",
                "INTERNAL_MEMOIZATION_TABLE[\"get_tuple\"] = INTERNAL_MEMOIZED_VALUE",
                "return INTERNAL_MEMOIZED_VALUE",
                "end",
                "local _ = print((get_optimized_tuple(5, 6)).first)",
                "local _ = print((get_optimized_tuple(5, 6)).second)",
                "local _ = print((get_tuple()).first)",
                "print((get_tuple()).second)",
            }
        )

        local source_ast = get_file_contents('./tests/tuples.json')
        local compiled_source = module.compile_script(source_ast)

        return compare_sources(compiled_source, target_source)
    end,
    should_generate_closures_with_correct_return_statements = function ()
        local target_source = sum_tables(
            default_headers, {
                "function id(n)",
                "if(INTERNAL_MEMOIZATION_TABLE[\"id\" .. n]) then return INTERNAL_MEMOIZATION_TABLE[\"id\" .. n] end",
                "INTERNAL_MEMOIZATION_TABLE[\"id\" .. n] = n",
                "return n",
                "end",
                "function is_less_than_five(n)",
                "if(INTERNAL_MEMOIZATION_TABLE[\"is_less_than_five\" .. n]) then return INTERNAL_MEMOIZATION_TABLE[\"is_less_than_five\" .. n] end",
                "if (( n < 5 )) then",
                "return true",
                "else",
                "return false",
                "end",
                "end",
                "function better_is_less_than_five(n)",
                "if(INTERNAL_MEMOIZATION_TABLE[\"better_is_less_than_five\" .. n]) then return INTERNAL_MEMOIZATION_TABLE[\"better_is_less_than_five\" .. n] end",
                "local INTERNAL_MEMOIZED_VALUE = ( n < 5 )",
                "INTERNAL_MEMOIZATION_TABLE[\"better_is_less_than_five\" .. n] = INTERNAL_MEMOIZED_VALUE",
                "return INTERNAL_MEMOIZED_VALUE",
                "end",
                "function print_hello()",
                "return print(\"hello\")",
                "end",
                "function print_world()",
                "return print(\"world\")",
                "end",
                "local _ = print(id(\"something\"))",
                "local _ = print(is_less_than_five(4))",
                "local _ = print(is_less_than_five(5))",
                "local _ = print(better_is_less_than_five(89374))",
                "local _ = print_hello()",
                "print_world()",
            }
        )

        local source_ast = get_file_contents('./tests/closures.json')
        local compiled_source = module.compile_script(source_ast)

        return compare_sources(compiled_source, target_source)
    end,
    should_generate_nested_ifs_with_binary_operators_precedence = function ()
        local target_source = sum_tables(
            default_headers, {
                "function returning_nested_ifs(x)",
                "if (( x == 3 and ( 3 <= 2 or ( 2 == ( 4 - ( 4 / ( 2 * 1 ) ) ) or true ) ) )) then",
                "if (( x == 2 or ( x == 1 ) )) then",
                "if (( x == 1 )) then",
                "return print(\"x is 1\")",
                "else",
                "return print(\"x is 2\")",
                "end",
                "else",
                "return print(\"x is problably 3\")",
                "end",
                "else",
                "local _ = print(x)",
                "return x",
                "end",
                "end",
                "local _ = print(returning_nested_ifs(1))",
                "local _ = print(returning_nested_ifs(2))",
                "local _ = print(returning_nested_ifs(3))",
                "local _ = print(returning_nested_ifs(4))",
                "print(returning_nested_ifs(false))",
            }
        )

        local source_ast = get_file_contents('./tests/conditionals.json')
        local compiled_source = module.compile_script(source_ast)

        return compare_sources(compiled_source, target_source)
    end,
    should_run_conditionals_as_expressions = function ()
        local target_source = sum_tables(
            default_headers, {
                "function rec(n, acc)",
                "if(INTERNAL_MEMOIZATION_TABLE[\"rec\" .. n .. \"-\" .. acc]) then return INTERNAL_MEMOIZATION_TABLE[\"rec\" .. n .. \"-\" .. acc] end",
                "if (( acc == n )) then",
                "INTERNAL_MEMOIZATION_TABLE[\"rec\" .. n .. \"-\" .. acc] = acc",
                "return acc",
                "else",
                "local INTERNAL_MEMOIZED_VALUE = ( rec(n, ( acc + 1 )) + 0 )",
                "INTERNAL_MEMOIZATION_TABLE[\"rec\" .. n .. \"-\" .. acc] = INTERNAL_MEMOIZED_VALUE",
                "return INTERNAL_MEMOIZED_VALUE",
                "end",
                "end",
                "function rec_tail_call(n, acc)",
                "if(INTERNAL_MEMOIZATION_TABLE[\"rec_tail_call\" .. n .. \"-\" .. acc]) then return INTERNAL_MEMOIZATION_TABLE[\"rec_tail_call\" .. n .. \"-\" .. acc] end",
                "if (( acc == n )) then",
                "INTERNAL_MEMOIZATION_TABLE[\"rec_tail_call\" .. n .. \"-\" .. acc] = acc",
                "return acc",
                "else",
                "return rec_tail_call(n, ( acc + 1 ))",
                "end",
                "end",
                "local a = ( 123 == ( 124 - 1 ) ) and (function()",
                "local _ = print(123)",
                "return true",
                "end)() or (function()",
                "return false",
                "end)()",
                "local _ = print(rec_tail_call(40000, 0))",
                "print(a)",
            }
        )

        local source_ast = get_file_contents('./tests/recursion.json')
        local compiled_source = module.compile_script(source_ast)

        return compare_sources(compiled_source, target_source)
    end
}

for k, v in pairs(tests) do
    local is_success, compiled_source, target_source = v()

    if is_success then
        print(k .. ' -> Success :)')
    else
        print(k .. ' -> Failure :(')
        print('\tExpected: \n' .. target_source .. '\n\n')
        print('\tReceived: \n' .. compiled_source .. '\n\n')
    end
end