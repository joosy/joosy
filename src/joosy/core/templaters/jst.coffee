#= require joosy/core/joosy

#
# JST template precompilation binding
#
class Joosy.Templaters.JST
  constructor: (applicationName) ->
    if Object.isString(applicationName) && applicationName.length > 0
      @applicationName = applicationName

  #
  # Gets template lambda by its full name
  #
  # @param [String] name      Template name 'foo/bar'
  #
  buildView: (name) ->
    template = false

    if @applicationName
      haystack = [
        "#{@applicationName}/templates/#{name}-#{I18n?.locale}",
        "#{@applicationName}/templates/#{name}"
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