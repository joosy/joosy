describe "Joosy.Modules.DOM", ->

  beforeEach ->
    @$ground.seed()
    container = @$ground.find('#application')

    class @DOM extends Joosy.Module
      @include Joosy.Modules.DOM

      @mapElements
        posts: '.post'
        content:
          post1: '#post1'
          post2: '#post2'
        footer: '.footer'

      @mapEvents
        'test': 'onDOMTest'

      $container: container

  describe "elements assigner", ->

    beforeEach ->
      @dom = new @DOM
      @dom.__assignElements()

    it "declares", ->
      class A extends @DOM
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

      expect((new @DOM).__elements).toEqual Object.extended
        posts: '.post'
        footer: '.footer'
        content: 
          post1: '#post1'
          post2: '#post2'

    describe "selector resolvance", ->

      it "works for plane selectors", ->
        expect(@dom.__extractSelector '$footer').toEqual '.footer'

      it "works for deep selectors", ->
        expect(@dom.__extractSelector '$content.$post1').toEqual '#post1'

      it "works for plane extended selectors", ->
        expect(@dom.__extractSelector '$footer tr').toEqual '.footer tr'

      it "works for deep extended selectors", ->
        expect(@dom.__extractSelector '$footer $content.$post1').toEqual '.footer #post1'

    it "assigns", ->
      target = @dom.$footer().get 0
      expect(target).toBeTruthy()
      expect(target).toBe $('.footer', @dom.$container).get 0
      expect(target).toBe @dom.$('.footer').get 0

    it "assigns nesteds", ->
      expect(@dom.$content.$post1().get 0).toBe $('#post1').get 0

    it "changes assignation context", ->
      target = @dom.$posts(@dom.$container).get 0
      expect(target).toBeTruthy()
      expect(target).toBe $('#post1', @dom.$container).get 0

    it "respects container boundaries", ->
      @$ground.prepend('<div class="footer" />')  # out of container

      target = @dom.$footer().get 0
      expect(target).toBeTruthy()
      expect(target).toBe $('.footer', @dom.$container).get 0
      expect(target).toBe @dom.$('.footer').get 0

  describe "events delegator", ->

    it "declares", ->
      class A extends @DOM
        @mapEvents
          'test .post': 'callback2'
          'custom' : 'method'

      class B extends A
        @mapEvents
          'test $footer': 'onFooterTest'
          'custom' : 'overrided'

      expect((new B).__events).toEqual Object.extended
        'test': 'onDOMTest'
        'test .post': 'callback2'
        'test $footer': 'onFooterTest'
        'custom' : 'overrided'

      expect((new @DOM).__events).toEqual Object.extended
        'test': 'onDOMTest'

    it "delegates", ->
      callbacks = 1.upto(3).map -> sinon.spy()

      @DOM.mapEvents
        'test .post': callbacks[2]
        'test $footer': 'onFooterTest'
      @DOM::onDOMTest = callbacks[0]
      @DOM::onFooterTest = callbacks[1]

      dom = new @DOM
      dom.__assignElements()
      dom.__delegateEvents()

      dom.$container.trigger 'test'
      $('.footer', dom.$container).trigger 'test'
      $('.post', dom.$container).trigger 'test'

      expect(callbacks[0].callCount).toEqual 5
      expect(callbacks[1].callCount).toEqual 1
      expect(callbacks[2].callCount).toEqual 3
