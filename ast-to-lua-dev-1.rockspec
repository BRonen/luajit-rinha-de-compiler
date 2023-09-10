package = "ast-to-lua"
version = "dev-1"
source = {
   url = "git+https://github.com/BRonen/luajit-rinha-de-compiler.git"
}
description = {
   homepage = "https://github.com/BRonen/luajit-rinha-de-compiler",
   license = MIT
}
build = {
   type = "builtin",
   modules = {
      init = "init.lua"
   }
}
