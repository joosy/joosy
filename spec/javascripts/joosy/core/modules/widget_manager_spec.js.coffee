describe "Joosy.Modules.WidgetsManager", ->

  beforeEach ->
    class @TestWidgetManager extends Joosy.Module
      @include Joosy.Modules.WidgetsManager
    @box = new @TestWidgetManager()
    @widgetMock = Object.extended(
      __load: sinon.stub()
      __unload: sinon.spy()
    )
    @widgetMock.__load.returns(@widgetMock)


  it "should register and unregister widget", ->
    expect(@box.registerWidget(@ground, @widgetMock)).toBe(@widgetMock)
    expect(@box.__activeWidgets).toEqual([@widgetMock])
    expect(@widgetMock.__load.callCount).toEqual(1)

    expect(@box.unregisterWidget(@widgetMock)).toBeTruthy()
    expect(@box.__activeWidgets).toEqual([undefined])
    expect(@widgetMock.__unload.callCount).toEqual(1)

  it "should unload all widgets", ->
    0.upto(2).each =>
      @box.registerWidget(@ground, @widgetMock)
    @box.__unloadWidgets()
    expect(@widgetMock.__unload.callCount).toEqual(3)

  it "should inherit widget declarations", ->
    @box.container = @ground
    @TestWidgetManager::widgets =
      'test': 'widget'
    class SubWidgetManagerA extends @TestWidgetManager
      widgets:
        'selector': 'widget'
    class SubWidgetManagerB extends SubWidgetManagerA
      widgets:
        'widgets': 'widget'
        'selector': 'overriden'
    subBox = new SubWidgetManagerB()
    target = subBox.__collectWidgets()
    expect(target).toEqual(
      'test': 'widget'
      'widgets':  'widget'
      'selector': 'overriden'
    )

  it "should register widgets per declaration", ->
    @seedGround()
    @box.container = $('#application')
    @box.elements = {footer: '.footer'}
    @box.widgets =
      '$container': Joosy.Widget
      '$footer': Joosy.Widget
      '.post': sinon.stub()
    @box.widgets['.post'].returns(@widgetMock)
    @box.__setupWidgets()
    expect(@box.__activeWidgets.length).toEqual(5)
    expect(@box.widgets['.post'].callCount).toEqual(3)
    expect(@box.widgets['.post'].getCall(0).calledOn(@box))

  it "should bootstrap widget properly", ->
    class TextWidget extends Joosy.Widget
      @render -> @container.html 'fluffy'
      constructor: (@tester) ->

    @seedGround()
    @box.container = $('#application')
    @box.widgets = 
      '.post:first': TextWidget
      '.widget:first': (i) -> new TextWidget(i)
    @box.__setupWidgets()
    
    expect(@ground.find('.post').html()).toEqual('fluffy')
    expect(@ground.find('.widget').html()).toEqual('fluffy')
    expect(@box.__activeWidgets[0].tester).toBeUndefined()
    expect(@box.__activeWidgets[1].tester).toEqual(0)