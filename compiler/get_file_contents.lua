function get_file_contents (path)
    local file = io.open(path, "r")
    
    local content = ''
    
    for line in io.lines(path) do
        content = content .. line
    end
    
    file:close()
    
    return require("cjson").decode(content);
end

return get_file_contents