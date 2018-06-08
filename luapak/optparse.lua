---------
-- Wrapper for the optparse module with some customizations.
--
-- **Note: This module is not part of public API!**
----
local OptionParser = require 'optparse'
local luapak = require 'luapak.init'

local FOOTER = string.format('Please report bugs at <%s/issues>.', luapak._HOMEPAGE)


--- Creates parser of command-line options from the given help message.
--
-- @function __call
-- @tparam string help_msg The help message to parse.
-- @tparam ?table vars The table of variables for substitutions in `help_msg`.
return function (help_msg, vars)
  vars = vars or {}
  vars['PROGRAM'] = _G.arg[0]
  help_msg = help_msg:gsub('%${(%w+)}', vars)..'\n'..FOOTER

  local parser = OptionParser(help_msg)
  parser:on('--', parser.finished)

  return parser
end
