Mincer = require 'mincer'

module.exports = (grunt) ->

  grunt.registerMultiTask 'mince', ->
    Mincer.CoffeeEngine.configure bare: false
    environment = new Mincer.Environment
    environment.appendPath x for x in @data.include
    grunt.file.write @data.dest, environment.findAsset(@data.src).toString()

  grunt.registerTask 'bowerize', ->
    bower = require './bower.json'
    meta  = require './package.json'

    bower.version = meta.version
    grunt.file.write 'bower.json', JSON.stringify(bower, null, 2)