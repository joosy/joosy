describe "Joosy.Modules.Renderer", ->

  beforeEach ->
    @seedGround()

    class @TestContainer extends Joosy.Module
      @include Joosy.Modules.Renderer

    @dummyContainer = new @TestContainer

    class @TestObject extends Joosy.Module
      @include Joosy.Modules.Events

      constructor: (@value) ->

      update: (@value) ->
        @trigger 'changed'

    @dummyObject = new @TestObject("initial")

    Joosy.namespace 'Joosy.Helpers.Hoge', ->
      @multiplier = (value) ->
        "#{value * 5}"

  it "should update contents, but only while it is bound to DOM", ->
    @TestContainer.view (locals) ->
      template = (locals) ->
        "#{locals.object.value}"

      @render(template, locals)

    elem = $("<div></div>")
    @ground.append elem

    elem.html @dummyContainer.__renderer({ object: @dummyObject })

    expect(elem.text()).toBe "initial"

    @dummyObject.update "new"

    expect(elem.text()).toBe "new"

    @dummyContainer.__removeMetamorphs()
    @dummyObject.update "afterwards"

    expect(elem.text()).toBe "new"

  it "should include rendering helpers in locals", ->
    @TestContainer.helpers "Hoge"

    @TestContainer.view (locals) ->
      template = (locals) ->
        "#{locals.multiplier(10)}"

      @render(template, locals)

    elem = $("<div></div>")
    @ground.append elem

    elem.html @dummyContainer.__renderer({ })

    expect(elem.text()).toBe "50"

  it "should include global rendering helpers in locals", ->
    Joosy.Helpers.Application.globalMultiplier = (value) ->
      value * 6

    @TestContainer.view (locals) ->
      template = (locals) ->
        "#{locals.globalMultiplier(10)}"

      @render(template, locals)

    elem = $("<div></div>")
    @ground.append elem

    elem.html @dummyContainer.__renderer({ })

    expect(elem.text()).toBe "60"