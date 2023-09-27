local ffi = require('ffi')

local call_memoization = {}

ffi.cdef("typedef struct { int32_t first, second; } tuple_t;")

local function create_tuple(n, m)
  local tuple = ffi.new("tuple_t")
  tuple.first = n
  tuple.second = m
  return tuple
end

local function creating_structs(n)
  local tuples = {}
  local time, space = os.time(), collectgarbage('count')
  for i=1,n do
    table.insert(tuples, create_tuple(i, i*2))
  end
  print('using ffi structs', math.floor((collectgarbage('count') - space) / 1024) .. 'MB', os.time() - time .. 's')
end

local function creating_tables(n)
  local tuples = {}
  local time, space = os.time(), collectgarbage('count')
  for i=1,n do
    table.insert(tuples, {i, i*2})
  end
  print('using lua tables', math.floor((collectgarbage('count') - space) / 1024) .. 'MB', os.time() - time .. 's')
end

creating_structs(10000000)
collectgarbage("collect")
creating_tables(10000000)

--[[

With unsigned int8
[nix-shell:~/github/rinha]$ luajit ffi_perfomance_comparison.lua
using ffi structs       2740MB  3s
using lua tables        9416MB  6s

With unsigned int32
[nix-shell:~/github/rinha]$ luajit ffi_perfomance_comparison.lua
using ffi structs       3312MB  3s
using lua tables        9416MB  7s

With unsigned int64
[nix-shell:~/github/rinha]$ luajit ffi_perfomance_comparison.lua
using ffi structs       4075MB  4s
using lua tables        9416MB  6s

]]

local function create_number(n)
  local number = ffi.new("uint8_t", n)
  return number
end

local function creating_integer_list(n)
  local integers = {}
  local time, space = os.time(), collectgarbage('count')
  for i=1,n do
    table.insert(integers, create_number(i))
  end
  print('using ffi integers', math.floor((collectgarbage('count') - space) / 1024) .. 'MB', os.time() - time .. 's')
end

local function creating_number_list(n)
  local numbers = {}
  local time, space = os.time(), collectgarbage('count')
  for i=1,n do
    table.insert(numbers, i)
  end
  print('using lua numbers', math.floor((collectgarbage('count') - space) / 1024) .. 'MB', os.time() - time .. 's')
end

creating_integer_list(100000000)
collectgarbage("collect")
creating_number_list(100000000)
