local module = require('compile_script')

local fib_json = module.get_file_contents('/var/rinha/source.rinha.json')

-- print(module.compile_script(fib_json))

loadstring(module.compile_script(fib_json))()
