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
    @copy ['application', 'standalone', 'Gruntfile.coffee'],     ['Gruntfile.coffee']
    @copy ['application', 'standalone', 'Procfile'],             ['Procfile']

    @copy ['application', 'standalone', 'app', 'haml', 'index.haml'],
                                       ['app', 'haml', 'index.haml']

    @copy ['application', 'standalone', 'app', 'stylesheets', 'application.styl'],
                                       ['app', 'stylesheets', 'application.styl']

    @file ['app', 'images', '.gitkeep']

    @file ['app', 'fonts', '.gitkeep']

    @copy ['application', 'standalone', 'tasks', 'spec.coffee'],
                                       ['tasks', 'spec.coffee']

    @copy ['application', 'standalone', 'spec', 'helpers', 'environment.coffee'],
                                       ['spec', 'helpers', 'environment.coffee']

    @copy ['application', 'standalone', 'spec', 'application_spec.coffee'],
                                       ['spec', 'application_spec.coffee']

    @template ['application', 'standalone', 'bower.json'],   ['bower.json'],
      application: @options.name

    @template ['application', 'standalone', 'package.json'], ['package.json'],
      joosy_version: @version()

    @actions

if module?
  module.exports = ProjectStandalone
else
  @Generator = ProjectStandalone
