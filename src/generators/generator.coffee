File      = require('grunt').file
Path      = require('path')
EJS       = require('ejs')
Commander = require('commander')
colors    = require('colors')

module.exports = class
  constructor: (destination, templates) ->
    @templates   = templates || @join(__dirname, '..', '..', 'templates')
    @destination = @join (destination || process.cwd()), 'source'
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

  performFileAction: (callback, destination, content) ->
    write = =>
      File.write(@join(@destination, destination), content)
      console.log "#{destination} created...".green

    if File.exists(@destination, destination)
      Commander.confirm "#{destination} exists. Overwrite? ", (y) ->
        write() if y
        callback()
    else
      write()
      callback()
      
  performTemplateAction: -> @performFileAction arguments...