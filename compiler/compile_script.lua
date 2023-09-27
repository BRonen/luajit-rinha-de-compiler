local new_string_builder = require('../string_builder')
local compile_binary_operators = require('./compiler/binary_operators')
-- local tprint = require('../debug')

function merge_tables (fst, snd)
    local result = {}
    
    for k,v in pairs(fst) do result[k] = v end
    for k,v in pairs(snd) do result[k] = v end

    result.is_recursive = fst.is_recursive or snd.is_recursive
    result.is_pure = fst.is_pure and snd.is_pure

    return result
end

function check_function_flags(expression, context)
    if(not expression or type(expression) ~= 'table') then return { is_pure = true } end

    if(expression.kind == 'Print') then
        return { is_pure = false }
    end

    if(expression.kind == 'If') then
        local flags = merge_tables(
            check_function_flags(expression['condition'], context),
            check_function_flags(expression['then'], context)
        )

        if(expression.otherwise) then
            flags = merge_tables(flags, check_function_flags(expression['otherwise'], context))
        end

        return flags
    end

    if(expression.kind == 'Binary') then
        local flags = merge_tables(
            check_function_flags(expression.lhs, context),
            check_function_flags(expression.rhs, context)
        )

        return flags
    end
    
    if(expression.kind == 'Call' and expression.callee.text == context.name) then
        local flags = { is_recursive = true }

        for _, argument in ipairs(expression.arguments) do
            flags = merge_tables(flags, check_function_flags(argument, context))
        end

        return flags
    end
    
    return check_function_flags(expression.value, context)
end

--[[
function compile_as_iterative_function(expression, context, parameters)
    local parameters = parameters or ''
    return 'function ' .. context.name .. ' ( ' .. parameters .. ' )' .. [[
        local result = nil
        local stack = {}
        while(not) ] ] .. 'end\n'
    end
]]

function compile_function_parameters (string_builder, parameters, delimiter, is_concatenating)
    if(is_concatenating and #parameters ~= 0) then string_builder:push(' .. ') end

    local delimiter = delimiter or ''
    
    for k, v in ipairs(parameters) do
        string_builder:push(v.text)
        
        if (k ~= #parameters) then
            string_builder:push(delimiter)
        end
    end

    return string_builder
end

local compile_expression_by_kind = {
    Function = function (string_builder, expression, context)
        local flags = check_function_flags(expression, context)
        
        local inner_context = merge_tables(
            context,
            merge_tables(
                flags,
                { parameters = expression.parameters, is_returning = true }
            )
        )

        inner_context.is_pure = flags.is_pure ~= false

        --[[
            if(is_recursive) then
                return compile_as_iterative_function(expression, merge_table(context, { is_recursive = true }), parameters)
            end
-        ]]

        string_builder:push('function ')
        if(context.name) then string_builder:push(context.name) end
        string_builder:push('(')
        compile_function_parameters(string_builder, expression.parameters, ', ')
        string_builder:push(')\n')
        
        if(inner_context.is_pure) then
            string_builder:push('if(INTERNAL_MEMOIZATION_TABLE["')
            string_builder:push(context.name)
            string_builder:push('"')

            compile_function_parameters(string_builder, expression.parameters, ' .. "-" .. ', true)
            
            string_builder:push(']) then return INTERNAL_MEMOIZATION_TABLE["')
            string_builder:push(context.name)
            string_builder:push('"')

            compile_function_parameters(string_builder, expression.parameters, ' .. "-" .. ', true)

            string_builder:push('] end\n\n')
        end

        compile_expression(
            string_builder,
            expression.value,
            inner_context
        )

        return string_builder:push('\nend\n')
    end,
    Let = function (string_builder, expression, context)
        local context = context or {}

        if(expression.value.kind == 'Function') then
            compile_expression(string_builder, expression.value, merge_tables(context, {name = expression.name.text}))
        else        
            string_builder:push('local ')
            string_builder:push(expression.name.text)
            string_builder:push(' = ')

            compile_expression(
                string_builder,
                expression.value,
                merge_tables(
                    context,
                    {
                        is_returning = false,
                        is_variable = true
                    }
                )
            )
            
            string_builder:push('\n')
        end

        compile_expression(
            string_builder,
            expression.next,
            context
        )
    end,
    If = function (string_builder, expression, context)
        if(context.is_variable) then
            compile_expression(string_builder, expression.condition)

            string_builder:push(' and (function()\n')

            compile_expression(string_builder, expression['then'], merge_tables(context, { is_returning = true }))

            if(expression.otherwise) then
                string_builder:push('\nend)() or (function()\n')

                compile_expression(string_builder, expression.otherwise, merge_tables(context, { is_returning = true }))

                return string_builder:push('\nend)()')
            end

            return string_builder:push('\nend)() or nil')
        end

        string_builder:push('if (')
        
        compile_expression(string_builder, expression.condition)

        string_builder:push(') then\n')

        compile_expression(string_builder, expression['then'], context)

        if(expression.otherwise) then
            string_builder:push('\nelse\n')

            compile_expression(string_builder, expression.otherwise, context)
        end

        return string_builder:push('\nend')
    end,
    Binary = function (string_builder, expression, context)
        if(context and context.is_returning and context.is_pure) then
            string_builder:push('local INTERNAL_MEMOIZED_VALUE = ')

            compile_binary_operators[expression.op](string_builder, expression)

            string_builder:push('\nINTERNAL_MEMOIZATION_TABLE["')
            string_builder:push(context.name)
            string_builder:push('"')
            
            compile_function_parameters(string_builder, context.parameters, ' .. "-" .. ', true)
            
            return string_builder:push('] = INTERNAL_MEMOIZED_VALUE\nreturn INTERNAL_MEMOIZED_VALUE')
        end

        if(context and context.is_returning) then
            string_builder:push('\nreturn ')
        end
        
        return compile_binary_operators[expression.op](string_builder, expression)
    end,
    Var = function (string_builder, expression, context)
        if(context) then
            --string_builder:push({tostring(context.is_returning), tostring(context.is_pure)})
        end
        if(context and context.is_returning) then
            if(context.is_pure) then                
                string_builder:push('\nINTERNAL_MEMOIZATION_TABLE["')
                string_builder:push(context.name)
                string_builder:push('"')

                compile_function_parameters(string_builder, context.parameters, ' .. "-" .. ', true)
                
                string_builder:push('] = ')
                string_builder:push(expression.text)
            end

            string_builder:push('\nreturn ')
        end

        return string_builder:push(expression.text)
    end,
    Int = function (string_builder, expression, context)
        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        return string_builder:push(expression.value)
    end,
    Call = function (string_builder, expression, context)
        if(context and context.is_pure and context.is_returning) then
            string_builder:push('return ')

            compile_expression(string_builder, expression.callee)
            string_builder:push('(')
    
            for i, argument in ipairs(expression.arguments) do
                compile_expression(string_builder, argument)
    
                if(i ~= #expression.arguments) then string_builder:push(', ') end
            end
    
            return string_builder:push(')\n')
        end

        if(context and context.is_returning) then
            string_builder:push('\nreturn ')
        end

        compile_expression(string_builder, expression.callee)
        string_builder:push('(')

        for i, argument in ipairs(expression.arguments) do
            compile_expression(string_builder, argument)

            if(i ~= #expression.arguments) then string_builder:push(', ') end
        end

        return string_builder:push(')')
    end,
    Str = function (string_builder, expression, context)
        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        return string_builder:push({'"', expression.value, '"'})
    end,
    Tuple = function (string_builder, expression, context)
        local begin, middle, final = '{ first = ', ', second = ', ' }'

        if(expression.first.kind == 'Int' and expression.second.kind == 'Int') then
            begin, middle, final = 'ffi_new("INTERNAL_INTEGER_PAIR", {', ', ', '})'
        end
        
        if(context and context.is_returning) then
            if(context.is_pure) then
                string_builder:push('local INTERNAL_MEMOIZED_VALUE = ')
                string_builder:push(begin)

                compile_expression(string_builder, expression.first)

                string_builder:push(middle)

                compile_expression(string_builder, expression.second)

                string_builder:push(final)
                string_builder:push('\nINTERNAL_MEMOIZATION_TABLE["')
                string_builder:push(context.name)
                string_builder:push('"')
                
                compile_function_parameters(string_builder, context.parameters, ' .. "-" .. ', true)

                string_builder:push('] = INTERNAL_MEMOIZED_VALUE\nreturn INTERNAL_MEMOIZED_VALUE\n')
                return
            end
            
            string_builder:push('\nreturn ')
        end
        string_builder:push(begin)
        compile_expression(string_builder, expression.first)
        string_builder:push(middle)
        compile_expression(string_builder, expression.second)
        string_builder:push(final)
    end,
    First = function (string_builder, expression, context)
        string_builder:push('(')
        compile_expression(string_builder, expression.value)
        string_builder:push(').first')
    end,
    Second = function (string_builder, expression, context)
        string_builder:push('(')
        compile_expression(string_builder, expression.value)
        string_builder:push(').second')
    end,
    Print = function (string_builder, expression, context)
        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        string_builder:push('print(')
        compile_expression(string_builder, expression.value)
        string_builder:push(')')
    end,
    Bool = function (string_builder, expression, context)
        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        return string_builder:push(tostring(expression.value))
    end
}

function compile_expression (string_builder, expression, context)
    local compiler_by_kind = compile_expression_by_kind[expression.kind]

    if (compiler_by_kind) then
        return compiler_by_kind(string_builder, expression, context)
    end

    return string_builder:push('[not implemented]')
end

function compile_script (script)
    local string_builder = new_string_builder(
[[
local ffi = require("ffi")
local ffi_new, INTERNAL_MEMOIZATION_TABLE, print = ffi.new, {}, function (...)
    print(unpack({...}))
    return unpack({...})
end
ffi.cdef("typedef struct { int32_t first, second; } INTERNAL_INTEGER_PAIR;")
]]
    )

    compile_expression(string_builder, script.expression, {})

    return string_builder:get()
end

return compile_script