@Base = require './base' if module?

class Page extends @Base
  constructor: (@name, destination, templates) ->
    super(destination, templates)
    @destination = @join @destination, 'source'

  generate: ->
    namespace = @getNamespace @name
    basename  = @getBasename @name
    template  = if namespace.length > 0 then 'namespaced' else 'basic'

    @template ['page', "#{template}.coffee"], ['pages', @join(namespace...), "#{basename}.coffee"],
      namespace_name: (@camelize(x) for x in namespace).join('.')
      class_name: @camelize(basename)
      view_name: basename

    @file ['templates', 'pages', @join(namespace...), "#{basename}.jst.hamlc"]

    @actions

if module?
  module.exports = Page
else
  @Generator = Page