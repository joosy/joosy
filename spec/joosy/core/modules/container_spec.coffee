describe "Joosy.Modules.Container", ->

  beforeEach ->
    @$ground.seed()
    container = @$ground.find('#application')

    class @Container extends Joosy.Module
      @include Joosy.Modules.Container

      @mapElements
        posts: '.post'
        content:
          post1: '#post1'
          post2: '#post2'
        footer: '.footer'

      @mapEvents
        'test': 'onContainerTest'

      container: container

  describe "elements assigner", ->

    beforeEach ->
      @container = new @Container
      @container.__assignElements()

    it "declares", ->
      class A extends @Container
        @mapElements
          first: 'first'
          second: 'second'

      class B extends A
        @mapElements
          first: 'overrided'
          third: 'third'

      expect((new B).__elements).toEqual Object.extended
        posts: '.post'
        content: 
          post1: '#post1'
          post2: '#post2'
        first: 'overrided'
        second: 'second'
        third: 'third'
        footer: '.footer'

      expect((new @Container).__elements).toEqual Object.extended
        posts: '.post'
        footer: '.footer'
        content: 
          post1: '#post1'
          post2: '#post2'

    describe "selector resolvance", ->

      it "works for plane selectors", ->
        expect(@container.__extractSelector '$footer').toEqual '.footer'

      it "works for deep selectors", ->
        expect(@container.__extractSelector '$content.$post1').toEqual '#post1'

      it "works for plane extended selectors", ->
        expect(@container.__extractSelector '$footer tr').toEqual '.footer tr'

      it "works for deep extended selectors", ->
        expect(@container.__extractSelector '$footer $content.$post1').toEqual '.footer #post1'

    it "assigns", ->
      target = @container.$footer().get 0
      expect(target).toBeTruthy()
      expect(target).toBe $('.footer', @container.container).get 0
      expect(target).toBe @container.$('.footer').get 0

    it "assigns nesteds", ->
      expect(@container.$content.$post1().get 0).toBe $('#post1').get 0

    it "filters assignation", ->
      target = @container.$posts('#post1').get 0
      expect(target).toBeTruthy()
      expect(target).toBe $('#post1', @container.container).get 0

    it "respects container boundaries", ->
      @$ground.prepend('<div class="footer" />')  # out of container

      target = @container.$footer().get 0
      expect(target).toBeTruthy()
      expect(target).toBe $('.footer', @container.container).get 0
      expect(target).toBe @container.$('.footer').get 0

  describe "events delegator", ->

    it "declares", ->
      class A extends @Container
        @mapEvents
          'test .post': 'callback2'
          'custom' : 'method'

      class B extends A
        @mapEvents
          'test $footer': 'onFooterTest'
          'custom' : 'overrided'

      expect((new B).__events).toEqual Object.extended
        'test': 'onContainerTest'
        'test .post': 'callback2'
        'test $footer': 'onFooterTest'
        'custom' : 'overrided'

      expect((new @Container).__events).toEqual Object.extended
        'test': 'onContainerTest'

    it "delegates", ->
      callbacks = 1.upto(3).map -> sinon.spy()

      @Container.mapEvents
        'test .post': callbacks[2]
        'test $footer': 'onFooterTest'
      @Container::onContainerTest = callbacks[0]
      @Container::onFooterTest = callbacks[1]

      container = new @Container
      container.__assignElements()
      container.__delegateEvents()

      container.container.trigger 'test'
      $('.footer', container.container).trigger 'test'
      $('.post', container.container).trigger 'test'

      expect(callbacks[0].callCount).toEqual 5
      expect(callbacks[1].callCount).toEqual 1
      expect(callbacks[2].callCount).toEqual 3
