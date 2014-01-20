#= require joosy/joosy

#
# JST template precompilation binding
#
class Joosy.Templaters.JST
  #
  # Initializes JST templater
  #
  constructor: (@config={}) ->
    @prefix = @config.prefix if @config.prefix? && @config.prefix.length > 0
    @locale = @config.locale if @config.locale? && @config.locale.length > 0

  #
  # Gets template lambda by its full name
  #
  # @param [String] name      Template name 'foo/bar'
  #
  buildView: (name) ->
    template = false

    if window.JST[name]
      return window.JST[name]

    if @locale && window.JST["#{name}-#{@locale}"]
      return window.JST["#{name}-#{@locale}"]

    if @prefix
      if @locale && window.JST["#{@prefix}/templates/#{name}-#{@locale}"]
        return window.JST["#{@prefix}/templates/#{name}-#{@locale}"]

      if window.JST["#{@prefix}/templates/#{name}"]
        return window.JST["#{@prefix}/templates/#{name}"]
    else
      if @locale && window.JST["templates/#{name}-#{@locale}"]
        return window.JST["templates/#{name}-#{@locale}"]

      if window.JST["templates/#{name}"]
        return window.JST["templates/#{name}"]

    throw new Error "Template '#{name}' not found. Checked at: '#{haystack.join(', ')}'"

  #
  # Gets full name of template by several params
  #
  # @param [String] section     Section of templates like pages/layouts/...
  # @param [String] template    Internal template path
  # @param [String] entity      Entity to lookup template path by its namespace
  #
  resolveTemplate: (section, template, entity) ->
    if template[0] == '/'
      return template.substr 1

    path = entity.constructor?.__namespace__?.map (x) -> inflection.underscore(x)
    path ||= []
    path.unshift section

    "#{path.join '/'}/#{template}"

# AMD wrapper
if define?.amd?
  define 'joosy/templaters/jst', -> Joosy.Templaters.JST