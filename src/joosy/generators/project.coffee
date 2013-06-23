Standalone = require './project/standalone'
Base       = require './project/base'

module.exports = class
  constructor: (@name) ->
    @standalone = new Standalone(@name)
    @base       = new Base(@name, @standalone.destination)

  generate: ->
    @standalone.generate()
    @base.generate()

  perform: (callback) ->
    @standalone.perform =>
      @base.perform =>
        callback()