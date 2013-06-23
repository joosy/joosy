Generator = require './generator'

module.exports = class extends Generator
  constructor: (@name, destination, templates) ->
    super(destination, templates)

  generate: (skip) ->
    namespace = @getNamespace @name
    basename  = @getBasename @name
    template  = if namespace.length > 0 then 'namespaced' else 'basic'

    @template ['layout', "#{template}.coffee"], ['layouts', @join(namespace...), "#{basename}.coffee"],
      namespace_name: namespace.map (x) -> x.camelize()
      class_name: basename.camelize()
      view_name: basename

    @file ['templates', 'layouts', @join(namespace...), "#{basename}.jst.hamlc"]

    @actions