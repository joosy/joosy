#= require_tree ../templaters
#= require metamorph

Joosy.Modules.Renderer =

  __renderer: ->
    throw new Error "#{@constructor.name} does not have an attached template"

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

      @__helpersInstance.render = =>
        @render(arguments...)

      if @__helpers
        for helper in @__helpers
          @__helpersInstance.merge helper

    @__helpersInstance

  render: (template, locals={}) ->
    if Object.isString template
      if @__renderSection?
        template = Joosy.Application.templater.resolveTemplate @__renderSection(), template, this

      template = Joosy.Application.templater.buildView template
    else if !Object.isFunction(template)
      throw new Error "#{Joosy.Module.__className__ @}> template (maybe @view) does not look like a string or lambda"

    if !Object.isObject locals
      throw new Error "#{Joosy.Module.__className__ @}> locals (maybe @data?) can only be dumb hash"

    locals.prototype = locals.__proto__ = @__instantiateHelpers()

    morph = Metamorph template(locals)

    update = =>
      morph.html template(locals)

    @__metamorphs ||= []

    for key, object of locals
      if locals.hasOwnProperty key
        if object?.bind? && object?.unbind?
          object.bind 'changed', update
          @__metamorphs.push [object, update]

    morph.outerHTML()

  __removeMetamorphs: ->
    if @__metamorphs
      for [object, callback] in @__metamorphs
        object.unbind callback