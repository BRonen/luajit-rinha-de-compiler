function compile_recursive_function(string_builder, expression, context)
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
    elseif (expression.kind == 'Binary') then
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
    elseif (expression.kind == 'Var') then
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
        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        return string_builder:push(expression.value)
    elseif (expression.kind == 'Call') then
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
    elseif (expression.kind == 'Str') then
        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        return string_builder:push({'"', expression.value, '"'})
    elseif (expression.kind == 'Tuple') then
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
    elseif (expression.kind == 'First') then
        string_builder:push('(')
        compile_expression(string_builder, expression.value)
        string_builder:push(').first')
    elseif (expression.kind == 'Second') then
        string_builder:push('(')
        compile_expression(string_builder, expression.value)
        string_builder:push(').second')
    elseif (expression.kind == 'Print') then
        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        string_builder:push('print(')
        compile_expression(string_builder, expression.value)
        string_builder:push(')')
    elseif (expression.kind == 'Bool') then
        if(context and context.is_returning) then string_builder:push('\nreturn ') end

        return string_builder:push(tostring(expression.value))
    end
end

return compile_recursive_function