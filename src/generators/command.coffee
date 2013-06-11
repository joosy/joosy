module.exports = ->
  Sugar = require 'sugar'
  cli   = require 'command-router'
  meta  = require '../../package.json'

  cli.command /new\s?(.*)?/, ->
    name = cli.params.splats[0]

    unless name?
      console.error "Usage: `new :name`. Run `help` for details."
      process.exit(1)

    require('./project').generate name

  cli.command /generate\s?(.*)/, ->
    params = cli.params.splats[0].split(' ')
    entity = params[0]
    name   = params[1]

    generators = ['page', 'resource', 'widget', 'layout']

    if !entity? || !name?
      console.error "Usage: `generate :entity :name`. Run `help` for details."
      process.exit 1

    unless generators.some(entity)
      console.error "Don't know how to generate '#{entity}'. Possible values: #{generators.join(', ')}."
      process.exit 1

    require("./#{entity}").generate name

  cli.on 'notfound', (action) ->
    if action.length > 0
      console.error "'#{action}' is an unknown action :("
    else
      console.log "Joosy #{meta.version}. Run `help` to list possible commands."

  cli.parse process.argv