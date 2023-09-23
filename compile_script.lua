function tprint (tbl, indent)
    if not indent then indent = 0 end
    
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
    
        if type(v) == "table" then
            
            print(formatting)
            tprint(v, indent+1)
            
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

function merge_tables (fst, snd)
    local result = fst
    
    for k,v in pairs(snd) do result[k] = v end

    if(fst.is_pure or snd.is_pure) then result.is_pure = true end

    return result
end

function get_file_contents (path)
    local file = io.open(path, "r")
    
    local content = ''
    
    for line in io.lines(path) do
        content = content .. line
    end
    
    file:close()
    
    return require("cjson").decode(content);
end

function map (tbl, f)
    local t = {}
    
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end

    return t
end

function check_function_flags (expression, context)
    if(not expression or type(expression) ~= 'table') then return { is_pure = true } end

    if(expression.kind == 'Print') then
        return merge_tables(context, { is_pure = false })
    end

    if(expression.kind == 'If') then
        local is_recursive = merge_tables(
            check_function_flags(expression['then'], context),
            check_function_flags(expression['otherwise'], context)
        ).is_recursive

        return merge_tables(context, { is_recursive = is_recursive })
    end

    if(expression.kind == 'Binary') then
        local is_recursive = merge_tables(
            check_function_flags(expression.lhs, context),
            check_function_flags(expression.rhs, context)
        ).is_recursive

        return merge_tables(context, { is_recursive = is_recursive })
    end
    
    if(expression.kind == 'Call' and expression.callee.text) == context.name then
        return merge_tables(context, { is_recursive = true })
    end
    
    return check_function_flags(expression.value, context)
end

--[[
let fib = fn (n) => {
  local result = nil
  
  while(not n < 2) {
    result = result + n - 1 + n - 2
  }
};
]]
function compile_as_iterative_function(expression, context, parameters)
    local parameters = parameters or ''
    return 'function ' .. context.name .. ' ( ' .. parameters .. ' )' .. [[
local result = nil
local stack = {}
while(not) ]] .. 'end\n'
end

local compile_binary_operators = {
    Lt = function (expression)
        return compile_expression(expression.lhs) .. '<' .. compile_expression(expression.rhs)
    end,
    Sub = function (expression)
        return compile_expression(expression.lhs) .. '-' .. compile_expression(expression.rhs)
    end,
    Add = function (expression)
        local operator = (expression.lhs.kind == 'Str' or expression.rhs.kind == 'Str') and '..' or '+'
        
        return compile_expression(expression.lhs) .. operator .. compile_expression(expression.rhs)
    end,
    Mul = function (expression) 
        return compile_expression(expression.lhs) .. '*' .. compile_expression(expression.rhs)
    end,
    Div = function (expression) 
        return compile_expression(expression.lhs) .. '/' .. compile_expression(expression.rhs)
    end,
    Rem = function (expression) 
        return 'math.fmod(' .. compile_expression(expression.lhs) .. ', ' .. compile_expression(expression.rhs) .. ')'
    end,
    Eq = function (expression) 
        return compile_expression(expression.lhs) .. '==' .. compile_expression(expression.rhs)
    end,
    Neq = function (expression) 
        return compile_expression(expression.lhs) .. '~=' .. compile_expression(expression.rhs)
    end,
    Lt = function (expression) 
        return compile_expression(expression.lhs) .. '<' .. compile_expression(expression.rhs)
    end,
    Gt = function (expression) 
        return compile_expression(expression.lhs) .. '>' .. compile_expression(expression.rhs)
    end,
    Lte = function (expression) 
        return compile_expression(expression.lhs) .. '<=' .. compile_expression(expression.rhs)
    end,
    Gte = function (expression) 
        return compile_expression(expression.lhs) .. '>=' .. compile_expression(expression.rhs)
    end,
    And = function (expression) 
        return compile_expression(expression.lhs) .. 'and' .. compile_expression(expression.rhs)
    end,
    Or = function (expression) 
        return compile_expression(expression.lhs) .. 'or' .. compile_expression(expression.rhs)
    end,
}

function compile_function_parameters (parameters, delimiter)
    local delimiter = delimiter or ''
    local result = ''
    
    for k, v in ipairs(parameters) do
        result = result .. v.text
        
        if (k ~= #parameters) then
            result = result .. delimiter
        end
    end

    return result
end

local compile_expression_by_kind = {
    Function = function (expression, context)
        local parameters = compile_function_parameters(expression.parameters, ', ')
        
        local flags = check_function_flags(expression, context)
        if(flags.is_pure ~= false) then flags.is_pure = true end

        --[[
            if(is_recursive) then
                return compile_as_iterative_function(expression, merge_table(context, { is_recursive = true }), parameters)
            end
        ]]

        local memoization_header = ''
        
        if(flags.is_pure) then
            memoization_header = 'if(call_memoization["' ..
                context.name .. '" .. ' .. compile_function_parameters(expression.parameters, ' .. "-" .. ') ..
            ']) then return call_memoization["' .. context.name .. '" .. ' .. compile_function_parameters(expression.parameters, ' .. "-" .. ') .. '] end\n\n'
        end

        return 'function ' .. context.name .. '(' .. parameters .. ')\n' ..
            memoization_header ..
            compile_expression(
                expression.value,
                merge_tables(
                    flags,
                    merge_tables(
                        context,
                        merge_tables(
                            { parameters = expression.parameters },
                            { is_returning = true }
                        )
                    )
                )
            ) ..
            '\nend\n\n'
    end,
    Let = function (expression, context)
        local context = context or {}
        if(expression.value.kind == 'Function') then
            return compile_expression(expression.value, merge_tables(context, {name = expression.name.text}))
        end
        return 'local ' .. expression.name.text .. ' = ' .. compile_expression(expression.value, merge_tables(context, {is_returning = false})) .. '\n'
    end,
    If = function (expression, context)
        local result = 'if (' .. compile_expression(expression.condition) .. ') then\n ' ..
            compile_expression(expression['then'], context)

        if(expression.otherwise) then
            result = result .. '\nelse\n ' .. compile_expression(expression.otherwise, context)
        end

        return result .. ' \nend'
    end,
    Binary = function (expression, context)
        local result = compile_binary_operators[expression.op](expression)

        if(context and context.is_pure and context.is_returning) then
            return 'local result = ' .. result ..
                '\n call_memoization["' .. context.name .. '" .. ' .. compile_function_parameters(context.parameters, ' .. "-" .. ') .. '] = result\n' .. 
                'return result'
        elseif(context and context.is_returning) then
            return 'return ' .. result
        end
        
        return result
    end,
    Var = function (expression, context)
        if(context and context.is_returning and context.is_pure) then
            return '\n call_memoization["' .. context.name .. '" .. ' .. compile_function_parameters(context.parameters, ' .. "-" .. ') .. '] = ' .. expression.text ..
                '\nreturn ' .. expression.text
        end
        if(context and context.is_returning) then return 'return ' .. expression.text end
        return expression.text
    end,
    Int = function (expression, context)
        if(context and context.is_returning) then return 'return ' .. expression.value end
        return expression.value
    end,
    Call = function (expression)
        local parameters = table.concat(map(expression.arguments, compile_expression), ', ')
        return compile_expression(expression.callee) .. '(' .. parameters .. ')'
    end,
    Str = function (expression, context)
        if(context and context.is_returning) then return 'return "' .. expression.value .. '"' end
        return '"' .. expression.value .. '"'
    end,
    Tuple = function (expression, context)
        if(context and context.is_returning) then return 'return ffi.new("tuple_t", {' .. expression.first .. ', ' .. expression.second .. '})' end
        return 'ffi.new("tuple_t", {' .. compile_expression(expression.first) .. ', ' .. compile_expression(expression.second) .. '})'
    end,
    First = function (expression, context)
        return '(' .. compile_expression(expression.value) .. ').first'
    end,
    Second = function (expression, context)
        return '(' .. compile_expression(expression.value) .. ').second'
    end,
    Print = function (expression)
        return 'print(' .. compile_expression(expression.value) .. ')\n '
    end,
}

function compile_expression (expression, context)
    local next = expression.next and compile_expression(expression.next, context) or ''

    local compiler_by_kind = compile_expression_by_kind[expression.kind]

    if (compiler_by_kind) then
        return compiler_by_kind(expression, context) .. next
    end

    return '[not implemented]'
end

function compile_script (script, context)
    return "local ffi = require(\"ffi\")\nlocal call_memoization = {}\nffi.cdef(\"typedef struct { uint32_t first, second; } tuple_t;\")\nlocal print = function (...)\nprint(unpack({...}))\nreturn unpack({...})\nend\n" ..
        compile_expression(script.expression)
end

return {
    compile_script = compile_script,
    get_file_contents = get_file_contents,
}