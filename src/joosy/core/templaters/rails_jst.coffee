#= require joosy/core/joosy

#
# Rails JST template precompilation binding
#
class Joosy.Templaters.RailsJST
  constructor: (@applicationName) ->

  #
  # Gets template lambda by its full name
  #
  # @param [String] name      Template name 'foo/bar'
  #
  buildView: (name) ->
    template = false
    haystack = [
      "#{@applicationName}/templates/#{name}-#{I18n?.locale}",
      "#{@applicationName}/templates/#{name}",
      "templates/#{name}-#{I18n?.locale}",
      "templates/#{name}"
    ]

    haystack.each (path) ->
      if JST[path]
        location = path
        template = JST[path]

    unless template
      throw new Error "Template '#{name}' not found. Checked at: #{location}"

    template

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
