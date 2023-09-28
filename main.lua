--[[
local run_tests = require('./test')

run_tests()
]]

local get_file_contents = require('./compiler/get_file_contents')
local compile_script = require('./compiler/compile_script')

local ast_json = get_file_contents('/var/rinha/source.rinha.json')

-- print(compile_script(ast_json))

loadstring(compile_script(ast_json))()