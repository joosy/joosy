#= require joosy/core/joosy

class Joosy.Templaters.RailsJST
  constructor: (@applicationName) ->

  buildView: (name) ->
    template = JST[location = "#{@applicationName}/templates/#{name}"]

    unless template
      throw new Error "Template '#{name}' not found. Checked at: #{location}"

    template

  resolveTemplate: (section, template, entity) ->
    if template.startsWith '/'
      return template.substr 1

    path = entity.constructor?.__namespace__?.map('underscore') || []
    path.unshift section

    "#{path.join '/'}/#{template}"
