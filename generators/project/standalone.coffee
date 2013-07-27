@Base = require '../base' if module?

#
# Possible options:
#
#   name: name of project
#
class ProjectStandalone extends @Base
  constructor: (@options, destination, templates) ->
    destination = @join process.cwd(), @options.name  if !destination? && process?
    super(@options, destination, templates)

  generate: ->
    @file ['public', '.gitkeep']
    @file ['vendor', '.gitkeep']

    @copy ['application', 'standalone', '_gitignore'],           ['.gitignore']
    @copy ['application', 'standalone', 'bower.json'],           ['bower.json']
    @copy ['application', 'standalone', 'Gruntfile.coffee'],     ['Gruntfile.coffee']
    @copy ['application', 'standalone', 'Procfile'],             ['Procfile']

    @copy ['application', 'standalone', 'source', 'haml', 'index.haml'], 
                                       ['source', 'haml', 'index.haml']

    @copy ['application', 'standalone', 'source', 'stylesheets', 'application.styl'],
                                       ['source', 'stylesheets', 'application.styl']

    @template ['application', 'standalone', 'package.json'], ['package.json'],
      joosy_version: @version()

    @actions

if module?
  module.exports = ProjectStandalone
else
  @Generator = ProjectStandalone