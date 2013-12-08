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
      '/': @spies.root
      '/base': @spies.base
      'page': @Page
      '/section':
        '/page/:id': @spies.section
        'page2/:more': @Page
      404: @spies.wildcard

  describe 'core', ->
    afterEach ->
      Joosy.Router.reset()

    describe 'drawer', ->
      beforeEach ->
        spies = @spies
        Page  = @Page

        Joosy.Router.setup {html5: true}, (-> ), false

        Joosy.Router.draw ->
          @root to: spies.root
          @match '/base', to: spies.base
          @match '/page',  to: Page
          @namespace '/test', ->
            @match '/page', to: spies.section, as: 'test'
          @namespace '/section', {as: 'section'}, ->
            @match '/page/:id', to: spies.section, as: 'page'
            @match '/page2/:more', to: Page
          @notFound to: spies.wildcard

      it 'registeres routes', ->
        expect(Joosy.Router.routes).toEqual
          '^/?/?$':
            to: @spies.root
            as: 'root'
            capture: []
          '^/?base/?$':
            to: @spies.base
            capture: []
          '^/?page/?$':
            to: @Page, capture : []
          '^/?test/page/?$':
            to: @spies.section
            capture: []
            as: 'test'
          '^/?section/page/([^/]+)/?$':
            to: @spies.section
            as: 'sectionPage'
            capture: ['id']
          '^/?section/page2/([^/]+)/?$':
            to: @Page
            capture: ['more']

        expect(Joosy.Router.wildcardAction).toEqual @spies.wildcard

      it 'defines plain helper', ->
        expect(Joosy.Helpers.Routes.rootPath()).toEqual '/'
        expect(Joosy.Helpers.Routes.rootUrl()).toEqual "http://#{location.host}/"
        expect(Joosy.Helpers.Routes.testPath()).toEqual '/test/page'

      it 'defines namespaced parameterized helpers', ->
        expect(Joosy.Helpers.Routes.sectionPagePath(id: 1)).toEqual '/section/page/1'
        expect(Joosy.Helpers.Routes.sectionPageUrl(id: 1)).toEqual "http://#{location.host}/section/page/1"

      it 'adds helper to widgets', ->
        class A extends Joosy.Widget
          test: ->
            expect(@rootPath()).toEqual '/'
            expect(@rootUrl()).toEqual "http://#{location.host}/"

        (new A).test()

    it 'maps', ->
      Joosy.Router.map @map

      expect(Joosy.Router.routes).toEqual
        '^/?/?$':
          to: @spies.root
          as: undefined
          capture: []
        '^/?base/?$':
          to: @spies.base
          as: undefined
          capture: []
        '^/?page/?$':
          to: @Page
          capture: []
          as: undefined
        '^/?section/page/([^/]+)/?$':
          to: @spies.section
          as: undefined
          capture: ['id']
        '^/?section/page2/([^/]+)/?$':
          to: @Page
          capture: ['more']
          as: undefined

      expect(Joosy.Router.wildcardAction).toEqual @spies.wildcard

    it 'compiles plain route', ->
      Joosy.Router.compileRoute '/such/a/long/long/url/:with/:plenty/:of/:params', '123'

      expect(Joosy.Router.routes['^/?such/a/long/long/url/([^/]+)/([^/]+)/([^/]+)/([^/]+)/?$']).toEqual
        capture: ['with', 'plenty', 'of', 'params']
        to: '123'
        as: undefined

    it 'compiles aliased route', ->
      Joosy.Router.compileRoute '/such/a/long/long/url/:with/:plenty/:of/:params', '456', '123'

      expect(Joosy.Router.routes['^/?such/a/long/long/url/([^/]+)/([^/]+)/([^/]+)/([^/]+)/?$']).toEqual
        capture: ['with', 'plenty', 'of', 'params']
        to: '456'
        as: '123'

  describe 'responder', ->

    describe 'hash based', ->
      beforeEach ->
        Joosy.Router.setup {html5: false}, @spies.responder, false
        Joosy.Router.map @map

      afterEach ->
        Joosy.Router.reset()
        location.hash = ''
        waits 0

      it 'resets', ->
        runs -> Joosy.Router.navigate '/page'
        waits 0
        runs ->
          Joosy.Router.reset()
          Joosy.Router.navigate '/'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1

      it 'boots pages', ->
        runs -> Joosy.Router.navigate '/page'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @Page

      it 'runs lamdas', ->
        runs -> Joosy.Router.navigate '/base'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.base

      it 'responds namespaced routes', ->
        runs -> Joosy.Router.navigate '/section/page/1'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.section

      it 'parses query parametrs', ->
        runs -> Joosy.Router.navigate '/?test=test&foo=bar'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.root
          expect(@spies.responder.args[0][1]).toEqual {test: 'test', foo: 'bar'}

      it 'parses route placeholders', ->
        runs -> Joosy.Router.navigate '/section/page/1'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.section
          expect(@spies.responder.args[0][1]).toEqual {id: '1'}

      it 'ignores restricted routes', ->
        Joosy.Router.restrict /^base/

        runs -> Joosy.Router.navigate '/base'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 0

      it 'defaults to wildcard route', ->
        runs -> Joosy.Router.navigate '/trololo'
        waits 0
        runs ->
          expect(@spies.responder.callCount).toEqual 1
          expect(@spies.responder.args[0][0]).toEqual @spies.wildcard

      it 'navigates', ->
        runs -> Joosy.Router.navigate '/base'
        waits 0
        runs ->
          expect(location.hash).toEqual '#/base'
          expect(@spies.responder.callCount).toEqual 1

      it 'stubs', ->
        runs -> Joosy.Router.navigate '/base', respond: false
        waits 0
        runs ->
          expect(location.hash).toEqual '#/base'
          expect(@spies.responder.callCount).toEqual 0

    if history.pushState?
      describe 'html5 based', ->
        beforeEach ->
          Joosy.Router.setup {html5: true}, @spies.responder, false
          Joosy.Router.map @map

        afterEach ->
          Joosy.Router.reset()
          history.pushState {}, '', pathname
          waits 0

        it 'resets', ->
          runs -> Joosy.Router.navigate '/page'
          waits 0
          runs ->
            Joosy.Router.reset()
            Joosy.Router.navigate '/'
          waits 0
          runs ->
            expect(@spies.responder.callCount).toEqual 1

        it 'boots pages', ->
          runs -> Joosy.Router.navigate '/page'
          waits 0
          runs ->
            expect(@spies.responder.callCount).toEqual 1
            expect(@spies.responder.args[0][0]).toEqual @Page

        it 'runs lamdas', ->
          runs -> Joosy.Router.navigate '/base'
          waits 0
          runs ->
            expect(@spies.responder.callCount).toEqual 1
            expect(@spies.responder.args[0][0]).toEqual @spies.base

        it 'responds namespaced routes', ->
          runs -> Joosy.Router.navigate '/section/page/1'
          waits 0
          runs ->
            expect(@spies.responder.callCount).toEqual 1
            expect(@spies.responder.args[0][0]).toEqual @spies.section

        it 'parses query parametrs', ->
          runs -> Joosy.Router.navigate '/?test=test&foo=bar'
          waits 0
          runs ->
            expect(@spies.responder.callCount).toEqual 1
            expect(@spies.responder.args[0][0]).toEqual @spies.root
            expect(@spies.responder.args[0][1]).toEqual {test: 'test', foo: 'bar'}

        it 'parses route placeholders', ->
          runs -> Joosy.Router.navigate '/section/page/1'
          waits 0
          runs ->
            expect(@spies.responder.callCount).toEqual 1
            expect(@spies.responder.args[0][0]).toEqual @spies.section
            expect(@spies.responder.args[0][1]).toEqual {id: '1'}

        it 'ignores restricted routes', ->
          Joosy.Router.restrict /^base/

          runs -> Joosy.Router.navigate '/base'
          waits 0
          runs ->
            expect(@spies.responder.callCount).toEqual 0

        it 'defaults to wildcard route', ->
          runs -> Joosy.Router.navigate '/trololo'
          waits 0
          runs ->
            expect(@spies.responder.callCount).toEqual 1
            expect(@spies.responder.args[0][0]).toEqual @spies.wildcard

        it 'navigates', ->
          runs -> Joosy.Router.navigate '/base'
          waits 0
          runs ->
            location.pathname == '/base'
            expect(@spies.responder.callCount).toEqual 1

        it 'stubs', ->
          runs -> Joosy.Router.navigate '/base', respond: false
          waits 0
          runs ->
            location.pathname == '/base'
            expect(@spies.responder.callCount).toEqual 0

        it 'replaces', ->
          length = history.length

          runs -> Joosy.Router.navigate '/base', replace: true
          waits 0
          runs ->
            location.pathname == '/base'
            expect(@spies.responder.callCount).toEqual 1
            expect(history.length).toEqual length

  for name, val of { html5: true, hash: false }
    do (name, val) ->
      if name != 'html5' || history.pushState
        describe "#{name} prefix", ->
          afterEach ->
            Joosy.Router.reset()
            location.hash = ''
            history.pushState?({}, '', pathname)
            waits 0

          beforeEach ->
            Joosy.Router.setup {html5: val, prefix: 'admin', hashSuffix: 'admin'}, @spies.responder, false
            Joosy.Router.map @map

          it "is considered in path without prefix", ->
            runs -> Joosy.Router.navigate '/base'
            waits 0
            runs ->
              expect(@spies.responder.callCount).toEqual 1
              expect(@spies.responder.args[0][0]).toEqual @spies.base

          it "is considered in path with prefix", ->
            runs -> Joosy.Router.navigate '/admin/base'
            waits 0
            runs ->
              expect(@spies.responder.callCount).toEqual 1
              expect(@spies.responder.args[0][0]).toEqual @spies.base

          it "is considered in root path", ->
            runs -> Joosy.Router.navigate '/admin'
            waits 0
            runs ->
              expect(@spies.responder.callCount).toEqual 1
              expect(@spies.responder.args[0][0]).toEqual @spies.root

  describe 'linker', ->
    it 'defines helper', ->
      tag = Joosy.Helpers.Application.linkTo 'test', '/base', class: 'zomg!'

      expect(tag).toBeTag 'a', 'test',
        'data-joosy': 'true'
        href: '/base'
        class: 'zomg!'

    it 'navigates', ->
      sinon.stub Joosy.Router, 'navigate'

      @$ground.html """
                    <a href='#' id='test1'></a>
                    <a href='#' id='test2' data-joosy='true'></a>
                    """
      $('#test1').click()
      $('#test2').click()

      expect(Joosy.Router.navigate.callCount).toEqual 1
      Joosy.Router.navigate.restore()
