describe "Joosy.Page", ->

  beforeEach ->
    window.JST = 'app/templates/layouts/default': (->)
    class window.ApplicationLayout extends Joosy.Layout
    class @TestPage extends Joosy.Page


  describe "not rendered page", ->

    beforeEach ->
      sinon.stub @TestPage.prototype, '__bootstrap'
      sinon.stub @TestPage.prototype, '__bootstrapLayout'
      @box = new @TestPage()
      expect(@TestPage::__bootstrap.callCount).toEqual 0
      expect(@TestPage::__bootstrapLayout.callCount).toEqual 1


    it "should have appropriate accessors", ->
      callback_names = ['fetch', 'beforePageRender', 'afterPageRender',
        'onPageRender', 'beforeLayoutRender', 'afterLayoutRender',
        'onLayoutRender']
      callback_names.each (func) =>
        @TestPage[func] 'callback'
        expect(@TestPage::['__' + func]).toEqual 'callback'

      @TestPage.scroll '#here'
      expect(@TestPage::__scrollElement).toEqual '#here'
      expect(@TestPage::__scrollSpeed).toEqual 500
      expect(@TestPage::__scrollMargin).toEqual 0

      @TestPage.scroll '#there', speed: 1000, margin: -5
      expect(@TestPage::__scrollElement).toEqual '#there'
      expect(@TestPage::__scrollSpeed).toEqual 1000
      expect(@TestPage::__scrollMargin).toEqual -5

    it "should not render layout if it not changes", ->
      @box.layout = new ApplicationLayout()
      new @TestPage {}, @box
      expect(@TestPage::__bootstrap.callCount).toEqual 1
      expect(@TestPage::__bootstrapLayout.callCount).toEqual 1

    it "should render layout if it changes", ->
      class SubLayout extends Joosy.Layout
      @box.layout = new SubLayout()
      new @TestPage {}, @box
      expect(@TestPage::__bootstrap.callCount).toEqual 0
      expect(@TestPage::__bootstrapLayout.callCount).toEqual 2

    it "should stop render on beforeFilter result", ->
      sinon.stub @TestPage.prototype, '__runBeforeLoads'
      @TestPage::__runBeforeLoads.returns(false)
      new @TestPage()
      expect(@TestPage::__bootstrap.callCount).toEqual 0
      expect(@TestPage::__bootstrapLayout.callCount).toEqual 1

    it "should use Router", ->
      target = sinon.stub Joosy.Router, 'navigate'
      @box.navigate 'there'
      expect(target.callCount).toEqual 1
      expect(target.alwaysCalledWithExactly 'there').toBeTruthy()
      Joosy.Router.navigate.restore()

    it "should load itself", ->
      spies = []
      spies.push sinon.spy(@box, 'refreshElements')
      spies.push sinon.spy(@box, '__delegateEvents')
      spies.push sinon.spy(@box, '__setupWidgets')
      spies.push sinon.spy(@box, '__runAfterLoads')
      @box.__load()
      expect(spies).toBeSequenced()

    it "should unload itself", ->
      spies = []
      spies.push sinon.spy(@box, 'clearTime')
      spies.push sinon.spy(@box, '__unloadWidgets')
      spies.push sinon.spy(@box, '__removeMetamorphs')
      spies.push sinon.spy(@box, '__runAfterUnloads')
      @box.__unload()
      expect(spies).toBeSequenced()

    describe "rendered page", ->

      beforeEach ->
        @box.previous = new @TestPage()
        @box.previous.layout = new @box.previous.layout()
        @box.view = sinon.spy()
        @box.layout.prototype.view = sinon.spy()
        @TestPage::__bootstrap.restore()
        @TestPage::__bootstrapLayout.restore()


      it "should wait stageClear and dataReceived event to start render", ->
        spies = []

        spies.push @box.__beforePageRender = sinon.spy (stage, callback) ->
          expect(stage.selector).toEqual @layout.content().selector
          expect(@__oneShotEvents[0][0]).toEqual ['stageClear', 'dataReceived']
          callback()
          expect(@__oneShotEvents[0][0]).toEqual ['dataReceived']

        spies.push @box.__fetch = sinon.spy (callback) ->
          expect(@__oneShotEvents[0][0]).toEqual ['dataReceived']
          callback()
          expect(@__oneShotEvents).toEqual []

        spies.push sinon.spy(@box.previous, '__unload')

        spies.push @box.__onPageRender = sinon.spy (stage, callback) ->
          expect(stage.selector).toEqual @layout.content().selector
          expect(typeof callback).toEqual 'function'
          # callback()  - start rendering

        @box.__bootstrap()

        expect(spies).toBeSequenced()

      it "should render page", ->
        spies = []

        spies.push @box.view
        spies.push sinon.spy(@box, 'swapContainer')
        spies.push sinon.spy(@box, '__load')
        spies.push sinon.spy(Joosy.Beautifier, 'go')

        spies.push @box.__afterPageRender = sinon.spy (stage) ->
          expect(stage.selector).toEqual @layout.content().selector

        @box.__bootstrap()
        expect(spies).toBeSequenced()

        Joosy.Beautifier.go.restore()

      it "should wait stageClear and dataReceived event to start layout render", ->
        spies = []

        spies.push @box.__beforeLayoutRender = sinon.spy (stage, callback) ->
          expect(stage.selector).toEqual Joosy.Application.content().selector
          expect(@__oneShotEvents[0][0]).toEqual ['stageClear', 'dataReceived']
          callback()
          expect(@__oneShotEvents[0][0]).toEqual ['dataReceived']

        spies.push @box.__fetch = sinon.spy (callback) ->
          expect(@__oneShotEvents[0][0]).toEqual ['dataReceived']
          callback()
          expect(@__oneShotEvents).toEqual []

        spies.push sinon.spy(@box.previous.layout, '__unload')
        spies.push sinon.spy(@box.previous, '__unload')

        spies.push @box.__onLayoutRender = sinon.spy (stage, callback) ->
          expect(stage.selector).toEqual Joosy.Application.content().selector
          expect(typeof callback).toEqual 'function'
          # callback()  - start rendering

        @box.__bootstrapLayout()

        expect(spies).toBeSequenced()

      it "should render layout and page", ->
        spies = []

        spies.push @box.layout.prototype.view
        spies.push @box.view
        swapContainer = sinon.spy(@box, 'swapContainer')
        spies.push @box.layout.prototype.__load = sinon.spy()
        spies.push sinon.spy(@box, '__load')
        spies.push sinon.spy(Joosy.Beautifier, 'go')

        spies.push @box.__afterLayoutRender = sinon.spy (stage) ->
          expect(stage.selector).toEqual Joosy.Application.content().selector

        @box.__bootstrapLayout()
        expect(spies).toBeSequenced()
        expect(swapContainer.callCount).toEqual 2

        Joosy.Beautifier.go.restore()
