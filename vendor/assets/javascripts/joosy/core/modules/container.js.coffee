Joosy.Modules.Container =
  events: false
  elements: false

  eventSplitter: /^(\S+)\s*(.*)$/

  $: (selector) -> $(selector, @container)

  refreshElements: ->
    elements = @elements || {}

    x = @__proto__
    _(elements).defaults(x.elements) while x = x.__proto__

    return unless elements

    for key, value of @elements
      @[key] = @$(value)

  swapContainer: (container, data) ->
    realContainer = container.clone().html(data)
    container.replaceWith realContainer
    return realContainer

  __delegateEvents: ->
    events = @events || {}

    x = @__proto__
    _(events).defaults(x.events) while x = x.__proto__

    return unless @events

    for key, method of @events
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