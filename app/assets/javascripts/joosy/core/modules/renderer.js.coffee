Joosy.Modules.Renderer =
  __instantiateHelpers: ->
    unless @__helpersInstance
      @__helpersInstance = {}

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