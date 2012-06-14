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
    
  it "renders resources and keep html up2date", ->
    data = Joosy.Resource.Generic.build zombie: 'rock'

    @TestContainer.view (locals) ->
      template = -> @zombie

      @renderDynamic(template, locals)

    elem = $("<div></div>")
    @ground.append elem
  
    elem.html @dummyContainer.__renderer(data)
    
    waits 0

    runs -> 
      expect(elem.text()).toBe "rock"
    
    runs ->
      data 'zombie', 'suck'
    
    waits 0 

    runs ->
      expect(elem.text()).toBe "suck"

  it "renders collections and keep html up2date", ->
    class Foo extends Joosy.Resource.Generic
      @entity 'foo'

    data = new Joosy.Resource.Collection(Foo)
    
    data.load [
        { zombie: 'rock' },
        { zombie: 'never sleep' }
      ]

    @TestContainer.view (locals) ->
      template = -> @data[1] 'zombie'

      @renderDynamic(template, locals)

    elem = $("<div></div>")
    @ground.append elem

    elem.html @dummyContainer.__renderer(data)

    waits 0

    runs -> 
      expect(elem.text()).toBe "never sleep"

    runs ->
      data.data[1] 'zombie', 'suck'
    
    waits 0 
    
    runs ->
      expect(elem.text()).toBe "suck"


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

  it "includes rendering helpers in locals", ->
    @TestContainer.helpers "Hoge"

    @TestContainer.view (locals) ->
      template = (locals) -> @multiplier(10)

      @render(template, locals)

    elem = $("<div></div>")
    @ground.append elem

    elem.html @dummyContainer.__renderer({ })

    expect(elem.text()).toBe "50"

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

  it "proxies onRefresh for containers", ->
    class Box extends Joosy.Module
      @include Joosy.Modules.Renderer
      @include Joosy.Modules.Container

    callback = sinon.spy()

    Box.view (locals) ->
      template = -> @onRefresh -> callback()
      @render(template, locals)

    box = new Box

    box.__renderer({ })
    box.refreshElements()

    expect(callback.callCount).toEqual 1