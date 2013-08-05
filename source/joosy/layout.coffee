#= require joosy/joosy
#= require joosy/widget
#= require joosy/helpers/view

#
# Base class for all Joosy Layouts.
#
# @example Sample application layout
#   class @ApplicationLayout extends Joosy.Layout
#     @view 'application'
#
class Joosy.Layout extends Joosy.Widget
  @helper 'page'

  #
  # @param [Hash] params              Route params
  # @param [Joosy.Layout] previous    Layout to replace on load
  #
  constructor: (@params, @previous) ->
    @uid = Joosy.uid()

  #
  # Helper that outputs container tag for the page
  #
  # @param [String]  name             Tag name
  # @param [Object]  options          Tag attributes
  #
  page: (tag, options={}) ->
    options.id = @uid
    Joosy.Helpers.Application.tag tag, options

  #
  # Gets DOM element that should be used as container for nested Page
  #
  # @return [jQuery]
  #
  content: ->
    $("##{@uid}")

  ######
  ###### Widget extensions
  ######

  #
  # This is required by {Joosy.Modules.Renderer}
  # Sets the base template dir to app_name/templates/layouts
  #
  __renderSection: ->
    'layouts'

  #
  # Extends list of registered nested widgets with page
  #
  __nestingMap: (page) ->
    map = super()
    map["##{@uid}"] =
      instance: page
      nested: page.__nestingMap()

    map

  #
  # Adds page as first argument to default bootstrap
  #
  # @param [Joosy.Page] page                  Page to inject
  # @param [jQuery] applicationContainer      The base container for the application to paint at
  #
  __bootstrapDefault: (page, applicationContainer) ->
    @__bootstrap @__nestingMap(page), applicationContainer

# AMD wrapper
if define?.amd?
  define 'joosy/layout', -> Joosy.Layout
