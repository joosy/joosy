module.exports = ->
  Sugar = require 'sugar'
  cli   = require 'command-router'
  meta  = require '../package.json'
  grunt = require 'grunt'
  path  = require 'path'

  cli.command /new\s?(.*)?/, ->
    name = cli.params.splats[0]

    unless name?
      console.error "Usage: `new :name`. Run `help` for details."
      process.exit(1)

    generator = require('./project')
    generator = new generator(name: name)
    generator.generate()
    generator.perform -> process.exit 0

  cli.command /g(enerate)?\s?(.*)/, ->
    params = cli.params.splats[1].split(' ')
    entity = params[0]
    name   = params[1]

    generators = ['page', 'resource', 'widget', 'layout']

    if !entity? || !name?
      console.error "Usage: `generate :entity :name`. Run `help` for details."
      process.exit 1

    unless generators.some(entity)
      console.error "Don't know how to generate '#{entity}'. Possible values: #{generators.join(', ')}."
      process.exit 1

    unless grunt.file.exists(process.cwd(), 'source')
      console.error "Failed: `source' directory not found. Are you in the root of project?"
      process.exit 1

    generator = require("./#{entity}")
    generator = new generator({name: name}, path.join(process.cwd(), 'source'))
    generator.generate()
    generator.perform -> process.exit 0

  cli.on 'notfound', (action) ->
    if action.length > 0
      console.error "'#{action}' is an unknown action :("
    else
      console.log "Joosy #{meta.version}. Run `help` to list possible commands."

  cli.parse process.argv