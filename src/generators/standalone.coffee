Generator = require './generator'

module.exports = class extends Generator
  constructor: (@name, destination, templates) ->
    super(destination, templates)

  generate: (skip) ->
    @file ['public', '.gitkeep']
    @file ['vendor', '.gitkeep']
    @file ['stylesheet', 'application.styl']

    @copy ['application', 'standalone', '.gitignore'],           ['.gitignore']
    @copy ['application', 'standalone', 'bower.json'],           ['bower.json']
    @copy ['application', 'standalone', 'Gruntfile.coffee'],     ['Gruntfile.coffee']
    @copy ['application', 'standalone', 'package.json'],         ['package.json']
    @copy ['application', 'standalone', 'Procfile'],             ['Procfile']
    @copy ['application', 'standalone', 'source', 'index.haml'], ['source', 'index.haml']