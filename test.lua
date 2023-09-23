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
    "local call_memoization = {}",
    "ffi.cdef(\"typedef struct { uint32_t first, second; } tuple_t;\")",
    "local print = function (...)",
    "print(unpack({...}))",
    "return unpack({...})",
    "end",
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
                "local t = ffi.new(\"tuple_t\", {3, 4})",
                "local _ = print((t).first)",
                "local _ = print((t).second)",
                "print((ffi.new(\"tuple_t\", {4, 5})).second)"
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
                "if(call_memoization[\"id\" .. n]) then return call_memoization[\"id\" .. n] end",
                "call_memoization[\"id\" .. n] = n",
                "return n",
                "end",
                "function is_less_than_five(n)",
                "if(call_memoization[\"is_less_than_five\" .. n]) then return call_memoization[\"is_less_than_five\" .. n] end",
                "if (n<5) then",
                "return true",
                "else",
                "return false ",
                "end",
                "end",
                "function better_is_less_than_five(n)",
                "if(call_memoization[\"better_is_less_than_five\" .. n]) then return call_memoization[\"better_is_less_than_five\" .. n] end",
                "local result = n<5",
                "call_memoization[\"better_is_less_than_five\" .. n] = result",
                "return result",
                "end",
                "function print_hello()",
                "print(\"hello\")",
                "end",
                "function print_world()",
                "print(\"world\")",
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