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

function get_ast (path)
    local file = io.open(path, "r")
    
    local content = ''
    
    for line in io.lines(path) do
        content = content .. line
    end
    
    file:close()
    
    return require("cjson").decode(content).expression;
end

function map (tbl, f)
    local t = {}
    
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end

    return t
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

local compile_expression_by_kind = {
    Function = function (expression, args)
        local parameters = ''

        for k, v in ipairs(expression.parameters) do
            parameters = parameters .. v.text

            if (k ~= #expression.parameters) then
                parameters = parameters .. ', '
            end
        end

        return 'function ' .. args.name .. '(' .. parameters .. ')\n' .. compile_expression(expression.value) .. '\nend\n'
    end,
    Let = function (expression)
        if(expression.value.kind == 'Function') then
            return compile_expression(expression.value, {name = expression.name.text})
        end
        return 'local ' .. expression.name.text .. ' = ' .. compile_expression(expression.value) .. '\n'
    end,
    If = function (expression)
        local result = 'if (' .. compile_expression(expression.condition) .. ') then\n return ' .. compile_expression(expression['then'])

        if(expression.otherwise) then
            result = result .. '\nelse\n return ' .. compile_expression(expression.otherwise)
        end

        return result .. ' \nend'
    end,
    Binary = function (expression)
        return compile_binary_operators[expression.op](expression)
    end,
    Var = function (expression)
        return expression.text
    end,
    Int = function (expression)
        return expression.value
    end,
    Call = function (expression)
        local parameters = table.concat(map(expression.arguments, compile_expression), ', ')
        return compile_expression(expression.callee) .. '(' .. parameters .. ')'
    end,
    Str = function (expression)
        return '"' .. expression.value .. '"'
    end,
    Print = function (expression)
        return 'print(' .. compile_expression(expression.value) .. ')'
    end,
}

function compile_expression (expression, args)
    local next = expression.next and compile_expression(expression.next) or ''

    local compiler_by_kind = compile_expression_by_kind[expression.kind]

    if (compiler_by_kind) then
        return compiler_by_kind(expression, args) .. next
    end

    return '[]'
end

local fib_json = get_ast('/var/rinha/source.rinha.json')

print(compile_expression(fib_json))
