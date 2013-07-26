#= require joosy/core/joosy
#= require_tree ../templaters
#= require vendor/metamorph

#
# Core DOM rendering mechanics
#
# @mixin
#
Joosy.Modules.Renderer =

  #
  # Default behavior for non-set view (empty template?)
  #
  __renderDefault: ->
    throw new Error "#{Joosy.Module.__className @constructor} does not have an attached template"

  #
  # Defines class-level helpers: @view and @helpers
  #
  # View (@view): Sets the curent template by specifying its name or lambda
  # Helpers (@helpers): Lists set of helpers' namespaces to include
  #
  included: ->
    @view = (template, options={}) ->
      @::__renderDefault = (locals={}) ->
        if options.dynamic
          @renderDynamic template, locals
        else
          @render template, locals

    @helper = (helpers...) ->
      unless @::hasOwnProperty "__helpers"
        @::__helpers = @.__super__.__helpers?.clone() || []

      @::__helpers = @::__helpers.add(helpers).unique()
      @::__helpers = @::__helpers.unique()

  #
  # Renders given template with given locals
  #
  # @param [String] template              Name of the template to render using templater
  # @param [Function] template            `(locals) ->` lambda to use as template
  # @param [Object] locals                Locals to assign
  # @param [Object] parentStackPointer    Internal rendering stack pointer
  #
  render: (template, locals={}, parentStackPointer=false) ->
    @__render false, template, locals, parentStackPointer

  #
  # Dynamically renders given template with given locals
  #
  # Whenever any of assigned locals triggers `changed` event, DOM will automatically be refreshed
  #
  # @param [String] template              Name of the template to render using templater
  # @param [Function] template            `(locals) ->` lambda to use as template
  # @param [Object] locals                Locals to assign
  # @param [Object] parentStackPointer    Internal rendering stack pointer
  #
  renderDynamic: (template, locals={}, parentStackPointer=false) ->
    @__render true, template, locals, parentStackPointer

  #
  # Converts all possible `@helper` arguments to the objects available for merge
  #
  __assignHelpers: ->
    return unless @__helpers?
  
    unless @hasOwnProperty "__helpers"
      @__helpers = @__helpers.clone()

    @__helpers.each (helper, i) =>
      unless Object.isObject(helper)
        unless @[helper]?
          throw new Error "Cannot find method '#{helper}' to use as helper"

        @__helpers[i] = {}
        @__helpers[i][helper] = => @[helper] arguments...

  #
  # Collects and merges all requested helpers including global scope to one cached object
  #
  __instantiateHelpers: ->
    unless @__helpersInstance
      @__assignHelpers()

      @__helpersInstance = Object.extended Joosy.Helpers.Application
      @__helpersInstance.__renderer = @

      if @__helpers
        for helper in @__helpers
          Joosy.Module.merge @__helpersInstance, helper

    @__helpersInstance

  #
  # Defines local `@render*` methods with proper stack pointer set
  #
  # @param [Object] parentStackPointer        Internal rendering stack pointer
  #
  __instantiateRenderers: (parentStackPointer) ->
    render: (template, locals={}) =>
      @render template, locals, parentStackPointer
    renderDynamic: (template, locals={}) =>
      @renderDynamic template, locals, parentStackPointer
    renderInline: (locals={}, template) =>
      @renderDynamic template, locals, parentStackPointer

  #
  # Actual rendering implementation
  #
  __render: (dynamic, template, locals={}, parentStackPointer=false) ->
    stack = @__renderingStackChildFor parentStackPointer

    stack.template = template
    stack.locals   = locals

    if Object.isString template
      if @__renderSection?
        template = Joosy.Application.templater.resolveTemplate @__renderSection(), template, this
      template = Joosy.Application.templater.buildView template
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
      # repeating DOM modification
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

  #
  # Template for the rendering stack node
  #
  __renderingStackElement: (parent=null) ->
    metamorphBindings: []
    locals: null
    template: null
    children: []
    parent: parent

  #
  # Creates new rendering stack node using given pointer as the parent
  #
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

  #
  # Disables and unbinds all dynamic bindings for the whole rendering stack
  #
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

# AMD wrapper
if define?.amd?
  define 'joosy/modules/renderer', -> Joosy.Modules.Renderer
