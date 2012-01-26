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
    Joosy.Helpers.Global.globalMultiplier = (value) ->
      value * 6

    @TestContainer.view (locals) ->
      template = (locals) ->
        "#{locals.globalMultiplier(10)}"

      @render(template, locals)

    elem = $("<div></div>")
    @ground.append elem

    elem.html @dummyContainer.__renderer({ })

    expect(elem.text()).toBe "60"

  it "correctly derives paths for templates from namespaces", ->
    Joosy.namespace 'HogeNS.Fuga', ->
      class @British extends Joosy.Module
        @include Joosy.Modules.Renderer

    class @Irish extends Joosy.Module
      @include Joosy.Modules.Renderer

    British = new HogeNS.Fuga.British
    Irish   = new @Irish

    func = ->
    expect(British.__resolveTemplate(func)).toBe func

    expect(British.__resolveTemplate()).toEqual "pages/hoge_ns/fuga/british"
    expect(British.__resolveTemplate("other")).toEqual "pages/hoge_ns/fuga/other"
    expect(British.__resolveTemplate("some/thing")).toEqual "pages/some/thing"

    expect(British.__resolveTemplate("other", true)).toEqual "pages/hoge_ns/fuga/_other"
    expect(British.__resolveTemplate("some/thing", true)).toEqual "pages/some/_thing"

    expect(Irish.__resolveTemplate("con", true)).toEqual "pages/_con"
    expect(Irish.__resolveTemplate("con/artist", true)).toEqual "pages/con/_artist"
