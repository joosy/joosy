describe "Joosy.Page", ->

  describe "manager", ->

    beforeEach ->
      @Layout = class Layout extends Joosy.Layout

      class @Page extends Joosy.Page
        @layout Layout

      sinon.stub @Page.prototype, '__bootstrap'

    afterEach ->
      @Page::__bootstrap.restore()

    it "has appropriate accessors", ->
      @Page.scroll '#here'
      expect(@Page::__scrollElement).toEqual '#here'
      expect(@Page::__scrollSpeed).toEqual 500
      expect(@Page::__scrollMargin).toEqual 0

      @Page.scroll '#there', speed: 1000, margin: -5
      expect(@Page::__scrollElement).toEqual '#there'
      expect(@Page::__scrollSpeed).toEqual 1000
      expect(@Page::__scrollMargin).toEqual -5

      @Page.layout 'test'
      expect(@Page::__layoutClass).toEqual 'test'

    it "integrates with Router", ->
      target = sinon.stub Joosy.Router, 'navigate'
      (new @Page $('#application')).navigate 'there'
      expect(target.callCount).toEqual 1
      expect(target.alwaysCalledWithExactly 'there').toBeTruthy()
      Joosy.Router.navigate.restore()

    it "respects beforeFilters cancelation", ->
      sinon.stub @Page.prototype, '__runBeforeLoads'
      @Page::__runBeforeLoads.returns(false)

      new @Page $('#application')

      expect(@Page::__bootstrap.callCount).toEqual 0

    it "loads", ->
      page = new @Page $('#application')

      spies = ['__assignElements', '__delegateEvents', '__setupWidgets', '__runAfterLoads'].map (x) ->
        sinon.spy page, x
      page.__load()
      expect(spies).toBeSequenced()

    it "unloads", ->
      page = new @Page $('#application')

      spies = ['__clearTime', '__unloadWidgets', '__removeMetamorphs', '__runAfterUnloads'].map (x) ->
        sinon.spy page, x
      page.__unload()
      expect(spies).toBeSequenced()
