@Base = require './base' if module?

#
# Possible options:
#
#   name: name of page including namespace (i.e. 'foo/bar/baz')
#
class Page extends @Base
  generate: ->
    namespace = @getNamespace @options.name
    basename  = @getBasename @options.name
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