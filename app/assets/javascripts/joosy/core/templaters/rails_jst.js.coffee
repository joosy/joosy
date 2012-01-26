#= require joosy/core/joosy

class Joosy.Templaters.RailsJST
  constructor: (@applicationName) ->

  buildView: (name) ->
    template = JST[location = "#{@applicationName}/templates/#{name}"]

    unless template
      throw new Error "Template '#{name}' not found. Checked at: #{location}"

    template