local compile_binary_operators = {
    Add = function (string_builder, expression, compile_term)
        string_builder:push('INTERNAL_GLOBAL_ADD_OPERATOR( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(', ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    Sub = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' - ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    Mul = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' * ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    Div = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' / ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    Rem = function (string_builder, expression, compile_term)
        string_builder:push('math.fmod( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(', ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    Eq = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' == ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    Neq = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' ~= ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    Lt = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' < ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    Gt = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' > ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    Lte = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' <= ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    Gte = function (string_builder, expression, compile_term)
        string_builder:push('( ')
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' >= ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
        return string_builder:push(' )')
    end,
    And = function (string_builder, expression, compile_term)
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' and ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
    end,
    Or = function (string_builder, expression, compile_term)
        compile_term(string_builder, expression.lhs, {is_variable = true})
        string_builder:push(' or ')
        compile_term(string_builder, expression.rhs, {is_variable = true})
    end
}

local binary_operators = {
    Add = {'INTERNAL_GLOBAL_ADD_OPERATOR(', ', ', ')'},
    Sub = {'(', '-', ')'},
    Mul = {'(', '*', ')'},
    Div = {'(', '/', ')'},
    Rem = {'math.fmod(', ', ', ')'},
    Eq = {'(', '==', ')'},
    Neq = {'(', '~=', ')'},
    Lt = {'(', '<', ')'},
    Gt = {'(', '>', ')'},
    Lte = {'(', '<=', ')'},
    Gte = {'(', '>=', ')'},
    And = {'', 'and', ''},
    Or = {'', 'or', ''}
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