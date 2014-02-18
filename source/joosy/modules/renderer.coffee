#= require vendor/metamorph
#= require joosy/joosy

#
# Core DOM rendering mechanics
#
# @mixin
#
Joosy.Modules.Renderer =

  ClassMethods:
    #
    # Sets the curent template by specifying its name or lambda
    #
    # @param [String] template
    # @param [Hash] options
    # @option options [Boolean] dynamic        Marks if the whole view should be rendered as a Dynamic one
    #
    view: (template, options={}) ->
      @::__view = template
      @::__renderDefault = (locals={}) ->
        if options.dynamic
          @renderDynamic template, locals
        else
          @render template, locals

    #
    # Lists set of helpers' namespaces to include
    #
    helper: (helpers...) ->
      unless @::hasOwnProperty "__helpers"
        @::__helpers = @.__super__.__helpers?.slice() || []

      @::__helpers = @::__helpers.concat(helpers).filter (value, i, array) ->
        array.indexOf(value) == i

  InstanceMethods:
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
    renderDynamic: (template, locals={}, callback, parentStackPointer=false) ->
      @__render (callback || true), template, locals, parentStackPointer

    #
    # Converts all possible `@helper` arguments to the objects available for merge
    #
    # @private
    #
    __assignHelpers: ->
      return unless @__helpers?

      unless @hasOwnProperty "__helpers"
        @__helpers = @__helpers.slice()

      for helper, i in @__helpers
        do (helper, i) =>
          unless helper.constructor == Object
            unless @[helper]?
              throw new Error "Cannot find method '#{helper}' to use as helper"

            @__helpers[i] = {}
            @__helpers[i][helper] = => @[helper] arguments...

    #
    # Collects and merges all requested helpers including global scope to one cached object
    #
    # @private
    #
    __instantiateHelpers: ->
      unless @__helpersInstance
        @__assignHelpers()

        @__helpersInstance = {}
        @__helpersInstance.__renderer = @

        Joosy.Module.merge @__helpersInstance, Joosy.Helpers.Application
        Joosy.Module.merge @__helpersInstance, Joosy.Helpers.Routes if Joosy.Helpers.Routes?

        if @__helpers
          for helper in @__helpers
            Joosy.Module.merge @__helpersInstance, helper

      @__helpersInstance

    #
    # Defines local `@render*` methods with proper stack pointer set
    #
    # @param [Object] parentStackPointer        Internal rendering stack pointer
    # @private
    #
    __instantiateRenderers: (stack) ->

      render: (template, locals={}) =>
        @render template, locals, stack

      renderDynamic: (template, locals={}, callback) =>
        @renderDynamic template, locals, callback, stack

      renderInline: (locals={}, callback, partial) =>
        if arguments.length < 3
          partial  = callback
          callback = undefined

        template = (params) ->
          partial.apply(params)

        @renderDynamic template, locals, callback, stack

      #
      # Allows to delay certain action to the moment when rendering is finished
      # and template has become part of the actual DOM
      #
      onRendered: (action) ->
        @__renderer.callDeferred =>
          action(@__renderer)

      #
      # Allows to delay certain action to the moment when particular region
      # is removed (works with dynamic rendering as well)
      #
      onRemoved: (action) ->
        stack.destructors.push action

    #
    # Actual rendering implementation
    #
    # @private
    #
    __render: (dynamic, template, locals={}, parentStackPointer=false) ->
      stack = @__renderingStackChildFor parentStackPointer

      stack.template = template
      stack.locals   = locals

      if typeof(template) == 'string'
        if @__renderSection?
          template = Joosy.templater().resolveTemplate @__renderSection(), template, this
        template = Joosy.templater().buildView template
      else if typeof(template) != 'function'
        throw new Error "#{Joosy.Module.__className @}> template (maybe @view) does not look like a string or lambda"

      if locals.constructor != Object
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
            @__destructRegionBindings stack
          else
            @__destructRegionManuals stack
            @__destructRegionChildren stack
            morph.html result()
            dynamic() if dynamic instanceof Function

        # This is here to break stack tree and save from
        # repeating DOM modification
        timeout = null
        debouncedUpdate = ->
          Joosy.cancelDeferred timeout if timeout?
          timeout = Joosy.callDeferred update

        for key, object of locals
          if locals.hasOwnProperty key
            if object?.bind? && object?.unbind?
              binding = [object, object.bind('changed', debouncedUpdate)]
              stack.metamorphBindings.push binding

        morph.outerHTML()
      else
        result()

    #
    # Template for the rendering stack node
    #
    # @private
    #
    __renderingStackElement: (parent=null) ->
      metamorphBindings: []
      locals: null
      template: null
      children: []
      parent: parent
      destructors: []

    #
    # Creates new rendering stack node using given pointer as the parent
    #
    # @private
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
    # Properly recursively destructs rendering region bound to given stack pointer
    #
    # @private
    #
    __destructRenderingStack: (stackPointer=false) ->
      unless stackPointer
        if @__renderingStack?
          @__destructRegion stackPointer for stackPointer in @__renderingStack
      else
        @__destructRegion stackPointer

    #
    # Properly recursively destructs rendering region bound to given stack pointer
    #
    # @private
    #
    __destructRegion: (stackPointer) ->
      @__destructRegionChildren stackPointer
      @__destructRegionBindings stackPointer
      @__destructRegionManuals  stackPointer

    #
    # Recursively runs destruction for every children
    #
    # @private
    #
    __destructRegionChildren: (stackPointer) ->
      if stackPointer?.children
        for child in stackPointer.children
          @__destructRenderingStack child
        stackPointer.children = []

    #
    # Cleans metamorphs bindings
    #
    # @private
    #
    __destructRegionBindings: (stackPointer) ->
      if stackPointer?.metamorphBindings
        for [object, callback] in stackPointer.metamorphBindings
          object.unbind callback
        stackPointer.metamorphBindings = []

    #
    # Calls manually bounded destructors
    #
    # @private
    #
    __destructRegionManuals: (stackPointer) ->
      if stackPointer?.destructors
        for action in stackPointer.destructors
          action(@)
        stackPointer.destructors = []

# AMD wrapper
if define?.amd?
  define 'joosy/modules/renderer', -> Joosy.Modules.Renderer