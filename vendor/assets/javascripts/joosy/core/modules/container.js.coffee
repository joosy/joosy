Joosy.Modules.Container =
  events: false
  elements: false

  eventSplitter: /^(\S+)\s*(.*)$/

  $: (selector) -> $(selector, @container)

  refreshElements: ->
    @__collectElements().each (key, value) => @[key] = @$(value)

  swapContainer: (container, data) ->
    realContainer = container.clone().html(data)
    container.replaceWith realContainer
    return realContainer
    
  __collectElements: ->
    elements = Object.extended(@elements || {})
    klass = @
    while klass = klass.constructor.__super__
      elements.merge(klass.elements, false)
    elements

  __collectEvents: ->
    events = Object.extended(@events || {})
    klass = @
    while klass = klass.constructor.__super__
      events.merge(klass.events, false)
    events

  __extractSelector: (selector) ->
    if r = selector.match(/\$([A-z]+)/)
      selector = @__collectElements()[r[1]]
    selector

  __delegateEvents: ->
    module = @
    events = @__collectEvents()

    events.each (key, method) =>
      method   = @[method] unless typeof(method) is 'function'
      callback = (event) -> method.call(module, @, event)

      match      = key.match(@eventSplitter)
      eventName  = match[1]
      selector   = @__extractSelector(match[2])

      if selector is ''
        @container.bind(eventName, callback)
      else
        @container.on(eventName, selector, callback)