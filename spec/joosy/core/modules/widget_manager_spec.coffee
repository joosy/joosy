describe "Joosy.Modules.WidgetsManager", ->

  beforeEach ->
    class @TestWidgetManager extends Joosy.Module
      @include Joosy.Modules.WidgetsManager
      @include Joosy.Modules.Container

    @box = new @TestWidgetManager()
    @widgetMock = Object.extended(
      __load: sinon.stub()
      __unload: sinon.spy()
    )
    @widgetMock.__load.returns @widgetMock


  it "should register and unregister widget", ->
    expect(@box.registerWidget @ground, @widgetMock).toBe @widgetMock
    expect(@box.__activeWidgets).toEqual [@widgetMock]
    expect(@widgetMock.__load.callCount).toEqual 1

    expect(@box.unregisterWidget @widgetMock).toBeTruthy()
    expect(@box.__activeWidgets).toEqual []
    expect(@widgetMock.__unload.callCount).toEqual 1

  it "should unload all widgets", ->
    0.upto(2).each => @box.registerWidget(@ground, @widgetMock)
    @box.__unloadWidgets()
    expect(@widgetMock.__unload.callCount).toEqual 3

  it "should inherit widget declarations", ->
    @box.container = @ground
    @TestWidgetManager::__widgets =
      'test': 'widget'
    class SubWidgetManagerA extends @TestWidgetManager
      @mapWidgets
        'selector': 'widget'
    class SubWidgetManagerB extends SubWidgetManagerA
      @mapWidgets
        'widgets': 'widget'
        'selector': 'overriden'
    subBox = new SubWidgetManagerB()
    target = subBox.__widgets
    expect(target).toEqual Object.extended
      'test': 'widget'
      'widgets':  'widget'
      'selector': 'overriden'

  it "should register widgets per declaration", ->
    @seedGround()
    @box.container  = $('#application')
    @box.__elements = {footer: '.footer'}
    @box.__widgets  = __widgets =
      '$container': Joosy.Widget
      '$footer': Joosy.Widget
      '.post': sinon.stub().returns @widgetMock

    @box.__assignElements()
    @box.__setupWidgets()

    expect(@box.__activeWidgets.length).toEqual 5
    expect(__widgets['.post'].callCount).toEqual 3
    expect(__widgets['.post'].getCall(0).calledOn @box).toBeTruthy()

  it "should bootstrap widget properly", ->
    class TextWidget extends Joosy.Widget
      @view -> 'fluffy'
      constructor: (@tester) ->

    @seedGround()
    @box.container = $('#application')
    @box.__widgets =
      '#post1': TextWidget
      '#widget1': (i) -> new TextWidget i
    @box.__setupWidgets()

    expect(@ground.find('.post').html()).toEqual 'fluffy'
    expect(@ground.find('.widget').html()).toEqual 'fluffy'
    expect(@box.__activeWidgets[0].tester).toBeUndefined()
    expect(@box.__activeWidgets[1].tester).toEqual 0