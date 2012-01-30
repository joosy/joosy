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
      @__helpersInstance = Object.extended Joosy.Helpers.Application

      @__helpersInstance.render = =>
        @render(arguments...)
        
      @__helpersInstance.widget = (element, widget) =>
        @widgets ||= {}
        
        uuid    = Joosy.uuid()
        element = document.createElement(element)
        temp    = document.createElement("div")
        
        element.id     = uuid
        @widgets['#'+uuid] = widget

        temp.appendChild(element)
        temp.innerHTML

      if @__helpers
        for helper in @__helpers
          @__helpersInstance.merge helper

    @__helpersInstance

  # If we do not have __proto__ available...
  __proxifyHelpers: (locals) ->
    if locals.hasOwnProperty '__proto__'
      locals.__proto__ = @__instantiateHelpers()

      locals
    else
      unless @__helpersProxyInstance
        @__helpersProxyInstance = (locals) ->
          Object.merge(this, locals)

        @__helpersProxyInstance.prototype = @__instantiateHelpers()

      new @__helpersProxyInstance(locals)

  render: (template, locals={}) ->
    if Object.isString template
      if @__renderSection?
        template = Joosy.Application.templater.resolveTemplate @__renderSection(), template, this

      template = Joosy.Application.templater.buildView template
    else if !Object.isFunction(template)
      throw new Error "#{Joosy.Module.__className__ @}> template (maybe @view) does not look like a string or lambda"

    if !Object.isObject(locals) && !Joosy.Module.hasAncestor(locals.__resource, Joosy.Resource.Generic)
      throw new Error "#{Joosy.Module.__className__ @}> locals (maybe @data?) can only be dumb hash or Resource"

    if Joosy.Module.hasAncestor(locals.__resource, Joosy.Resource.Generic)
      binding = locals
      locals  = locals.e

    locals = @__proxifyHelpers(locals)

    morph = Metamorph template(locals)

    update = =>
      morph.html template(locals)

    @__metamorphs ||= []

    if binding
      binding.bind 'changed', update
    else
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