Standalone = require './project/standalone'
Base       = require './project/base'
Path       = require 'path'

module.exports = class
  constructor: (@name) ->
    @standalone = new Standalone(@name)
    @base       = new Base(@name, Path.join(@standalone.destination, 'source'))

  generate: ->
    @standalone.generate()
    @base.generate()

  perform: (callback) ->
    @standalone.perform =>
      @base.perform =>
        callback()