Standalone = require './project/standalone'
Base       = require './project/base'
Path       = require 'path'

module.exports = class
  constructor: (@options) ->
    @options.dependencies = """
                            #= require jquery/jquery.js
                            #= require jquery-form/jquery.form.js
                            #= require sugar/release/sugar-full.min.js
                            """

    @standalone = new Standalone(@options)
    @base       = new Base(@options, Path.join(@standalone.destination, 'source'))

  generate: ->
    @standalone.generate()
    @base.generate()

  perform: (callback) ->
    @standalone.perform =>
      @base.perform =>
        callback()