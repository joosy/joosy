Sugar     = require 'sugar'
Generator = require './generator'
Path      = require 'path'

module.exports = class extends Generator
  @generate: (name) -> (new @(name)).generate()

  constructor: (@name, destination, templates) ->
    @templates   = templates   || Path.join(__dirname, '..', '..', 'templates')
    @destination = Path.join (destination || process.cwd()), 'source'
  
  generate: ->
    return false unless @exists(@destination)

    namespace = @getNamespace @name
    basename  = @getBasename @name

    @template ['page', 'basic.coffee'], ['pages', Path.join(namespace...), "#{basename}.coffee"],
      namespace_name: namespace.map (x) -> x.camelize()
      class_name: basename.camelize()
      view_name: @name

    @file ['templates', 'pages', Path.join(namespace...), "#{basename}.jst.hamlc"]

    true