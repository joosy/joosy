Joosy.Modules.Container =
  events: false
  elements: false

  eventSplitter: /^(\S+)\s*(.*)$/

  $: (selector) -> $(selector, @container)

  refreshElements: ->
    elements = Object.extended(@elements || {})

    x = @constructor
    elements.merge(x.elements, false) while x = x.__super__

    return unless elements

    elements.each (key, value) => @[key] = @$(value)

  swapContainer: (container, data) ->
    realContainer = container.clone().html(data)
    container.replaceWith realContainer
    return realContainer
    
  __extractSelector: (selector) ->
    if r = selector.match(/\$([A-z]+)/)
      selector = @elements[r[1]]
    selector

  __delegateEvents: ->
    module = @
    events = Object.extended(@events || {})

    x = @constructor
    events.merge(x.events, false) while x = x.__super__

    return unless events

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