function new_string_builder(initial_string)
    local string_builder = {
        buffer = { initial_string }
    }

    function string_builder:push(str)
        if(type(str) == 'table') then
            for _, v in ipairs(str) do
                table.insert(self.buffer, v)
            end
        else
            table.insert(self.buffer, str)
        end

        return self
    end

    function string_builder:get()
        return table.concat(self.buffer, '')
    end

    return string_builder
end

return new_string_builder