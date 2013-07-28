describe "Joosy.Router", ->

  pathname = location.pathname

  beforeEach ->
    class @Page extends Joosy.Page

    @spies =
      responder: sinon.spy()
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

    afterEach ->
      Joosy.Router.reset()

    describe 'hash based', ->
      beforeEach ->
        @router = new Joosy.Router(html5: false)
        @router.setup(@spies.responder, false)

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
          expect(@spies.responder.callCount).toEqual 1

      it 'boots pages', ->
        runs -> @router.navigate '/page'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @Page

      it 'runs lamdas', ->
        runs -> @router.navigate '/base'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.base

      it 'responds namespaced routes', ->
        runs -> @router.navigate '/section/page/1'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.section

      it 'parses query parametrs', ->
        runs -> @router.navigate '/?test=test&foo=bar'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.root
          expect(@spies.responder.args[0][1]).toEqual {test: 'test', foo: 'bar'}

      it 'parses route placeholders', ->
        runs -> @router.navigate '/section/page/1'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.section
          expect(@spies.responder.args[0][1]).toEqual {id: '1'}

      it 'ignores restricted routes', ->
        @router.restrict /^base/

        runs -> @router.navigate '/base'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 0

      it 'defaults to wildcard route', ->
        runs -> @router.navigate '/trololo'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.wildcard

      it 'navigates', ->
        runs -> @router.navigate '/base'
        waits 0
        runs ->
          location.hash == '#/base'
          expect(@spies.responder.callCount).toEqual 1

      it 'defines plain helper', ->
        expect(Joosy.Helpers.Routes.rootPath()).toEqual '#/'
        expect(Joosy.Helpers.Routes.rootUrl()).toEqual "http://localhost:8888#{pathname}#/"

      it 'defines namespaced parameterized helpers', ->
        expect(Joosy.Helpers.Routes.sectionPagePath(id: 1)).toEqual '#/section/page/1'
        expect(Joosy.Helpers.Routes.sectionPageUrl(id: 1)).toEqual "http://localhost:8888#{pathname}#/section/page/1"

    describe 'html5 based', ->
      beforeEach ->
        @router = new Joosy.Router(html5: true)
        @router.setup(@spies.responder, false)

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
          expect(@spies.responder.callCount).toEqual 1

      it 'boots pages', ->
        runs -> @router.navigate '/page'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @Page

      it 'runs lamdas', ->
        runs -> @router.navigate '/base'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.base

      it 'responds namespaced routes', ->
        runs -> @router.navigate '/section/page/1'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.section

      it 'parses query parametrs', ->
        runs -> @router.navigate '/?test=test&foo=bar'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.root
          expect(@spies.responder.args[0][1]).toEqual {test: 'test', foo: 'bar'}

      it 'parses route placeholders', ->
        runs -> @router.navigate '/section/page/1'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.section
          expect(@spies.responder.args[0][1]).toEqual {id: '1'}

      it 'ignores restricted routes', ->
        @router.restrict /^base/

        runs -> @router.navigate '/base'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 0

      it 'defaults to wildcard route', ->
        runs -> @router.navigate '/trololo'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.wildcard

      it 'navigates', ->
        runs -> @router.navigate '/base'
        waits 0
        runs ->
          location.pathname == '/base'
          expect(@spies.responder.callCount).toEqual 1

      it 'defines plain helper', ->
        expect(Joosy.Helpers.Routes.rootPath()).toEqual '/'
        expect(Joosy.Helpers.Routes.rootUrl()).toEqual 'http://localhost:8888/'

      it 'defines namespaced parameterized helpers', ->
        expect(Joosy.Helpers.Routes.sectionPagePath(id: 1)).toEqual '/section/page/1'
        expect(Joosy.Helpers.Routes.sectionPageUrl(id: 1)).toEqual 'http://localhost:8888/section/page/1'

