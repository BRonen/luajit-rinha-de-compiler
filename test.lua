local module = require('compile_script')

function compare_sources(compiled_source, target_source_lines)
    local get_compiled_source_line = compiled_source:gmatch("[^\n]+")
    
    for k, target_line in ipairs(target_source_lines) do
        local compiled_line = get_compiled_source_line()

        print("compiled_line", compiled_line, #compiled_line)
        print("target_line", target_line, #target_line)
        if (target_line ~= compiled_line) then
            print('> error at line ' .. k .. ': ', target_line, compiled_line)
            
            return false, compiled_source, table.concat(target_source_lines, "\n")
        end
    end

    return true, compiled_source, table.concat(target_source_lines, "\n")
end

local tests = {
    should_print_hello_world = function ()
        local target_source = {
            "local call_memoization = {}",
            "print(\"Hello world\")",
        }

        local source_ast = get_file_contents('./tests/print.json')
        local compiled_source = module.compile_script(source_ast)

        return compare_sources(compiled_source, target_source)
    end,
    should_print_tuple_values = function ()
        local target_source = {
            "local call_memoization = {}",
            "local t = {3, 4}",
            "local _ = print((t)[1])",
            " ",
            "local _ = print((t)[2])",
            " ",
            "print(({4, 5})[2])"
        }

        local source_ast = get_file_contents('./tests/tuples.json')
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