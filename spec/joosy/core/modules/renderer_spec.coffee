describe "Joosy.Modules.Renderer", ->

  beforeEach ->
    @seedGround()

    class @TestContainer extends Joosy.Module
      @include Joosy.Modules.Renderer

      multiplier: (value) ->
        "#{value * 10}"

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

  it "updates contents, but only while it is bound to DOM", ->
    @TestContainer.view (locals) ->
      template = -> @object.value

      @renderDynamic(template, locals)

    elem = $("<div></div>")
    @ground.append elem

    elem.html @dummyContainer.__renderer({ object: @dummyObject })
    expect(elem.text()).toBe "initial"

    @dummyObject.update "new"

    waits 0

    runs ->
      expect(elem.text()).toBe "new"

    waits 0

    runs ->
      @dummyContainer.__removeMetamorphs()
      @dummyObject.update "afterwards"

    waits 0

    runs ->
      expect(elem.text()).toBe "new"

  it "debounces morpher updates", ->
    @TestContainer.view (locals) ->
      template = -> @object.value

      @renderDynamic(template, locals)

    elem = $("<div></div>")
    @ground.append elem

    sinon.spy window, 'Metamorph'

    elem.html @dummyContainer.__renderer({ object: @dummyObject })
    expect(elem.text()).toBe "initial"

    updater = sinon.spy window.Metamorph.returnValues[0], 'html'

    @dummyObject.update "new"

    waits 0

    runs ->
      expect(elem.text()).toBe "new"
      expect(updater.callCount).toEqual 1

    runs ->
      @dummyObject.update "don't make"
      @dummyObject.update "me evil"

    waits 0

    runs ->
      expect(elem.text()).toBe "me evil"
      expect(updater.callCount).toEqual 2

  it "includes helpers module in locals", ->
    @TestContainer.helper Joosy.Helpers.Hoge

    @TestContainer.view (locals) ->
      template = -> @multiplier(10)

      @render(template, locals)

    elem = $("<div></div>")
    @ground.append elem

    elem.html @dummyContainer.__renderer({ })

    expect(elem.text()).toBe "50"

  it "includes local helper in locals", ->
    @TestContainer.helper 'multiplier'

    @TestContainer.view (locals) ->
      template = -> @multiplier(10)

      @render(template, locals)

    @dummyContainer.__assignHelpers()

    elem = $("<div></div>")
    @ground.append elem

    elem.html @dummyContainer.__renderer({ })

    expect(elem.text()).toBe "100"

  it "includes global rendering helpers in locals", ->
    Joosy.Helpers.Application.globalMultiplier = (value) ->
      value * 6

    @TestContainer.view (locals) ->
      template = (locals) -> @globalMultiplier(10)

      @render(template, locals)

    elem = $("<div></div>")
    @ground.append elem

    elem.html @dummyContainer.__renderer({ })

    expect(elem.text()).toBe "60"
