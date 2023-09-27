function tprint (tbl, indent)
    if not indent then indent = 0 end
    
    for k, v in pairs(tbl) do
        formatting = string.rep("    ", indent) .. k .. ": "
    
        if type(v) == "table" then
            
            print(formatting .. "{")
            tprint(v, indent+1)
            print(string.rep("    ", indent) .. "},")
            
        elseif type(v) == "string" then
            print(formatting .. '"' .. tostring(v) .. "\",")
        else
            print(formatting .. tostring(v) .. ",")
        end
    end
end

return tprint