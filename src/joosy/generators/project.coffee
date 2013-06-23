Standalone = require './project/standalone'
Base       = require './project/base'
Path       = require 'path'

module.exports = class
  constructor: (@options) ->
    @standalone = new Standalone(@options)
    @base       = new Base(@options, Path.join(@standalone.destination, 'source'))

  generate: ->
    @standalone.generate()
    @base.generate()

  perform: (callback) ->
    @standalone.perform =>
      @base.perform =>
        callback()