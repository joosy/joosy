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
      else
        @container.on(eventName, selector, callback)

  # @helpers: (helper...) ->           <- This is not a class! Static property can not be included in object
  #   # Add a helper to the chain


  __instantiateHelpers: ->
    unless @__helpersInstance
      @__helpersInstance = { __proto__: this }

      # Mix in the actual helpers

    @__helpersInstance

  render: (template, locals) ->
    if object.isString(template)
      template = JST[template]

    locals = new Object(locals)
    locals.__proto__ = @__instantiateHelpers()

    morph = Metamorph(template(locals))

    update = =>
      morph.html(template(locals))

    @__metamorphs ||= []

    for key, object of locals
      if object.bind?
        object.bind 'changed', update
        @__metamorphs.push [object, update]

    morph.outerHTML()

  __removeMetamorphs: ->
    if @__metamorphs
      for [object, callback] in @__metamorphs
        object.unbind callback