@Base = require '../base' if module?

class ProjectBase extends @Base
  constructor: (name, destination, templates) ->
    super(destination, templates)
    @name = name.split('/').pop()

  generate: ->
    @file ['resources', '.gitkeep']
    @file ['widgets', '.gitkeep']

    @copy ['application', 'base', 'routes.coffee'],                    ['routes.coffee']
    @copy ['application', 'base', 'helpers', 'application.coffee'],    ['helpers', 'application.coffee']
    @copy ['application', 'base', 'layouts', 'application.coffee'],    ['layouts', 'application.coffee']
    @copy ['application', 'base', 'pages', 'application.coffee'],      ['pages', 'application.coffee']
    @copy ['application', 'base', 'pages', 'welcome', 'index.coffee'], ['pages', 'welcome', 'index.coffee']

    @copy ['application', 'base', 'templates', 'layouts', 'application.jst.hamlc'],
                                 ['templates', 'layouts', 'application.jst.hamlc']

    @copy ['application', 'base', 'templates', 'pages', 'welcome', 'index.jst.hamlc'],
                                 ['templates', 'pages', 'welcome', 'index.jst.hamlc']


    @template ['application', 'base', 'application.coffee'], ['application.coffee'],
      application: @name

    @actions

if module?
  module.exports = ProjectBase
else
  @Generator = ProjectBase