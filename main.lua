--require('./test')()

loadstring(
    require('./compiler/compile_script')(
        require(
            './compiler/get_file_contents'
        )(
            '/var/rinha/source.rinha.json'
        )
    ):gsub("%nil", "INTERNAL_OVERRIDE_nil")
)()

-- file = io.open("output.lua", "w")
-- io.output(file)
-- io.write(compile_script(ast_json))
-- io.close(file)
