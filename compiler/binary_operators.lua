local compile_binary_operators = {
    Add = function (string_builder, expression)
        string_builder:push('( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(
            (expression.lhs.kind == 'Str' or expression.rhs.kind == 'Str') and ' .. ' or ' + '
        )
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Sub = function (string_builder, expression)
        string_builder:push('( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' - ')
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Mul = function (string_builder, expression)
        string_builder:push('( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' * ')
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Div = function (string_builder, expression)
        string_builder:push('( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' / ')
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Rem = function (string_builder, expression)
        string_builder:push('math.fmod( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(', ')
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Eq = function (string_builder, expression)
        string_builder:push('( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' == ')
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Neq = function (string_builder, expression)
        string_builder:push('( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' ~= ')
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Lt = function (string_builder, expression)
        string_builder:push('( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' < ')
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Gt = function (string_builder, expression)
        string_builder:push('( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' > ')
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Lte = function (string_builder, expression)
        string_builder:push('( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' <= ')
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Gte = function (string_builder, expression)
        string_builder:push('( ')
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' >= ')
        compile_expression(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    And = function (string_builder, expression)
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' and ')
        compile_expression(string_builder, expression.rhs)
    end,
    Or = function (string_builder, expression)
        compile_expression(string_builder, expression.lhs)
        string_builder:push(' or ')
        compile_expression(string_builder, expression.rhs)
    end
}

return compile_binary_operators