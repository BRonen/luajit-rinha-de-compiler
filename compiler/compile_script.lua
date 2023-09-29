local new_string_builder = require('../string_builder')
local compile_recursive_function = require('./compiler/compile_recursive_function')
local binary_operators_module = require('./compiler/compile_binary_operators')
local compile_binary_operators, binary_operators = binary_operators_module.compile_binary_operators, binary_operators_module.binary_operators

function merge_tables (fst, snd)
    local result = {}
    
    for k,v in pairs(fst) do result[k] = v end
    for k,v in pairs(snd) do result[k] = v end

    result.is_tail_recursive = fst.is_tail_recursive or snd.is_tail_recursive
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
            check_function_flags(expression['condition'], merge_tables(context, { is_returning = false })),
            check_function_flags(expression['then'], context)
        )

        if(expression.otherwise) then
            return merge_tables(flags, check_function_flags(expression['otherwise'], context))
        end

        return flags
    end

    if(expression.kind == 'Binary') then
        return merge_tables(
            check_function_flags(
                expression.lhs,
                merge_tables(
                    context,
                    { is_in_binary_operation = true, is_variable = true }
                )
            ),
            check_function_flags(
                expression.rhs,
                merge_tables(
                    context,
                    { is_in_binary_operation = true, is_variable = true }
                )
            )
        )
    end

    if(expression.kind == 'Let') then
        return check_function_flags(
            expression.value,
            merge_tables(
                context,
                { is_returning = false }
            )
        )
    end

    if(
        expression.kind == 'Call' and
        expression.callee.text == context.name and
        context.is_returning and
        context.is_in_binary_operation
    ) then
        local flags = { is_tail_recursive = true }

        for _, argument in ipairs(expression.arguments) do
            flags = merge_tables(flags, check_function_flags(argument, context))
        end

        return flags
    end
    
    return check_function_flags(expression.value, context)
end

function compile_function_parameters (string_builder, parameters, delimiter, is_concatenating)
    if(not parameters or #parameters == 0) then return string_builder end

    if(is_concatenating and #parameters ~= 0) then string_builder:push(' .. ') end

    local delimiter = delimiter or ''
    
    for k, v in ipairs(parameters) do
        if(is_concatenating) then
            string_builder:push("tostring(")
        end

        string_builder:push(v.text)
        
        if(is_concatenating) then
            string_builder:push(")")
        end        
        
        if (k ~= #parameters) then
            string_builder:push(delimiter)
        end
    end

    return string_builder
end

function compile_function(string_builder, expression, context)
    local parameters = expression.parameters
    local name = context.name

    local context = merge_tables(
        context,
        { parameters = parameters, is_returning = true }
    )

    local flags = check_function_flags(expression, context)
    
    local inner_context = merge_tables(context, flags)

    inner_context.is_pure = flags.is_pure ~= false

    string_builder:push('function ')
    if(name) then string_builder:push(name) end
    string_builder:push('(')
    compile_function_parameters(string_builder, parameters, ', ')
    string_builder:push(')\n')
    
    if(not inner_context.is_tail_recursive and inner_context.is_pure) then
        string_builder:push('if(INTERNAL_MEMOIZATION_TABLE["')
        string_builder:push(name)
        string_builder:push('"')

        compile_function_parameters(string_builder, parameters, ' .. "-" .. ', true)
        
        string_builder:push(']) then return INTERNAL_MEMOIZATION_TABLE["')
        string_builder:push(name)
        string_builder:push('"')

        compile_function_parameters(string_builder, parameters, ' .. "-" .. ', true)

        string_builder:push('] end\n\n')
    end


    if(inner_context.is_tail_recursive) then
        string_builder:push('function INTERNAL_INNER_FUNCTION_')
        string_builder:push(name)
        string_builder:push(' (')
        compile_function_parameters(string_builder, parameters, ', ')
        string_builder:push(', INTERNAL_CONTINUATION)\n')

        if(inner_context.is_pure) then
            string_builder:push('if(INTERNAL_MEMOIZATION_TABLE["INTERNAL_INNER_FUNCTION_')
            string_builder:push(name)
            string_builder:push('-"')

            compile_function_parameters(string_builder, parameters, ' .. "-" .. ', true)
            
            string_builder:push(']) then return INTERNAL_CONTINUATION(INTERNAL_MEMOIZATION_TABLE["INTERNAL_INNER_FUNCTION_')
            string_builder:push(name)
            string_builder:push('-"')

            compile_function_parameters(string_builder, parameters, ' .. "-" .. ', true)

            string_builder:push(']) end\n\n')
        end
    end
    
    compile_expression(string_builder, expression.value, inner_context)

    if(inner_context.is_tail_recursive) then
        string_builder:push({'\nend\nreturn INTERNAL_INNER_FUNCTION_', name, '('})
        compile_function_parameters(string_builder, parameters, ', ')
        return string_builder:push(', function(INTERNAL_X) return INTERNAL_X end)\nend\n')
    end

    return string_builder:push('\nend\n')
end

function compile_expression(string_builder, expression, context)
    if(expression.kind == 'Let') then
        local context = context or {}

        if(expression.value.kind == 'Function') then
            compile_function(string_builder, expression.value, merge_tables(context, {name = expression.name.text}))
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
    elseif (expression.kind == 'If') then
        if(context.is_variable) then
            compile_expression(string_builder, expression.condition, {is_variable = true})

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
        
        compile_expression(string_builder, expression.condition, {is_variable = true})

        string_builder:push(') then\n')

        compile_expression(string_builder, expression['then'], context)

        if(expression.otherwise) then
            string_builder:push('\nelse\n')

            compile_expression(string_builder, expression.otherwise, context)
        end

        return string_builder:push('\nend')
    elseif (expression.kind == 'Binary') then
        if(context and context.is_returning and context.is_tail_recursive ) then
            local last_operation = new_string_builder('return INTERNAL_CONTINUATION( ')

            local close_number = 0

            function parse_binary_term(expr, level)
                if(not expr) then return end

                if(expr.kind == 'Binary') then
                    if(expr.lhs.kind == 'Call' and expr.lhs.callee.text == context.name) then
                        string_builder:push('\nreturn ')
                        string_builder:push('INTERNAL_INNER_FUNCTION_')
                        string_builder:push(context.name)
                        string_builder:push('(')
                        close_number = close_number + 1
                    end

                    local operator_tokens = binary_operators[expr.op]
                    last_operation:push(operator_tokens[1])

                    parse_binary_term(expr.lhs, level * 1000)

                    last_operation:push(operator_tokens[2])

                    if(expr.rhs.kind == 'Call' and expr.rhs.callee.text == context.name) then
                        string_builder:push('\nreturn ')
                        string_builder:push('INTERNAL_INNER_FUNCTION_')
                        string_builder:push(context.name)
                        string_builder:push('(')
                        close_number = close_number + 1
                    end

                    parse_binary_term(expr.rhs, level + 1)
                    
                    last_operation:push(operator_tokens[3])

                    return
                end
                if(expr.kind == 'Call' and expr.callee.text == context.name) then
                    
                    for i, argument in ipairs(expr.arguments) do
                        compile_expression(string_builder, argument, {is_variable = true})
                        
                        if(i ~= #expr.arguments) then string_builder:push(', ') end
                    end
                    string_builder:push({', function(INTERNAL_CONTINUATION_RESULT_', level, ')\n'})

                    last_operation:push({' INTERNAL_CONTINUATION_RESULT_', level, ' '})
                        
                    if(context.is_pure) then
                        string_builder:push('INTERNAL_MEMOIZATION_TABLE["INTERNAL_INNER_FUNCTION_')
                        string_builder:push(context.name)
                        string_builder:push('-" .. ')

                        for i, argument in ipairs(expr.arguments) do
                            string_builder:push('tostring(')
                            compile_expression(string_builder, argument, {is_variable = true})
                            string_builder:push(')')
                            
                            if(i ~= #expr.arguments) then string_builder:push(' .. ') end
                        end

                        string_builder:push({
                            '] = ', 'INTERNAL_CONTINUATION_RESULT_', level, '\n'
                        })
                    end

                    return 
                end

                compile_expression(last_operation, expr, {})
            end

            parse_binary_term(expression, 1)

            string_builder:push({
                last_operation:get(),
                ')\n'
            })
            
            for i=1,close_number do
                string_builder:push('end)')
            end

            return
        end

        if(context and context.is_returning and context.is_pure) then
            string_builder:push('local INTERNAL_MEMOIZED_VALUE = ')

            compile_binary_operators[expression.op](string_builder, expression, compile_expression)

            string_builder:push('\nINTERNAL_MEMOIZATION_TABLE["')
            string_builder:push(context.name)
            string_builder:push('"')
            
            compile_function_parameters(string_builder, context.parameters, ' .. "-" .. ', true)
            
            return string_builder:push('] = INTERNAL_MEMOIZED_VALUE\nreturn INTERNAL_MEMOIZED_VALUE')
        end

        if(context and context.is_returning) then
            string_builder:push('\nreturn ')
        end
        
        return compile_binary_operators[expression.op](string_builder, expression, compile_expression)
    elseif (expression.kind == 'Var') then
        if(context and context.is_returning and context.is_tail_recursive) then
            return string_builder:push({'\nreturn INTERNAL_CONTINUATION(', expression.text, ')'})
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
    elseif (expression.kind == 'Int') then
        if(context and context.is_returning and context.is_tail_recursive) then
            return string_builder:push({'\nreturn INTERNAL_CONTINUATION(', expression.value, ')'})
        end

        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        return string_builder:push(expression.value)
    elseif (expression.kind == 'Call') then
        if(context and context.is_pure and context.is_returning) then
            string_builder:push('return ')

            compile_expression(string_builder, expression.callee, {is_variable = true})
            string_builder:push('(')
    
            for i, argument in ipairs(expression.arguments) do
                compile_expression(string_builder, argument, {is_variable = true})
    
                if(i ~= #expression.arguments) then string_builder:push(', ') end
            end
    
            return string_builder:push(')\n')
        end

        if(context and context.is_returning) then
            string_builder:push('\nreturn ')
        end

        compile_expression(string_builder, expression.callee, {is_variable = true})
        string_builder:push('(')

        for i, argument in ipairs(expression.arguments) do
            compile_expression(string_builder, argument, {is_variable = true})

            if(i ~= #expression.arguments) then string_builder:push(', ') end
        end

        return string_builder:push(')')
    elseif (expression.kind == 'Str') then
        if(context and context.is_returning and context.is_tail_recursive) then
            return string_builder:push({'\nreturn INTERNAL_CONTINUATION(', expression.value, ')'})
        end

        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        return string_builder:push({'"', expression.value, '"'})
    elseif (expression.kind == 'Tuple') then
        local begin, middle, final = '{ first = ', ', second = ', ' }'

        if(expression.first.kind == 'Int' and expression.second.kind == 'Int') then
            begin, middle, final = 'ffi_new("INTERNAL_INTEGER_PAIR", {', ', ', '})'
        end
        
        if(context and context.is_returning and context.is_tail_recursive) then
            string_builder:push('\nreturn INTERNAL_CONTINUATION(')
            string_builder:push(begin)
            compile_expression(string_builder, expression.first)
            string_builder:push(middle)
            compile_expression(string_builder, expression.second)
            string_builder:push(final)
            string_builder:push(')')
        end

        if(context and context.is_returning) then
            if(context.is_pure) then
                string_builder:push('local INTERNAL_MEMOIZED_VALUE = ')
                string_builder:push(begin)

                compile_expression(string_builder, expression.first, {is_variable = true})

                string_builder:push(middle)

                compile_expression(string_builder, expression.second, {is_variable = true})

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
        compile_expression(string_builder, expression.first, {is_variable = true})
        string_builder:push(middle)
        compile_expression(string_builder, expression.second, {is_variable = true})
        string_builder:push(final)
    elseif (expression.kind == 'First') then
        if(context and context.is_returning and context.is_tail_recursive) then
            string_builder:push('\nreturn INTERNAL_CONTINUATION( (')
            compile_expression(string_builder, expression.value, {is_variable = true})
            returnstring_builder:push(').first )')
        end

        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        string_builder:push('(')
        compile_expression(string_builder, expression.value, {is_variable = true})
        string_builder:push(').first')
    elseif (expression.kind == 'Second') then
        if(context and context.is_returning and context.is_tail_recursive) then
            string_builder:push('\nreturn INTERNAL_CONTINUATION( (')
            compile_expression(string_builder, expression.value, {is_variable = true})
            returnstring_builder:push(').second )')
        end

        if(context and context.is_returning) then string_builder:push('\nreturn ') end
        
        string_builder:push('(')
        compile_expression(string_builder, expression.value)
        string_builder:push(').second')
    elseif (expression.kind == 'Print') then
        if(context and context.is_returning and context.is_tail_recursive) then
            string_builder:push('\nreturn INTERNAL_CONTINUATION( print(')
            compile_expression(string_builder, expression.value, {is_variable = true})
            return string_builder:push(') )')
        end

        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        string_builder:push('print(')
        compile_expression(string_builder, expression.value, {is_variable = true})
        string_builder:push(')')
    elseif (expression.kind == 'Bool') then
        if(context and context.is_returning and context.is_tail_recursive) then
            string_builder:push('\nreturn INTERNAL_CONTINUATION( ')
            string_builder:push(tostring(expression.value))
            return string_builder:push(' )')
        end

        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        return string_builder:push(tostring(expression.value))
    end
end

function compile_script (script)
    local string_builder = new_string_builder(
[[
local ffi = require("ffi")
local ffi_new, INTERNAL_MEMOIZATION_TABLE, print, INTERNAL_GLOBAL_ADD_OPERATOR = ffi.new, {}, function (value)
    if(type(value) == 'Function') then
        print('<#Closure>')
    else
        print(value)
    end
    return value
end, function (x, y)
    if(type(x) ~= "number" or type(y) ~= "number") then
        return x .. y
    end
    return x + y
end
ffi.cdef("typedef struct { int32_t first, second; } INTERNAL_INTEGER_PAIR;")
]]
    )

    compile_expression(string_builder, script.expression, {})

    return string_builder:get()
end

return compile_script