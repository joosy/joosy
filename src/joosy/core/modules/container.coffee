#= require joosy/core/joosy

#
# DOM container handling, DOM elements and DOM events bindings
#
# @note Requires implementor to contain DOM node at @container propert
#
# @mixin
#
Joosy.Modules.Container =
  eventSplitter: /^(\S+)\s*(.*)$/

  included: ->
    @mapElements = (map) ->
      unless @::hasOwnProperty "__elements"
        @::__elements = Object.clone(@.__super__.__elements) || {}
      Object.merge @::__elements, map

    @mapEvents = (map) ->
      unless @::hasOwnProperty "__events"
        @::__events = Object.clone(@.__super__.__events) || {}
      Object.merge @::__events, map

  onRefresh: (callback) ->
    @__onRefreshes = [] unless @hasOwnProperty "__onRefreshes"
    @__onRefreshes.push callback

  $: (selector) ->
    $(selector, @container)

  #
  # Rebinds selectors defined in 'elements' hash to object properties
  #
  refreshElements: ->
    if @hasOwnProperty "__onRefreshes"
      @__onRefreshes.each (callback) => callback.apply @
      @__onRefreshes = []

  #
  # Clears old HTML links, set the new HTML from the callback and refreshes elements
  #
  # @param [Function] htmlCallback       `() -> String` callback that will generate new HTML
  #
  reloadContainer: (htmlCallback) ->
    @__removeMetamorphs?()
    @container.html htmlCallback()
    @refreshElements()

  #
  # Fills container with given data removing all events
  #
  # @param [jQuery] container       jQuery entity of container to update
  # @param [String] data            HTML to inject
  #
  swapContainer: (container, data) ->
    container.unbind().off()
    container.html data
    container

  #
  # Converts '$...' notation to selector from 'elements'
  #
  # @param [String] selector            Selector to convert
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
  # @example Sample elements
  #   @mapElements
  #     foo: '.foo'
  #     bar: '.bar'
  #
  __assignElements: (root, entries) ->
    root    ||= @
    entries ||= @__elements

    return unless entries

    Object.each entries, (key, value) =>
      if Object.isObject(value)
        @__assignElements root['$'+key]={}, value
      else
        value = @__extractSelector value

        root['$'+key] = (filter) =>
          return @$(value) unless filter
          return @$(value).filter(filter)

        root['$'+key].selector = value

  #
  # Binds events defined in 'events' to container
  #
  # @example Sample events
  #   @mapEvents
  #     'click': -> # this will raise on container click
  #     'click .foo': -> # this will raise on .foo click
  #     'click $foo': -> #this will search for selector of foo element
  #
  __delegateEvents: ->
    module = @
    events = @__events

    return unless events

    Object.each events, (key, method) =>
      unless Object.isFunction method
        method = @[method]
      callback = (event) ->
        method.call module, $(this), event

      match      = key.match @eventSplitter
      eventName  = match[1]
      selector   = @__extractSelector match[2]

      if selector == ""
        @container.bind eventName, callback
        Joosy.Modules.Log.debugAs @, "#{eventName} binded on container"
      else if selector == undefined
        throw new Error "Unknown element #{match[2]} in #{Joosy.Module.__className @constructor} (maybe typo?)"
      else
        @container.on eventName, selector, callback
        Joosy.Modules.Log.debugAs @, "#{eventName} binded on #{selector}"
