#= require joosy/core/joosy

class Joosy.Templaters.RailsJST
  constructor: (@applicationName) ->

  buildView: (name) ->
    template = JST[location = "#{@applicationName}/templates/#{name}"]

    unless template
      throw new Error "Template '#{name}' not found. Checked at: #{location}"

    template

  resolveTemplate: (section, template) ->
    return template.substr 1 if template.startsWith '/'

    "#{section}/#{template}"

  resolvePageTemplate: (section, template, entity) ->
    return template.substr 1 if template.startsWith '/'

    if template.indexOf("/") == -1
      path = entity.constructor.__namespace__.map 'underscore'
      path.unshift(section)

      "#{path.join('/')}/#{template}"
    else
      "#{section}/#{template}"