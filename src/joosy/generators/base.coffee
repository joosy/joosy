if module?
  File      = require('grunt').file
  Log       = require('grunt').log
  Path      = require('path')
  EJS       = require('ejs')
  Commander = require('commander')

class Base
  constructor: (@options, @destination, @templates) ->
    @destination ||= process?.cwd()
    @templates   ||= @join(__dirname, '..', '..', '..', 'templates') if __dirname?
    @actions       = []

  getNamespace: (name) ->
    name = name.split('/')
    name.pop()
    name

  getBasename: (name) ->
    name = name.split('/')
    name.pop()

  template: (source, destination, data) ->
    source = @join(source...) if source instanceof Array
    destination = @join(destination...) if destination instanceof Array

    @actions.push ['template', destination, source, data]

  file: (destination, content='') ->
    destination = @join(destination...) if destination instanceof Array

    @actions.push ['file', destination, content]

  copy: (source, destination) ->
    source = @join(source...) if source instanceof Array
    destination = @join(destination...) if destination instanceof Array

    @actions.push ['copy', destination, source]

  camelize: (string) ->
    parts = (part.charAt(0).toUpperCase() + part.substr(1) for part in string.split(/_|-/))
    parts.join ''

  join: ->
    if Path?
      Path.join arguments...
    else
      Array.prototype.slice.call(arguments, 0).join('/')

  #
  # Methods that have to be overrided outside of Node.js
  #
  version: ->
    require('../../../package.json').version

  #
  # Node-base performer
  #
  compileTemplate: (source, data) ->
    EJS.render File.read(source), data

  perform: (callback) ->
    actions = @actions.clone()
    @performAction actions.pop(), actions, callback

  performAction: (action, actions, callback) ->
    method = "perform#{action.shift().camelize()}Action"
    next   = =>
      if actions.length > 0
        @performAction(actions.pop(), actions, callback)
      else
        callback()

    @[method] next, action...

  performCopyAction: (callback, destination, source) ->
    write = =>
      File.copy @join(@templates, source), @join(@destination, destination)
      Log.ok "#{destination} copied..."

    if File.exists(@destination, destination)
      Commander.confirm "#{destination} exists. Overwrite? ", (y) ->
        write() if y
        callback()
    else
      write()
      callback()

  performFileAction: (callback, destination, content) ->
    write = =>
      File.write(@join(@destination, destination), content)
      Log.ok "#{destination} generated..."

    if File.exists(@destination, destination)
      Commander.confirm "#{destination} exists. Overwrite? ", (y) ->
        write() if y
        callback()
    else
      write()
      callback()
      
  performTemplateAction: (callback, destination, source, data) ->
    @performFileAction callback, destination, @compileTemplate(@join(@templates, source), data)

if module?
  module.exports = Base
else
  @Base = Base