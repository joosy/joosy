class Joosy.Templaters.RailsJST
  constructor: (@applicationName) ->
    
  buildView: (name) ->
    JST["#{@applicationName}/templates/#{name}"]