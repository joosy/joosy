describe "Joosy.Application", ->

  beforeEach ->
    sinon.stub Joosy.Router, "setup"
    @$ground.seed()

  afterEach ->
    Joosy.Router.setup.restore()
    Joosy.Application.reset()

  it "initializes", ->
    Joosy.Application.initialize '#application', foo: {bar: 'baz'}
    expect(Joosy.Application.page).toBeUndefined()
    expect(Joosy.Application.selector).toEqual '#application'
    expect(Joosy.Router.setup.callCount).toEqual 1
    expect(Joosy.Application.config.foo.bar).toEqual 'baz'
    expect(Joosy.Application.content()).toEqual $('#application')

  it "merges config", ->
    Joosy.Application.initialize '#application', router: {html5: true}
    expect(Joosy.Application.config.router.html5).toEqual true
    expect(Joosy.Application.config.router.base).toEqual ''

  describe "page changer", ->
    beforeEach ->
      Joosy.Application.initialize @$ground

      class @Layout extends Joosy.Layout
        @view (locals) -> locals.page 'div'

      class @Page extends Joosy.Page
        @view -> "page"

    it "sets page to clean ground", ->
      Joosy.Application.changePage(@Page, {foo: 'bar'})
      expect(Joosy.Application.page instanceof @Page).toBeTruthy()
      expect(Joosy.Application.page.params).toEqual foo: 'bar'
      expect(@$ground.html()).toEqual 'page'

    it "changes from page to page", ->
      Joosy.Application.changePage(@Page, {foo: 'bar'})
      expect(@$ground.html()).toEqual 'page'
      page = Joosy.Application.page

      Joosy.Application.changePage(@Page, {foo: 'bar'})
      expect(@$ground.html()).toEqual 'page'
      expect(Joosy.Application.page.previous).toEqual page

    it "sets layouted page to clean ground", ->
      @Page.layout @Layout

      Joosy.Application.changePage(@Page, {foo: 'bar'})
      expect(Joosy.Application.page instanceof @Page).toBeTruthy()
      expect(Joosy.Application.page.params).toEqual foo: 'bar'
      expect(Joosy.Application.page.layout.params).toEqual foo: 'bar'
      expect(@$ground.html()).toBeTag 'div', 'page', id: /__joosy\d+/

    it "changes from layouted page to layouted page", ->
      @Page.layout @Layout

      Joosy.Application.changePage(@Page, {foo: 'bar'})
      expect(@$ground.html()).toBeTag 'div', 'page', id: /__joosy\d+/
      page   = Joosy.Application.page
      layout = page.layout

      Joosy.Application.changePage(@Page, {foo: 'bar'})
      expect(@$ground.html()).toBeTag 'div', 'page', id: /__joosy\d+/
      expect(Joosy.Application.page.previous).toEqual page
      expect(Joosy.Application.page.layout).toEqual layout

    it "changes from layouted page to page", ->
      @Page.layout @Layout

      Joosy.Application.changePage(@Page, {foo: 'bar'})
      expect(@$ground.html()).toBeTag 'div', 'page', id: /__joosy\d+/
      page   = Joosy.Application.page
      layout = page.layout

      class Page extends Joosy.Page
        @view -> "page"

      Joosy.Application.changePage(Page, {foo: 'bar'})
      expect(@$ground.html()).toEqual 'page'
      expect(Joosy.Application.page.previous).toEqual layout
      expect(Joosy.Application.page.layout).toBeUndefined()

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

      Joosy.Application.changePage Page

    it "hooks", ->
      spies = []
      11.times -> spies.push sinon.spy()

      class Layout extends Joosy.Layout
        @beforePaint (complete) -> spies[0](); complete()
        @fetch       (complete) -> spies[2](); complete()
        @paint       (complete) -> spies[3](); complete()

        @view spies[4]

      class PageA extends Joosy.Page
        @layout Layout

        @fetch       (complete) -> spies[1](); complete()
        @erase       (complete) -> spies[6](); complete()
        @view spies[5]

      class PageB extends Joosy.Page
        @layout Layout

        @beforePaint (complete) -> spies[7](); complete()
        @fetch       (complete) -> spies[8](); complete()
        @paint       (complete) -> spies[9](); complete()

        @view spies[10]

      Joosy.Application.changePage PageA
      Joosy.Application.changePage PageB

      expect(spies).toBeSequenced()