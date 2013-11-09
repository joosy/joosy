#= require joosy/joosy

#
# DOM container handling, DOM elements and DOM events bindings
#
# @note Requires implementor to contain DOM node at @$container property
# @mixin
#
Joosy.Modules.DOM =
  eventSplitter: /^(\S+)\s*(.*)$/

  ClassMethods:
    #
    # Extends elements mapping scheme
    #
    # @example
    #   @mapElements
    #     'name':       '.selector'
    #     'name2':      '$name .selector'
    #     'category':
    #       'name3':    '.selector'
    #
    mapElements: (map) ->
      unless @::hasOwnProperty "__elements"
        @::__elements = Joosy.Module.merge {}, @.__super__.__elements
      Joosy.Module.merge @::__elements, map

    #
    # Extends events mapping scheme
    #
    # @example
    #   @mapEvents
    #     'click':            ($container, event) -> #fires on container
    #     'click .selector':  ($element, event) -> #fires on .selector
    #     'click $name':      ($element, event) -> #fires on selector assigned to 'name' element
    #
    mapEvents: (map) ->
      unless @::hasOwnProperty "__events"
        @::__events = Joosy.Module.merge {}, @.__super__.__events
      Joosy.Module.merge @::__events, map

  InstanceMethods:
    #
    # jQuery accessor limited to the container of current object
    #
    # @param [String] selector           jQuery selector
    # @param [jQuery] context            The override for the context
    # @return [jQuery]
    #
    $: (selector, context) ->
      $(selector, context || @$container)

    #
    # Converts '$...' notation to selector from 'elements'
    #
    # @param [String] selector            Selector to convert
    # @private
    #
    __extractSelector: (selector) ->
      selector = selector.replace /(\$[A-z0-9\.\$]+)/g, (path) =>
        path    = path.split('.')
        keyword = path.pop()

        target = @
        target = target?[part] for part in path

        target?[keyword]?.selector

      selector.trim()

    #
    # Assigns elements defined in 'elements'
    #
    # @private
    # @see Joosy.Modules.DOM.mapElements
    #
    __assignElements: (root, entries) ->
      root    ||= @
      entries ||= @__elements

      return unless entries

      for key,value of entries
        do (key, value) =>
          if typeof(value) != 'string'
            @__assignElements root['$'+key]={}, value
          else
            value = @__extractSelector value
            root['$'+key] = @__wrapElement(value)
            root['$'+key].selector = value

    #
    # Wraps actual element closures. Required to clear context to avoid circular reference
    #
    # @private
    # @see Joosy.Modules.DOM.mapElements
    #
    __wrapElement: (value) ->
      (context) =>
        return @$(value) unless context
        return @$(value, context)

    #
    # Binds events defined in 'events' to container
    #
    # @private
    # @see Joosy.Modules.DOM.mapEvents
    #
    __delegateEvents: ->
      module = @
      events = @__events

      return unless events

      for keys, method of events
        do (keys, method) =>
          for key in keys.split(',')
            key = key.replace(/^\s+/, '')

            unless typeof(method) == 'function'
              method = @[method]
            callback = (event) ->
              method.call module, $(this), event

            match      = key.match Joosy.Modules.DOM.eventSplitter
            eventName  = match[1]
            selector   = @__extractSelector match[2]

            if selector == ""
              @$container.bind eventName, callback
              Joosy.Modules.Log.debugAs @, "#{eventName} binded on container"
            else if selector == undefined
              throw new Error "Unknown element #{match[2]} in #{Joosy.Module.__className @constructor} (maybe typo?)"
            else
              @$container.on eventName, selector, callback
              Joosy.Modules.Log.debugAs @, "#{eventName} binded on #{selector}"

    #
    # Clears the container from everything
    #
    # @private
    #
    __clearContainer: ->
      @$container.unbind().off()
      @$container = $()


# AMD wrapper
if define?.amd?
  define 'joosy/modules/dom', -> Joosy.Modules.DOM
