Generator = require './generator'

module.exports = class extends Generator
  constructor: (@name, destination, templates) ->
    super(destination, templates)

  generate: (skip) ->
    namespace = @getNamespace @name
    basename  = @getBasename @name
    template  = if namespace.length > 0 then 'namespaced' else 'basic'

    @template ['page', "#{template}.coffee"], ['pages', @join(namespace...), "#{basename}.coffee"],
      namespace_name: namespace.map (x) -> x.camelize()
      class_name: basename.camelize()
      view_name: basename

    @file ['templates', 'pages', @join(namespace...), "#{basename}.jst.hamlc"]

    @actions