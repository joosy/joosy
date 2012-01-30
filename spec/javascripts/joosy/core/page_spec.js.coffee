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
      callback_names = ['fetch', 'beforeRender', 'afterRender', 'onRender']
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
      @box.layout.yield()
      new @TestPage {}, @box
      expect(@TestPage::__bootstrap.callCount).toEqual 1
      expect(@TestPage::__bootstrapLayout.callCount).toEqual 1

    it "should render layout if it changes", ->
      class SubLayout extends Joosy.Layout
      @box = new @TestPage()
      new @TestPage {}, @box
      expect(@TestPage::__bootstrap.callCount).toEqual 0
      expect(@TestPage::__bootstrapLayout.callCount).toEqual 3

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
        @box.previous.layout = new @box.previous.__layoutClass
        @box.__renderer = sinon.spy()
        @box.__layoutClass.prototype.__renderer = sinon.spy()
        @TestPage::__bootstrap.restore()
        @TestPage::__bootstrapLayout.restore()


      it "should wait stageClear and dataReceived event to start render", ->
        spies = []

        spies.push @box.__beforeRender = sinon.spy (stage, callback) ->
          expect(stage.selector).toEqual @layout.content().selector
          expect(@__oneShotEvents[0][0]).toEqual ['stageClear', 'dataReceived']
          callback()
          expect(@__oneShotEvents[0][0]).toEqual ['dataReceived']

        spies.push @box.__fetch = sinon.spy (callback) ->
          expect(@__oneShotEvents[0][0]).toEqual ['dataReceived']
          callback()
          expect(@__oneShotEvents).toEqual []

        spies.push sinon.spy(@box.previous, '__unload')

        spies.push @box.__onRender = sinon.spy (stage, callback) ->
          expect(stage.selector).toEqual @layout.content().selector
          expect(typeof callback).toEqual 'function'
          # callback()  - start rendering

        @box.__bootstrap()

        expect(spies).toBeSequenced()

      it "should render page", ->
        spies = []

        spies.push @box.__renderer
        spies.push sinon.spy(@box, 'swapContainer')
        spies.push sinon.spy(@box, '__load')

        spies.push @box.__afterRender = sinon.spy (stage) ->
          expect(stage.selector).toEqual @layout.content().selector

        @box.__bootstrap()
        expect(spies).toBeSequenced()

      it "should wait stageClear and dataReceived event to start layout render", ->
        spies = []

        spies.push ApplicationLayout::__beforeRender = sinon.spy (stage, callback) =>
          expect(stage.selector).toEqual Joosy.Application.content().selector
          expect(@box.__oneShotEvents[0][0]).toEqual ['stageClear', 'dataReceived']
          callback()
          expect(@box.__oneShotEvents[0][0]).toEqual ['dataReceived']

        spies.push @box.__fetch = sinon.spy (callback) ->
          expect(@__oneShotEvents[0][0]).toEqual ['dataReceived']
          callback()
          expect(@__oneShotEvents).toEqual []

        spies.push sinon.spy(@box.previous.layout, '__unload')
        spies.push sinon.spy(@box.previous, '__unload')

        spies.push ApplicationLayout::__onRender = sinon.spy (stage, callback) ->
          expect(stage.selector).toEqual Joosy.Application.content().selector
          expect(typeof callback).toEqual 'function'
          # callback()  - start rendering

        @box.__bootstrapLayout()

        expect(spies).toBeSequenced()

      it "should render layout and page", ->
        spies = []

        spies.push @box.__layoutClass.prototype.__renderer
        spies.push @box.__renderer
        swapContainer = sinon.spy(@box, 'swapContainer')
        spies.push @box.__layoutClass.prototype.__load = sinon.spy()
        spies.push sinon.spy(@box, '__load')

        spies.push ApplicationLayout::__afterRender = sinon.spy (stage) ->
          expect(stage.selector).toEqual Joosy.Application.content().selector

        @box.__bootstrapLayout()
        expect(spies).toBeSequenced()
        expect(swapContainer.callCount).toEqual 2
