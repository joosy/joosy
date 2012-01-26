#= require_tree ../templaters
#= require metamorph

Joosy.Modules.Renderer =

  __renderer: (locals={}) ->
    @render(null, locals)

  __helpers: null

  included: ->
    @view = (template) ->
      if Object.isFunction(template)
        @::__renderer = template
      else
        @::__renderer = (locals={}) ->
          @render(template, locals)

    @helpers = (helpers...) ->
      @::__helpers ||= []
      helpers.map (helper) =>
        module = Joosy.Helpers[helper]
        unless module
          throw new Error "Cannot find helper module #{helper}"

        @::__helpers.push module

      @::__helpers = @::__helpers.unique()

  __instantiateHelpers: ->
    unless @__helpersInstance
      @__helpersInstance = Object.extended Joosy.Helpers.Global

      if @__helpers
        for helper in @__helpers
          @__helpersInstance.merge helper

    @__helpersInstance

  render: (template, locals) ->
  #   locals = locals.merge
  #     render: (template, locals) =>
  #       @__implicitlyRenderPartial template, locals
  # 
  #   @__implicitlyRenderPage template, locals
  # 
  # __explicitlyRender: (template, locals) ->
    if Object.isString template
      template = Joosy.Application.templater.buildView template
    else if !Object.isFunction(template)
      throw new Error "#{@constructor.name}> template (maybe @view) does not look like a string or lambda"

    if !Object.isObject locals
      throw new Error "#{@constructor.name}> locals (maybe @data?) can only be dumb hash"

    locals.__proto__ = @__instantiateHelpers()

    morph = Metamorph template(locals)

    update = =>
      morph.html template(locals)

    @__metamorphs ||= []

    for key, object of locals
      if object.bind?
        object.bind 'changed', update
        @__metamorphs.push [object, update]

    morph.outerHTML()

  __implicitlyRenderPage: (template, locals) ->
    @__explicitlyRender @__resolveTemplate(template, false), locals

  __implicitlyRenderPartial: (template, locals) ->
    @__explicitlyRender @__resolveTemplate(template, true), locals

  __resolveTemplate: (template, isPartial) ->
    if Object.isFunction template
      return template

    if template
      if !Object.isString template
        throw new Error "template should either be string or function"

      path = template.split "/"
      file = path.pop()
    else
      path = []
      file = null

    if path.length == 0
      path = @constructor.__namespace__.map 'underscore'

    path.unshift "pages"

    if file == null
      file = @constructor.name.underscore()

    if isPartial
      "#{path.join "/"}/_#{file}"
    else
      "#{path.join "/"}/#{file}"

  __removeMetamorphs: ->
    if @__metamorphs
      for [object, callback] in @__metamorphs
        object.unbind callback