File = require('grunt').file
Path = require('path')
EJS  = require('ejs')

module.exports = class
  constructor: (destination, templates) ->
    @templates   = templates || Path.join(__dirname, '..', '..', 'templates')
    @destination = Path.join (destination || process.cwd()), 'source'
    @actions     = []

  getNamespace: (name) ->
    name = name.split('/')
    name.pop()
    name

  getBasename: (name) ->
    name = name.split('/')
    name.pop()

  join: ->
    Path.join arguments...

  exists: ->
    File.exists arguments...

  template: (source, destination, data) ->
    source = Path.join(@templates, source...) if source instanceof Array
    destination = Path.join(@destination, destination...) if destination instanceof Array

    result = EJS.render File.read(source), data
    File.write destination, result

    @actions.push ['template', destination]

  file: (destination) ->
    destination = Path.join(@destination, destination...) if destination instanceof Array
    File.write(destination, '')

    @actions.push ['file', destination]

  mkdir: ->
    File.mkdir Path.join(arguments...)