#= require joosy/joosy

#
# JST template precompilation binding
#
class Joosy.Templaters.JST
  constructor: (@config={}) ->
    @prefix = @config.prefix if @config.prefix? && @config.prefix.length > 0

  #
  # Gets template lambda by its full name
  #
  # @param [String] name      Template name 'foo/bar'
  #
  buildView: (name) ->
    template = false

    if @prefix
      haystack = [
        "#{@prefix}/templates/#{name}-#{I18n?.locale}",
        "#{@prefix}/templates/#{name}"
      ]
    else
      haystack = [
        "templates/#{name}-#{I18n?.locale}",
        "templates/#{name}"
      ]

    for path in haystack 
      return window.JST[path] if window.JST[path]

    throw new Error "Template '#{name}' not found. Checked at: '#{haystack.join(', ')}'"

  #
  # Gets full name of template by several params
  #
  # @param [String] section     Section of templates like pages/layouts/...
  # @param [String] template    Internal template path
  # @param [String] entity      Entity to lookup template path by its namespace
  #
  resolveTemplate: (section, template, entity) ->
    if template.startsWith '/'
      return template.substr 1

    path = entity.constructor?.__namespace__?.map('underscore') || []
    path.unshift section

    "#{path.join '/'}/#{template}"

# AMD wrapper
if define?.amd?
  define 'joosy/templaters/jst', -> Joosy.Templaters.JST