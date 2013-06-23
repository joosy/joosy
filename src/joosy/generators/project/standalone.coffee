meta      = require '../../../../package.json'
Generator = require '../generator'

module.exports = class extends Generator
  constructor: (@name, destination, templates) ->
    destination = @join (destination || process.cwd()), @name unless destination?
    super(destination, templates)

  generate: ->
    @file ['public', '.gitkeep']
    @file ['vendor', '.gitkeep']

    @copy ['application', 'standalone', '.gitignore'],           ['.gitignore']
    @copy ['application', 'standalone', 'bower.json'],           ['bower.json']
    @copy ['application', 'standalone', 'Gruntfile.coffee'],     ['Gruntfile.coffee']
    @copy ['application', 'standalone', 'Procfile'],             ['Procfile']
    @copy ['application', 'standalone', 'source', 'index.haml'], ['source', 'index.haml']

    @copy ['application', 'standalone', 'stylesheets', 'application.styl'],
                                       ['stylesheets', 'application.styl']

    @template ['application', 'standalone', 'package.json'], ['package.json'],
      joosy_version: meta.version

    @actions