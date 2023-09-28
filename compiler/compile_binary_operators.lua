local tprint = require('./debug')

local compile_binary_operators = {
    Add = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(
            (expression.lhs.kind == 'Str' or expression.rhs.kind == 'Str') and ' .. ' or ' + '
        )
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Sub = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(' - ')
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Mul = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(' * ')
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Div = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(' / ')
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Rem = function (string_builder, expression, compile_term)
        string_builder:push('math.fmod( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(', ')
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Eq = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(' == ')
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Neq = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(' ~= ')
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Lt = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(' < ')
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Gt = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(' > ')
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Lte = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(' <= ')
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    Gte = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs)
        string_builder:push(' >= ')
        compile_term(string_builder, expression.rhs)
        return string_builder:push(' )')
    end,
    And = function (string_builder, expression, compile_term)
        compile_term(string_builder, expression.lhs)
        string_builder:push(' and ')
        compile_term(string_builder, expression.rhs)
    end,
    Or = function (string_builder, expression, compile_term)
        compile_term(string_builder, expression.lhs)
        string_builder:push(' or ')
        compile_term(string_builder, expression.rhs)
    end
}

local binary_operators = {
    Add = '+',
    Sub = '-',
    Mul = '*',
    Div = '/',
    Eq = '==',
    Neq = '~=',
    Lt = '<',
    Gt = '>',
    Lte = '<=',
    Gte = '>=',
    And = 'and',
    Or = 'or'
}

function build_binary_operators (string_builder, operator, left, right, compile_term)
    tprint({ lhs = left, rhs = right })
    return compile_binary_operators[operator](string_builder, { lhs = left, rhs = right }, compile_term)
end

return {
    compile_binary_operators = compile_binary_operators,
    build_binary_operators = build_binary_operators,
    binary_operators = binary_operators
}