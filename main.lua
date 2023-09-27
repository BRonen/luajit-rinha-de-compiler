local module = require('./compiler/compile_script')

local fib_json = module.get_file_contents('./tests/closures.json')

print(module.compile_script(fib_json))

loadstring(module.compile_script(fib_json))()
