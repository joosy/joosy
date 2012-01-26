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

  resolvePartial: (section, template, entity) ->
    return template.substr 1 if template.startsWith '/'

    entity   = entity.constructor.__namespace__.map 'underscore'
    template = template.split "/"
    file     = path.pop()

    "#{section}/#{entity.join('/')}/#{template.join('/')}/_#{file}"