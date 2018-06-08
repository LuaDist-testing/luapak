#!/usr/bin/env lua
local luapak = require 'luapak.init'
local log = require 'luapak.logging'
local optparse = require 'luapak.optparse'
local utils = require 'luapak.utils'

local shallow_clone = utils.shallow_clone

local commands = {
  ['analyse-deps'] = 'analyse_deps',
  ['build-rock'] = 'build_rock',
  ['make'] = 'make',
  ['wrapper'] = 'wrapper',
}


local optparser = optparse([[
luapak ${VERSION}

Usage: ${PROGRAM} COMMAND [args]
       ${PROGRAM} (--help | --version)

Commands:
  make              Make a standalone executable for the specified Lua program. This is the main
                    Luapak command that do everything what is needed.

  analyse-deps      Analyse requirements of Lua sources.

  build-rock        Build and install Lua rock from local rockspec and sources.

  wrapper           Generate C wrapper for Lua program.

Options:
  -q, --quiet       Be quiet, i.e. print only errors.
  -v, --verbose     Be verbose, i.e. print debug messages.
  -h, --help        Display this help message and exit. Note that every command has its own --help.
  -V, --version     Display version information and exit.
]], { VERSION = luapak._VERSION })

optparser:on('--help', function (_, arglist, i)
  if not commands[arglist[1]] then
    optparser:help()
  end
  return i + 1
end)

local args, opts = optparser:parse(arg)

if opts.verbose then
  log.threshold = log.DEBUG
elseif opts.quiet then
  log.threshold = log.ERROR
end

local command = args[1]
if not command then
  optparser:opterr('No command specified')
elseif not commands[command] then
  optparser:opterr('Unknown command: '..command)
end

local module = require('luapak.cli.'..commands[command])

local arg = shallow_clone(_G.arg)
table.remove(arg, 1)

local ok, err = pcall(module, arg)
if not ok then
  if not opts.verbose then
    err = err:gsub('^[^:]+:[^:]+:%s*', '')  -- remove location info
  end
  log.error('%s', err)
  os.exit(1)
end