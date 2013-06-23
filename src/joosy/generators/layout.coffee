@Base = require './base' if module?

class Layout extends @Base
  constructor: (@name, destination, templates) ->
    super(destination, templates)

  generate: ->
    namespace = @getNamespace @name
    basename  = @getBasename @name
    template  = if namespace.length > 0 then 'namespaced' else 'basic'

    @template ['layout', "#{template}.coffee"], ['layouts', @join(namespace...), "#{basename}.coffee"],
      namespace_name: (@camelize(x) for x in namespace).join('.')
      class_name: @camelize(basename)
      view_name: basename

    @file ['templates', 'layouts', @join(namespace...), "#{basename}.jst.hamlc"]

    @actions

if module?
  module.exports = Layout
else
  @Generator = Layout