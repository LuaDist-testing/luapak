---------
-- Lua library finder.
----
local fs = require 'luapak.fs'
local luarocks = require 'luapak.luarocks.init'
local utils = require 'luapak.utils'

local fmt = string.format
local insert = table.insert
local is_file = fs.is_file
local popen = io.popen
local read_file = fs.read_file
local starts_with = utils.starts_with


local include_dirs = {
  luarocks.get_variable('LUA_INCDIR') or '',
  'vendor/lua', 'deps/lua', '/usr/local/include', '/usr/include'
}
local liblua_dirs = {
  luarocks.get_variable('LUA_LIBDIR') or '',
  'vendor/lua', 'deps/lua', '/usr/local/lib', '/usr/local/lib64', '/usr/lib', '/usr/lib64'
}

local M = {}

--- Reads version number from the given `lua.h` file.
--
-- @tparam string filename Path of the `lua.h` file.
-- @treturn[1] string Version number in format `x.y`.
-- @treturn[2] nil
-- @treturn[2] string An error message.
function M.luah_version (filename)
  local content, err = read_file(filename)
  if not content then
    return nil, err
  end

  local major, minor = content:match('#define%s+LUA_VERSION_NUM%s+(%d)0(%d)')
  if not major or not minor then
    return nil, 'LUA_VERSION_NUM not found in '..filename
  end

  return major..'.'..minor
end
local luah_version = M.luah_version

--- Reads version number of the given Lua library.
--
-- This function uses command `strings` to determine the version number.
-- It works for both static and dynamic library on Linux and macOS.
--
-- @tparam string filename Path of the Lua library.
-- @treturn[1] string Version number in format `x.y`.
-- @treturn[2] nil
-- @treturn[2] string An error message.
function M.lualib_version (filename)
  if not is_file(filename) then
    return nil, 'file does not exist or not readable: '..filename
  end

  local handler, err = popen('strings -n 4 '..filename)
  if not handler then
    return nil, err
  end

  local ver
  for line in handler:lines() do
    if starts_with('Lua 5.', line) then
      ver = line:match('Lua (5%.%d+)')
      break
    end
  end

  handler:close()
  return ver
end
local lualib_version = M.lualib_version

--- Looking for a directory containing `lua.h` in common locations.
--
-- @tparam string lua_ver Version of the `lua.h` file to search for.
-- @treturn[1] string File path of the found directory.
-- @treturn[1] string Version of the found `lua.h` file in format `x.y`.
-- @treturn[2] nil Not found.
function M.find_incdir (lua_ver)
  local suffixes = lua_ver ~= nil
      and { '', '/lua'..lua_ver, '/lua-'..lua_ver }
      or { '' }

  for _, dir in ipairs(include_dirs) do
    for _, suffix in ipairs(suffixes) do
      local path = dir..suffix
      local ver = luah_version(path..'/lua.h')

      if ver and (lua_ver == nil or lua_ver == ver) then
        return path, ver
      end
    end
  end
end

--- Looking for Lua library in common locations.
--
-- @tparam string lib_ext File extension of the library to search for.
-- @tparam ?string lua_ver Version of the Lua library to search for, or nil to
--   search for any version.
-- @treturn[1] string File path of the found Lua library.
-- @treturn[1] string Version of the found Lua library in format `x.y`.
-- @treturn[2] nil Not found.
function M.find_liblua (lib_ext, lua_ver)
  local libnames = lua_ver ~= nil
      and { 'liblua', 'liblua'..lua_ver, 'liblua.'..lua_ver, 'lua'..lua_ver..'/liblua' }
      or { 'liblua' }

  local lualib = luarocks.get_variable('LUALIB')
  if lualib then
    insert(libnames, 1, (lualib:gsub('%.%w+$', '')))  -- strip file extension
  end

  for _, dir in ipairs(liblua_dirs) do
    for _, libname in ipairs(libnames) do
      local path = fmt('%s/%s.%s', dir, libname, lib_ext)
      local ver = lualib_version(path)

      if ver and (lua_ver == nil or lua_ver == ver) then
        return path, ver
      end
    end
  end
end

return M
