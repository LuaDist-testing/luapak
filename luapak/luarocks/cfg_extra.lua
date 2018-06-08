local cfg = require 'luarocks.cfg'

local fmt = string.format
local getenv = os.getenv
local MSVC = cfg.is_platform('win32') and not cfg.is_platform('mingw32')

if not cfg.shared_lib_extension then
  cfg.shared_lib_extension = cfg.lib_extension
end

if not cfg.static_lib_extension then
  cfg.static_lib_extension = MSVC and 'lib' or 'a'
end

if not cfg.variables.AR then
  cfg.variables.AR = MSVC and 'lib' or 'ar'
end

if not cfg.variables.RANLIB then
  cfg.variables.RANLIB = 'ranlib'
end

if not cfg.variables.STRIP then
  cfg.variables.STRIP = 'strip'
end

-- LUALIB for MSVC is already defined in cfg.lua.
if not cfg.variables.LUALIB and not MSVC then
  cfg.variables.LUALIB = fmt('liblua%s.%s', cfg.lua_version:gsub('%.', ''),
                                            cfg.lib_extension)
end

-- Allow to override specified variables from environment.
for _, name in ipairs {
  'AR', 'CC', 'CMAKE', 'CFLAGS', 'LD', 'LDFLAGS', 'MAKE', 'RANLIB', 'STRIP'
} do
  local value = getenv(name)
  if value then
    cfg.variables[name] = value
  end
end

return cfg
