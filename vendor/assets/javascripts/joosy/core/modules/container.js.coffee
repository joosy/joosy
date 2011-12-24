Joosy.Modules.Container =
  events: false
  elements: false

  eventSplitter: /^(\S+)\s*(.*)$/

  $: (selector) -> $(selector, @container)

  refreshElements: ->
    elements = Object.extended(@elements || {})

    x = @__proto__
    elements.merge(x.elements, false) while x = x.__proto__

    return unless elements

    elements.each (key, value) => @[key] = @$(value)

  swapContainer: (container, data) ->
    realContainer = container.clone().html(data)
    container.replaceWith realContainer
    return realContainer

  __delegateEvents: ->
    events = Object.extended(@events || {})

    x = @__proto__
    events.merge(x.events, false) while x = x.__proto__

    return unless events

    events.each (key, method) =>
      unless typeof(method) is 'function'
        method = @proxy(@[method])
      else
        method = @proxy(method)

      match      = key.match(@eventSplitter)
      eventName  = match[1]
      selector   = match[2]

      if selector is ''
        @container.bind(eventName, method)
      else
        if r = selector.match(/\$([A-z]+)/)
          selector = @elements[r[1]]

        @container.on(eventName, selector, method)