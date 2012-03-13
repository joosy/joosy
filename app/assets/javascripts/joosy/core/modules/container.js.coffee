#
# DOM container handling, DOM elements and DOM events bindings
#
# @note Requires implementor to contain DOM node at @container propert
#
# @module
#
Joosy.Modules.Container =
  events: false
  elements: false

  eventSplitter: /^(\S+)\s*(.*)$/

  $: (selector) ->
    $(selector, @container)

  #
  # Rebinds selectors defined in 'elements' hash to object properties
  #
  # @example Sample elements
  #   elements:
  #     foo: '.foo'
  #     bar: '.bar'
  #
  refreshElements: ->
    @__collectElements().each (key, value) =>
      # TODO: Check for possible collisions?
      @[key] = @$(value)

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
  # Gathers 'elements' from current and super classes
  #
  __collectElements: ->
    elements = Object.extended @elements || {}

    klass = this
    while klass = klass.constructor.__super__
      Joosy.Module.merge elements, klass.elements, false

    elements

  #
  # Gathers 'events' from current and super classes
  #
  __collectEvents: ->
    events = Object.extended @events || {}

    klass = this
    while klass = klass.constructor.__super__
      Joosy.Module.merge events, klass.events, false

    events

  #
  # Converts '$...' notation to selector from 'elements'
  #
  # @param [String] selector            Selector to convert
  #
  __extractSelector: (selector) ->
    if r = selector.match /\$([A-z]+)/
      selector = @__collectElements()[r[1]]

    selector

  #
  # Bings events defined in 'events' to container
  #
  # @example Sample events
  #   events:
  #     'click': -> # this will raise on container click
  #     'click .foo': -> # this will raise on .foo click
  #     'click $foo': -> #this will search for selector of foo element
  #
  __delegateEvents: ->
    module = this
    events = @__collectEvents()

    events.each (key, method) =>
      unless Object.isFunction method
        method = @[method]
      callback = (event) ->
        method.call module, this, event

      match      = key.match @eventSplitter
      eventName  = match[1]
      selector   = @__extractSelector match[2]

      if selector == ""
        @container.bind eventName, callback
        Joosy.Modules.Log.debugAs @, "#{eventName} binded on container"
      else
        @container.on eventName, selector, callback
        Joosy.Modules.Log.debugAs @, "#{eventName} binded on #{selector}"
