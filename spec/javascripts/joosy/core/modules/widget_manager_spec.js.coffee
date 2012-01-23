describe "Joosy.Modules.WidgetsManager", ->

  beforeEach ->
    class @TestWidgetManager extends Joosy.Module
      @include Joosy.Modules.WidgetsManager
    @box = new @TestWidgetManager()
    @widget_mock = Object.extended(
      __load: sinon.stub()
      __unload: sinon.spy()
    )
    @widget_mock.__load.returns(@widget_mock)


  it "should register and unregister widget", ->
    expect(@box.registerWidget(@ground, @widget_mock)).toBe(@widget_mock)
    expect(@box.__activeWidgets).toEqual([@widget_mock])
    expect(@widget_mock.__load.callCount).toEqual(1)

    expect(@box.unregisterWidget(@widget_mock)).toBeTruthy()
    expect(@box.__activeWidgets).toEqual([undefined])
    expect(@widget_mock.__unload.callCount).toEqual(1)

  it "should unload all widgets", ->
    0.upto(2).each =>
      @box.registerWidget(@ground, @widget_mock)
    @box.__unloadWidgets()
    expect(@widget_mock.__unload.callCount).toEqual(3)

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
    @box.widgets['.post'].returns(@widget_mock)
    @box.__setupWidgets()
    expect(@box.__activeWidgets.length).toEqual(5)
    expect(@box.widgets['.post'].callCount).toEqual(3)
    expect(@box.widgets['.post'].getCall(0).calledOn(@box))

  it "should bootstrap widget properly", ->
    class TextWidget extends Joosy.Widget
      @afterLoad -> @container.html '123'

    @seedGround()
    @box.container = $('#application')
    @box.widgets = 
      '.post': TextWidget
      '.widget': -> new TextWidget
    
    expect(@ground.find('.post').html()).toEqual('123')
    expect(@ground.find('.widget').html()).toEqual('123')
