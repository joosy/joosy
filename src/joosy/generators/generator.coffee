File      = require('grunt').file
Log       = require('grunt').log
Path      = require('path')
EJS       = require('ejs')
Commander = require('commander')

module.exports = class
  constructor: (destination, templates) ->
    @destination = destination || process.cwd()
    @templates   = templates || @join(__dirname, '..', '..', '..', 'templates')
    @actions     = []

  getNamespace: (name) ->
    name = name.split('/')
    name.pop()
    name

  getBasename: (name) ->
    name = name.split('/')
    name.pop()

  template: (source, destination, data) ->
    source = @join(@templates, source...) if source instanceof Array
    destination = @join(destination...) if destination instanceof Array

    result = @compileTemplate source, data

    @actions.push ['template', destination, result]

  file: (destination, content='') ->
    destination = @join(destination...) if destination instanceof Array

    @actions.push ['file', destination, content]

  copy: (source, destination) ->
    source = @join(@templates, source...) if source instanceof Array
    destination = @join(destination...) if destination instanceof Array

    @actions.push ['copy', destination, source]

  #
  # Required but Node-only methods
  #
  join: ->
    Path.join arguments...

  compileTemplate: (source, data) ->
    EJS.render File.read(source), data

  #
  # Node-base performer
  #
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
      File.copy source, @join(@destination, destination)
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
      
  performTemplateAction: -> @performFileAction arguments...