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
    
  it "should render resources and keep html up2date", ->
    data = Joosy.Resource.Generic.create zombie: 'rock'

    @TestContainer.view (locals) ->
      template = (locals) -> 
        "#{locals.zombie}"

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

  it "should render collections and keep html up2date", ->
    class Foo extends Joosy.Resource.Generic
      @entity 'foo'

    data = new Joosy.Resource.Collection(Foo)
    
    data.reset [
        { zombie: 'rock' },
        { zombie: 'never sleep' }
      ]

    @TestContainer.view (locals) ->
      template = (locals) ->
        "#{locals.data[1] 'zombie'}"

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


  it "should debounce morpher updates", ->
    @TestContainer.view (locals) ->
      template = (locals) ->
        "#{locals.object.value}"
  
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