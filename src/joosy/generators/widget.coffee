Generator = require './generator'

module.exports = class extends Generator
  constructor: (@name, destination, templates) ->
    super(destination, templates)
    @destination = @join @destination, 'source'

  generate: ->
    namespace = @getNamespace @name
    basename  = @getBasename @name
    template  = if namespace.length > 0 then 'namespaced' else 'basic'

    @template ['widget', "#{template}.coffee"], ['widgets', @join(namespace...), "#{basename}.coffee"],
      namespace_name: namespace.map (x) -> x.camelize()
      class_name: basename.camelize()
      view_name: basename

    @file ['templates', 'widgets', @join(namespace...), "#{basename}.jst.hamlc"]

    @actions