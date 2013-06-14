Generator = require './generator'

module.exports = class extends Generator
  @generate: (name) -> (new @(name)).generate()

  constructor: (@name, destination, templates) ->
    super(destination, templates)

  files: ->
    namespace = @getNamespace @name
    basename  = @getBasename @name

    [
      @join @destination, 'layouts', @join(namespace...), "#{basename}.coffee"
      @join @destination, 'templates', 'layouts', @join(namespace...), "#{basename}.jst.hamlc"
    ]

  generate: (skip) ->
    return false unless @exists(@destination)

    namespace = @getNamespace(@name)

    files    = @files()
    template = if namespace.length > 0 then 'namespaced' else 'basic'

    @template ['layout', "#{template}.coffee"], files[0],
      namespace_name: namespace.map (x) -> x.camelize()
      class_name: @getBasename(@name).camelize()
      view_name: @name

    @file files[1]

    @actions