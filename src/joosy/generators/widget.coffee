@Base = require './base' if module?

#
# Possible options:
#
#   name: name of widget including namespace (i.e. 'foo/bar/baz')
#
class Widget extends @Base
  generate: ->
    namespace = @getNamespace @options.name
    basename  = @getBasename @options.name
    template  = if namespace.length > 0 then 'namespaced' else 'basic'

    @template ['widget', "#{template}.coffee"], ['widgets', @join(namespace...), "#{basename}.coffee"],
      namespace_name: (@camelize(x) for x in namespace).join('.')
      class_name: @camelize(basename)
      view_name: basename

    @file ['templates', 'widgets', @join(namespace...), "#{basename}.jst.hamlc"]

    @actions

if module?
  module.exports = Widget
else
  @Generator = Widget