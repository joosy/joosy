module.exports = ->
  Sugar = require 'sugar'
  cli   = require 'command-router'
  meta  = require '../../../../package.json'
  grunt = require 'grunt'
  path  = require 'path'

  generators = ['page', 'resource', 'widget', 'layout']

  cli.command /help\s?(.*)/, ->
    name = cli.params.splats[0]

    commands = ['new', 'generate']

    if  name == ''
      console.log "Usage: `help :command`. Possible values: #{commands.join(', ')}"
      process.exit 1

    unless  commands.some(name)
      console.error "Unknown command '#{name}'. Possible values: #{commands.join(', ')}."
      process.exit 1

    generator = require('./help')
    generator = new generator()
    generator[name]()

  cli.command /new\s?(.*)?/, ->
    name = cli.params.splats[0]

    unless name?
      console.error "Usage: `new :name`. Run `help` for details."
      process.exit(1)

    generator = require('../project')
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

    generator = require("../#{entity}")
    generator = new generator({name: name}, path.join(process.cwd(), 'source'))
    generator.generate()
    generator.perform -> process.exit 0

  cli.command 'help', ->
    console.log '\t\t\t     __________________________'
    console.log '\t\t\t    /_    ____ ____ ____ __ __/'
    console.log '\t\t\t   __/  /    /    / ___/  /  /'
    console.log '\t\t\t  / /  / /  /  / /__  /  /  /'
    console.log '\t\t\t /____/____/____/____/__   /'
    console.log '\t\t\t/_________________________/\n'
    console.log 'Usage: joosy COMMAND [ARGS]\n'
    console.log 'Available commands are: \n'
    console.log '  generate    Insert new entity in the application (short-cut alias "g")'
    console.log '  new         Create a new application\n'
    console.log 'Help is also available on per-command basis, use appropriate argument, Luke'

  cli.on 'notfound', (action) ->
    if action.length > 0
      console.error "'#{action}' is an unknown action :("
    else
      console.log "Joosy #{meta.version}. Run `help` to list possible commands."

  cli.parse process.argv