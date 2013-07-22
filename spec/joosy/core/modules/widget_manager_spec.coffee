describe "Joosy.Modules.WidgetsManager", ->

  beforeEach ->
    class @Manager extends Joosy.Module
      @include Joosy.Modules.Container
      @include Joosy.Modules.WidgetsManager

    class @Widget extends Joosy.Widget
      constructor: (@argument) ->

    @manager = new @Manager

  describe "manager", ->

    beforeEach ->
      @widget = new @Widget

      sinon.spy @widget, '__load'
      sinon.spy @widget, '__unload'

    it "registers widget", ->
      result = @manager.registerWidget @$ground, @widget
      expect(result instanceof @Widget).toBeTruthy()
      expect(@manager.__activeWidgets).toEqual [result]
      expect(@widget.__load.callCount).toEqual 1

    it "unregisters widget", ->
      @manager.registerWidget @$ground, @widget

      expect(@manager.unregisterWidget @widget).toBeTruthy()
      expect(@manager.__activeWidgets).toEqual []
      expect(@widget.__unload.callCount).toEqual 1

    it "unload all widgets properly", ->
      3.times => @manager.registerWidget(@$ground, @widget)
      @manager.__unloadWidgets()
      expect(@widget.__unload.callCount).toEqual 3

  describe 'declarator', ->

    it "inherits widget declarations", ->
      @Manager.mapWidgets
        'test': 'widget'

      class A extends @Manager
        @mapWidgets
          'selector': 'widget'

      class B extends A
        @mapWidgets
          'widgets': 'widget'
          'selector': 'overriden'

      expect((new A).__widgets).toEqual Object.extended
        'test': 'widget'
        'selector': 'widget'

      expect((new B).__widgets).toEqual Object.extended
        'test': 'widget'
        'widgets':  'widget'
        'selector': 'overriden'

    it "registers declared widgets", ->
      @$ground.seed()

      @Manager.mapElements
        footer: '.footer'

      @Manager.mapWidgets widgets =
        '$container': Joosy.Widget
        '$footer': Joosy.Widget
        '.post': sinon.stub().returns new @Widget

      @manager.container = $('#application')
      @manager.__assignElements()
      @manager.__setupWidgets()

      expect(@manager.__activeWidgets.length).toEqual 5
      expect(widgets['.post'].callCount).toEqual 3
      expect(widgets['.post'].getCall(0).calledOn @manager).toBeTruthy()

    it "bootstraps declared widgets properly", ->
      @$ground.seed()

      @Widget.view -> 'fluffy'
      @Manager.mapWidgets
        '#post1': @Widget
        '#widget1': (i) => new @Widget i

      @manager.container = $('#application')
      @manager.__setupWidgets()

      expect(@$ground.find('#post1').html()).toEqual 'fluffy'
      expect(@$ground.find('#widget1').html()).toEqual 'fluffy'
      expect(@manager.__activeWidgets[0].argument).toBeUndefined()
      expect(@manager.__activeWidgets[1].argument).toEqual 0