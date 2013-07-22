describe "Joosy.Page", ->

  describe "manager", ->

    beforeEach ->
      @Layout = class Layout extends Joosy.Layout

      class @Page extends Joosy.Page
        @layout Layout

      sinon.stub @Page.prototype, '__bootstrap'
      sinon.stub @Page.prototype, '__bootstrapLayout'

    afterEach ->
      @Page::__bootstrap.restore()
      @Page::__bootstrapLayout.restore()

    it "has appropriate accessors", ->
      callbackNames = ['beforePaint', 'paint', 'afterPaint', 'erase']
      callbackNames.each (callbackName) =>
        @Page[callbackName] 'callback'
        expect(@Page::['__' + callbackName]).toEqual 'callback'

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
      (new @Page).navigate 'there'
      expect(target.callCount).toEqual 1
      expect(target.alwaysCalledWithExactly 'there').toBeTruthy()
      Joosy.Router.navigate.restore()

    it "respects beforeFilters cancelation", ->
      sinon.stub @Page.prototype, '__runBeforeLoads'
      @Page::__runBeforeLoads.returns(false)

      new @Page

      expect(@Page::__bootstrap.callCount).toEqual 0
      expect(@Page::__bootstrapLayout.callCount).toEqual 0

    describe "layout switcher", ->

      beforeEach ->
        @page = new @Page
        @page.layout = new @Layout

      it "does not render when previous layout is the same", ->
        new @Page {}, @page

        expect(@Page::__bootstrap.callCount).toEqual 1
        expect(@Page::__bootstrapLayout.callCount).toEqual 1

      it "renders when previous layout is another class", ->
        class Layout extends Joosy.Layout
        class Page extends Joosy.Page
          @layout Layout

        sinon.stub Page.prototype, '__bootstrap'
        sinon.stub Page.prototype, '__bootstrapLayout'

        new Page {}, @page

        expect(@Page::__bootstrap.callCount).toEqual 0
        expect(@Page::__bootstrapLayout.callCount).toEqual 1
        expect(Page::__bootstrap.callCount).toEqual 0
        expect(Page::__bootstrapLayout.callCount).toEqual 1

    it "loads", ->
      page = new @Page

      spies = []
      spies.push sinon.spy(page, '__assignElements')
      spies.push sinon.spy(page, '__delegateEvents')
      spies.push sinon.spy(page, '__setupWidgets')
      spies.push sinon.spy(page, '__runAfterLoads')
      page.__load()
      expect(spies).toBeSequenced()

    it "unloads", ->
      page = new @Page

      spies = []
      spies.push sinon.spy(page, '__clearTime')
      spies.push sinon.spy(page, '__unloadWidgets')
      spies.push sinon.spy(page, '__removeMetamorphs')
      spies.push sinon.spy(page, '__runAfterUnloads')
      page.__unload()
      expect(spies).toBeSequenced()

  describe "rendering", ->

    beforeEach ->
      # Layouts inject themselves into `Joosy.Application.content`
      # so let's make them inject where we want
      sinon.stub Joosy.Application, 'content'
      Joosy.Application.content.returns @$ground

      # We test every module separately so there's no need to run all those
      sinon.stub Joosy.Page.prototype, '__load'
      sinon.stub Joosy.Page.prototype, '__unload'
      sinon.stub Joosy.Layout.prototype, '__load'
      sinon.stub Joosy.Layout.prototype, '__unload'

    afterEach ->
      Joosy.Application.content.restore()
      Joosy.Page::__load.restore()
      Joosy.Page::__unload.restore()
      Joosy.Layout::__load.restore()
      Joosy.Layout::__unload.restore()

    it "renders", ->
      class Layout extends Joosy.Layout
        @view (locals) -> locals.page 'div', class: 'layout'

      class Page extends Joosy.Page
        @layout Layout
        @view (locals) -> 'page'

      page = new Page
      expect(@$ground.html()).toMatch /<div class\=\"layout\" id=\"__joosy\d+\">page<\/div>/

    it "changes page", ->
      class Layout extends Joosy.Layout
        @view (locals) -> locals.page 'div'

      class PageA extends Joosy.Page
        @layout Layout
        @view (locals) -> 'page a'

      class PageB extends Joosy.Page
        @layout Layout
        @view (locals) -> 'page b'

      page = new PageA
      expect(@$ground.html()).toMatch /<div id=\"__joosy\d+\">page a<\/div>/

      page = new PageB {}, page
      expect(@$ground.html()).toMatch /<div id=\"__joosy\d+\">page b<\/div>/

    it "changes layout", ->
      class LayoutA extends Joosy.Layout
        @view (locals) -> locals.page 'div'

      class PageA extends Joosy.Page
        @layout LayoutA
        @view (locals) -> ''

      class LayoutB extends Joosy.Layout
        @view (locals) -> locals.page 'div'

      class PageB extends Joosy.Page
        @layout LayoutB
        @view (locals) -> ''

      page = new PageA
      html = @$ground.html()
      expect(html).toMatch /<div id=\"__joosy\d+\"><\/div>/

      page = new PageB {}, page
      expect(@$ground.html()).toMatch /<div id=\"__joosy\d+\"><\/div>/
      expect(@$ground.html()).not.toEqual html

    it "proxies @params to layout", ->
      class Layout extends Joosy.Layout
        @view (locals) -> locals.page 'div', class: 'layout'

        constructor: (@params) ->
          expect(@params).toEqual foo: 'bar'
          super

      class Page extends Joosy.Page
        @layout Layout
        @view (locals) -> 'page'

      page = new Page foo: 'bar'

    it "passes @data to @view", ->
      class Layout extends Joosy.Layout
        @fetch (complete) ->
          expect(@data).toEqual {}
          @data.foo = 'bar'
          complete()

        @view (locals) ->
          expect(locals.foo).toEqual 'bar'

      class Page extends Joosy.Page
        @layout Layout

        @fetch (complete) ->
          expect(@data).toEqual {}
          @data.foo = 'bar'
          complete()

        @view (locals) ->
          expect(locals.foo).toEqual 'bar'

      page = new Page

    it "hooks", ->
      spies = []
      11.times -> spies.push sinon.spy()

      class Layout extends Joosy.Layout
        @beforePaint (container, page, complete) -> spies[0](); complete()
        @fetch       (complete)                  -> spies[1](); complete()
        @paint       (container, page, complete) -> spies[3](); complete()

        @view spies[4]

      class PageA extends Joosy.Page
        @layout Layout

        @fetch       (complete)            -> spies[2](); complete()
        @erase       (container, complete) -> spies[6](); complete()
        @view spies[5]

      class PageB extends Joosy.Page
        @layout Layout

        @beforePaint (container, complete) -> spies[7](); complete()
        @fetch       (complete)            -> spies[8](); complete()
        @paint       (container, complete) -> spies[9](); complete()

        @view spies[10]

      page = new PageA
      page = new PageB {}, page

      expect(spies).toBeSequenced()
