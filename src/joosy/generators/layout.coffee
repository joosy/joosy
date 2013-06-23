@Base = require './base' if module?

#
# Possible options:
#
#   name: name of layout including namespace (i.e. 'foo/bar/baz')
#
class Layout extends @Base
  generate: ->
    namespace = @getNamespace @options.name
    basename  = @getBasename @options.name
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