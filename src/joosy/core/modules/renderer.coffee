#= require joosy/core/joosy
#= require_tree ../templaters
#= require vendor/metamorph

#
# Core DOM rendering mechanics
#
# @mixin
# @todo           Describe this scary thing o_O
#
Joosy.Modules.Renderer =

  #
  # Default behavior for non-set renderer (empty template?)
  #
  __renderer: ->
    throw new Error "#{Joosy.Module.__className @constructor} does not have an attached template"

  __helpers: null

  #
  # Defines class-level helpers: @view and @helpers
  #
  # View (@view): Sets the curent template by specifying its name or lambda
  # Helpers (@helpers): Lists set of helpers' namespaces to include
  #
  included: ->
    @view = (template, options={}) ->
      if Object.isFunction template
        @::__renderer = template
      else
        @::__renderer = (locals={}) ->
          if options.dynamic
            @renderDynamic template, locals
          else
            @render template, locals

    @helpers = (helpers...) ->
      @::__helpers ||= []
      helpers.map (helper) =>
        module = Joosy.Helpers[helper]
        unless module
          throw new Error "Cannot find helper module #{helper}"

        @::__helpers.push module

      @::__helpers = @::__helpers.unique()

  render: (template, locals={}, parentStackPointer=false) ->
    @__render false, template, locals, parentStackPointer

  renderDynamic: (template, locals={}, parentStackPointer=false) ->
    @__render true, template, locals, parentStackPointer

  __instantiateHelpers: ->
    unless @__helpersInstance
      @__helpersInstance = Object.extended Joosy.Helpers.Application
      @__helpersInstance.__owner = @

      if @__helpers
        for helper in @__helpers
          Joosy.Module.merge @__helpersInstance, helper

    @__helpersInstance

  __instantiateRenderers: (stack) ->
    render: (template, locals={}) =>
      @render template, locals, stack
    renderDynamic: (template, locals={}) =>
      @renderDynamic template, locals, stack
    renderInline: (locals={}, template) =>
      @renderDynamic template, locals, stack

  __render: (dynamic, template, locals={}, parentStackPointer=false) ->
    stack = @__renderingStackChildFor parentStackPointer

    stack.template = template
    stack.locals   = locals

    # If template was given as a lambda, parameters should
    # be passed as a context, not as an argument
    assignContext = false

    if Object.isString template
      if @__renderSection?
        template = Joosy.Application.templater.resolveTemplate @__renderSection(), template, this

      template = Joosy.Application.templater.buildView template
    else if Object.isFunction template
      assignContext = true
    else if !Object.isFunction template
      throw new Error "#{Joosy.Module.__className @}> template (maybe @view) does not look like a string or lambda"

    if !Object.isObject(locals) && Object.extended().constructor != locals.constructor
      throw new Error "#{Joosy.Module.__className @}> locals (maybe @data?) is not a hash"

    context = =>
      data = {}

      Joosy.Module.merge data, stack.locals
      Joosy.Module.merge data, @__instantiateHelpers(), false
      Joosy.Module.merge data, @__instantiateRenderers(stack)
      data

    result = ->
      if assignContext
        template.call(context())
      else
        template(context())

    if dynamic
      morph  = Metamorph result()
      update = =>
        if morph.isRemoved()
          for [object, binding] in morph.__bindings
            object.unbind binding
        else
          for child in stack.children
            @__removeMetamorphs child
          stack.children = []
          morph.html result()

      # This is here to break stack tree and save from
      # repeating DOM handling
      update = update.debounce 0

      for key, object of locals
        if locals.hasOwnProperty key
          if object?.bind? && object?.unbind?
            binding = [object, object.bind('changed', update)]
            stack.metamorphBindings.push binding

      morph.__bindings = stack.metamorphBindings

      morph.outerHTML()
    else
      result()

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
      element = @__renderingStackElement parentPointer
      parentPointer.children.push element
      element

  __removeMetamorphs: (stackPointer=false) ->
    remove = (stackPointer) =>
      if stackPointer?.children
        for child in stackPointer.children
          @__removeMetamorphs child

      if stackPointer?.metamorphBindings
        for [object, callback] in stackPointer.metamorphBindings
          object.unbind callback
        stackPointer.metamorphBindings = []

    unless stackPointer
      @__renderingStack?.each (stackPointer) ->
        remove stackPointer
    else
      remove stackPointer
