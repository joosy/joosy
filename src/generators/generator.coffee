File = require('grunt').file
Path = require('path')
EJS  = require('ejs')

module.exports = class
  getNamespace: (name) ->
    name = name.split('/')
    name.pop()
    name

  getBasename: (name) ->
    name = name.split('/')
    name.pop()

  exists: ->
    File.exists(arguments...)

  template: (source, destination, data) ->
    source = Path.join(@templates, source...) if source instanceof Array
    destination = Path.join(@destination, destination...) if destination instanceof Array

    result = EJS.render File.read(source), data
    File.write destination, result

  file: (destination) ->
    destination = Path.join(@destination, destination...) if destination instanceof Array
    File.write(destination, '')

  mkdir: ->
    File.mkdir Path.join(arguments...)