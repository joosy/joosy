#= require joosy/core/joosy

class Joosy.Templaters.RailsJST
  constructor: (@applicationName) ->

  buildView: (name) ->
    template = JST[location = "#{@applicationName}/templates/#{name}"]

    unless template
      throw new Error "Template '#{name}' not found. Checked at: #{location}"

    template
    
  resolve: (section, template, entity=false) ->
    if entity
      resolvePartial section, template, entity
    else
      resolveTemplate section, template
        
  resolveTemplate: (section, template) ->
    "#{section}/#{template}"
    
  resolvePartial: (section, template, entity) ->
    entity   = entity.constructor.__namespace__.map 'underscore'
    template = template.split "/"
    file     = path.pop()
    
    "#{section}/#{entity.join('/')}/#{template.join('/')}/_#{file}"