describe "Joosy.Router", ->

  pathname = location.pathname

  beforeEach ->
    class @Page extends Joosy.Page

    @spies =
      root: sinon.spy()
      base: sinon.spy()
      section: sinon.spy()
      wildcard: sinon.spy()

    @map =
      '/': to: @spies.root, as: 'root'
      '/base': @spies.base
      'page': @Page
      '/section':
        '/page/:id': to: @spies.section, as: 'sectionPage'
        'page2/:more': @Page
      404: @spies.wildcard

  describe 'core', ->
    beforeEach ->
      @router = new Joosy.Router

    it 'draws', ->
      spies = @spies
      Page  = @Page

      Joosy.Router.draw ->
        @root to: spies.root
        @match '/base', to: spies.base
        @match '/page',  to: Page
        @namespace '/section', {as: 'section'}, ->
          @match '/page/:id', to: spies.section, as: 'page'
          @match '/page2/:more', to: Page
        @notFound to: spies.wildcard

      expect(Joosy.Router.routes).toEqual 
        '/': to: @spies.root, as: 'root'
        '/base': @spies.base
        '/page': @Page
        '/section/page/:id': to: @spies.section, as: 'sectionPage'
        '/section/page2/:more': @Page
        404: @spies.wildcard

      Joosy.Router.reset()

    it 'maps', ->
      Joosy.Router.map @map
      expect(Joosy.Router.routes).toEqual @map
      Joosy.Router.reset()

    it 'compiles plain route', ->
      route = @router.compileRoute "/such/a/long/long/url/:with/:plenty/:of/:params", "123"

      expect(route).toEqual
        '^/?such/a/long/long/url/([^/]+)/([^/]+)/([^/]+)/([^/]+)/?$':
          capture: ['with', 'plenty', 'of', 'params']
          to: '123'

    it 'compiles aliased route', ->
      route = @router.compileRoute "/such/a/long/long/url/:with/:plenty/:of/:params", {as: "123", to: "456"}

      expect(route).toEqual
        '^/?such/a/long/long/url/([^/]+)/([^/]+)/([^/]+)/([^/]+)/?$':
          capture: ['with', 'plenty', 'of', 'params']
          to: '456'
          as: '123'

  describe 'responder', ->
    beforeEach ->
      Joosy.Router.map @map
      sinon.stub Joosy.Application, 'setCurrentPage'

    afterEach ->
      Joosy.Router.reset()
      Joosy.Application.setCurrentPage.restore()

    describe 'hash based', ->
      beforeEach ->
        @router = new Joosy.Router(html5: false)
        @router.setup(false)

      afterEach ->
        Joosy.Router.reset()
        location.hash = ''
        waits 0

      it 'resets', ->
        runs -> @router.navigate '/page'
        waits 0
        runs ->
          Joosy.Router.reset()
          @router.navigate '/'
        waits 0
        runs ->
          expect(Joosy.Application.setCurrentPage.callCount).toEqual 1
          expect(@spies.root.callCount).toEqual 0

      it 'boots pages', ->
        runs -> @router.navigate '/page'
        waits 0
        runs -> expect(Joosy.Application.setCurrentPage.callCount).toEqual 1

      it 'runs lamdas', ->
        runs -> @router.navigate '/base'
        waits 0
        runs -> expect(@spies.base.callCount).toEqual 1

      it 'responds namespaced routes', ->
        runs -> @router.navigate '/section/page/1'
        waits 0
        runs -> expect(@spies.section.callCount).toEqual 1

      it 'parses query parametrs', ->
        runs -> @router.navigate '/?test=test&foo=bar'
        waits 0
        runs ->
          expect(@spies.root.callCount).toEqual 1
          expect(@spies.root.args.last()).toEqual [test: 'test', foo: 'bar']

      it 'parses route placeholders', ->
        runs -> @router.navigate '/section/page/1'
        waits 0
        runs ->
          expect(@spies.section.callCount).toEqual 1
          expect(@spies.section.args.last()).toEqual [id: '1']

      it 'ignores restricted routes', ->
        @router.restrict /^base/

        runs -> @router.navigate '/base'
        waits 0
        runs -> expect(@spies.base.callCount).toEqual 0

      it 'defaults to wildcard route', ->
        runs -> @router.navigate '/trololo'
        waits 0
        runs ->
          expect(@spies.wildcard.callCount).toEqual 1

      it 'navigates', ->
        runs -> @router.navigate '/base'
        waits 0
        runs ->
          location.hash == '#/base'
          expect(@spies.base.callCount).toEqual 1

      it 'defines plain helper', ->
        expect(Joosy.Helpers.Application.rootPath()).toEqual '#/'
        expect(Joosy.Helpers.Application.rootUrl()).toEqual "http://localhost:8888#{pathname}#/"

      it 'defines namespaced parameterized helpers', ->
        expect(Joosy.Helpers.Application.sectionPagePath(id: 1)).toEqual '#/section/page/1'
        expect(Joosy.Helpers.Application.sectionPageUrl(id: 1)).toEqual "http://localhost:8888#{pathname}#/section/page/1"

    describe 'html5 based', ->
      beforeEach ->
        @router = new Joosy.Router(html5: true)
        @router.setup(false)

      afterEach ->
        Joosy.Router.reset()
        history.pushState {}, '', pathname
        waits 0

      it 'resets', ->
        runs -> @router.navigate '/page'
        waits 0
        runs ->
          Joosy.Router.reset()
          @router.navigate '/'
        waits 0
        runs ->
          expect(Joosy.Application.setCurrentPage.callCount).toEqual 1
          expect(@spies.root.callCount).toEqual 0

      it 'boots pages', ->
        runs -> @router.navigate '/page'
        waits 0
        runs -> expect(Joosy.Application.setCurrentPage.callCount).toEqual 1

      it 'runs lamdas', ->
        runs -> @router.navigate '/base'
        waits 0
        runs -> expect(@spies.base.callCount).toEqual 1

      it 'responds namespaced routes', ->
        runs -> @router.navigate '/section/page/1'
        waits 0
        runs -> expect(@spies.section.callCount).toEqual 1

      it 'parses query parametrs', ->
        runs -> @router.navigate '/?test=test&foo=bar'
        waits 0
        runs ->
          expect(@spies.root.callCount).toEqual 1
          expect(@spies.root.args.last()).toEqual [test: 'test', foo: 'bar']

      it 'parses route placeholders', ->
        runs -> @router.navigate '/section/page/1'
        waits 0
        runs ->
          expect(@spies.section.callCount).toEqual 1
          expect(@spies.section.args.last()).toEqual [id: '1']

      it 'ignores restricted routes', ->
        @router.restrict /^base/

        runs -> @router.navigate '/base'
        waits 0
        runs -> expect(@spies.base.callCount).toEqual 0

      it 'defaults to wildcard route', ->
        runs -> @router.navigate '/trololo'
        waits 0
        runs ->
          expect(@spies.wildcard.callCount).toEqual 1

      it 'navigates', ->
        runs -> @router.navigate '/base'
        waits 0
        runs ->
          location.pathname == '/base'
          expect(@spies.base.callCount).toEqual 1

      it 'defines plain helper', ->
        expect(Joosy.Helpers.Application.rootPath()).toEqual '/'
        expect(Joosy.Helpers.Application.rootUrl()).toEqual 'http://localhost:8888/'

      it 'defines namespaced parameterized helpers', ->
        expect(Joosy.Helpers.Application.sectionPagePath(id: 1)).toEqual '/section/page/1'
        expect(Joosy.Helpers.Application.sectionPageUrl(id: 1)).toEqual 'http://localhost:8888/section/page/1'

