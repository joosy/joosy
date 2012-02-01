#= require_tree ../templaters
#= require metamorph

Joosy.Modules.Renderer =

  __renderer: ->
    throw new Error "#{@constructor.name} does not have an attached template"

  __helpers: null

  included: ->
    @view = (template, options={}) ->
      if Object.isFunction(template)
        @::__renderer = template
      else
        @::__renderer = (locals={}) ->
          if options.dynamic
            @renderDynamic(template, locals)
          else
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
        
      @__helpersInstance.widget = (element, widget) =>
        @widgets ||= {}
        
        uuid    = Joosy.uuid()
        element = document.createElement(element)
        temp    = document.createElement("div")
        
        element.id = uuid
        @widgets['#'+uuid] = widget

        temp.appendChild(element)
        temp.innerHTML

      if @__helpers
        for helper in @__helpers
          Object.merge @__helpersInstance, helper

    @__helpersInstance

  # If we do not have __proto__ available...
  __proxifyHelpers: (locals) ->
    if locals.hasOwnProperty '__proto__'
      locals.__proto__ = @__instantiateHelpers()
      locals
    else
      unless @__helpersProxyInstance
        @__helpersProxyInstance = (locals) ->
          Object.merge this, locals

        @__helpersProxyInstance.prototype = @__instantiateHelpers()

      new @__helpersProxyInstance(locals)

  render: (template, locals={}, parentStackPointer=false) ->
    @__render false, template, locals, parentStackPointer
    
  renderDynamic: (template, locals={}, parentStackPointer=false) ->
    @__render true, template, locals, parentStackPointer

  __render: (dynamic, template, locals={}, parentStackPointer=false) ->
    stack = @__renderingStackChildFor(parentStackPointer)
    
    stack.template = template
    
    isResource   = Joosy.Module.hasAncestor(locals.constructor, Joosy.Resource.Generic)
    isCollection = Joosy.Module.hasAncestor(locals.constructor, Joosy.Resource.GenericCollection)
    
    if Object.isString template
      if @__renderSection?
        template = Joosy.Application.templater.resolveTemplate @__renderSection(), template, this

      template = Joosy.Application.templater.buildView template
    else if !Object.isFunction(template)
      throw new Error "#{Joosy.Module.__className__ @}> template (maybe @view) does not look like a string or lambda"

    if !Object.isObject(locals) && !isResource && !isCollection
      throw new Error "#{Joosy.Module.__className__ @}> locals (maybe @data?) not in: dumb hash, Resource, Collection"

    if isCollection
      stack.locals = @__proxifyHelpers {data: locals.data}
    else if isResource
      stack.locals = locals.e = @__proxifyHelpers(locals.e)
    else
      stack.locals = locals = @__proxifyHelpers(locals)
      
    if !stack.locals.render
      stack.locals.render = (template, locals={}) =>
        @render(template, locals, stack)
        
    if !stack.locals.renderDynamic
      stack.locals.renderDynamic = (template, locals={}) =>
        @renderDynamic(template, locals, stack)
    
    if dynamic
      morph  = Metamorph template(stack.locals)
      update = =>
        @__removeMetamorphs(child) for child in stack.children
        stack.children = []
        morph.html template(stack.locals)
        @refreshElements?()

      # This is here to break stack tree and save from 
      # repeating DOM handling
      update = update.debounce(0)

      if isCollection
        for resource in locals.data
          resource.bind 'changed', update
          stack.metamorphBindings.push [resource, update]
      if isResource || isCollection
        locals.bind 'changed', update
        stack.metamorphBindings.push [locals, update]
      else
        for key, object of locals
          if locals.hasOwnProperty key
            if object?.bind? && object?.unbind?
              object.bind 'changed', update
              stack.metamorphBindings.push [object, update]

      morph.outerHTML()
    else
      template(stack.locals)

  __renderingStackElement: (parent=null) ->
    metamorphBindings: []
    locals: null
    template: null
    children: []
    parent: parent

  __renderingStackChildFor: (parentPointer) ->
    if !@__renderingStack
      @__renderingStack = []
    
    if !parentPointer
      element = @__renderingStackElement()
      @__renderingStack.push element
      element
    else
      element = @__renderingStackElement(parentPointer)
      parentPointer.children.push element
      element

  __removeMetamorphs: (stackPointer=false) ->
    unless stackPointer
      @__renderingStack.each (stackPointer) =>
        if stackPointer?.children
          for child in stackPointer.children
            @__removeMetamorphs(child)
    
        if stackPointer?.metamorphBindings
          for [object, callback] in stackPointer.metamorphBindings
            object.unbind callback
          stackPointer.metamorphBindings = []