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