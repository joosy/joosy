Joosy.Modules.Container =
  events: false
  elements: false

  eventSplitter: /^(\S+)\s*(.*)$/

  $: (selector) -> $(selector, @container)

  refreshElements: ->
    @__collectElements().each (key, value) =>
      @[key] = @$(value)

  swapContainer: (container, data) ->
    realContainer = container.clone().html(data)
    container.replaceWith realContainer
    realContainer

  __collectElements: ->
    elements = Object.extended(@elements || {})

    klass = this
    while klass = klass.constructor.__super__
      elements.merge(klass.elements, false)

    elements

  __collectEvents: ->
    events = Object.extended(@events || {})

    klass = this
    while klass = klass.constructor.__super__
      events.merge(klass.events, false)

    events

  __extractSelector: (selector) ->
    if r = selector.match(/\$([A-z]+)/)
      selector = @__collectElements()[r[1]]

    selector

  __delegateEvents: ->
    module = this
    events = @__collectEvents()

    events.each (key, method) =>
      method   = @[method] unless typeof(method) == 'function'
      callback = (event) -> method.call(module, this, event)

      match      = key.match(@eventSplitter)
      eventName  = match[1]
      selector   = @__extractSelector(match[2])

      if selector == ""
        @container.bind(eventName, callback)
        Joosy.Modules.Log.debug "#{@constructor.name}> #{eventName} binded on container"
      else
        @container.on(eventName, selector, callback)
        Joosy.Modules.Log.debug "#{@constructor.name}> #{eventName} binded on #{selector}"
