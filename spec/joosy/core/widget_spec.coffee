describe "Joosy.Widget", ->

  @beforeEach ->
    Joosy.templater
      resolveTemplate: (section, template) -> template
      buildView: (template) -> (-> template) # ಠ_ಠ

  describe 'callback caller', ->
    beforeEach ->
      @spies = spies = {}
      entries = ['a', 'b', 'c', 'd']

      for instance in entries
        for filter in ['paint', 'beforePaint', 'erase', 'fetch']
          spies[instance + '/' + filter] = sinon.spy()

      class @A extends Joosy.Widget
        @view """
          <div id="content"></div>
        """

        @paint (done)       -> spies['a/paint'](); done()
        @beforePaint (done) -> spies['a/beforePaint'](); done()
        @erase (done)       -> spies['a/erase'](); done()
        @fetch (done)       -> spies['a/fetch'](); done()

      class @B extends Joosy.Widget
        @view """
          <div id="subcontent"></div>
        """

        @paint (done)       -> spies['b/paint'](); done()
        @beforePaint (done) -> spies['b/beforePaint'](); done()
        @erase (done)       -> spies['b/erase'](); done()
        @fetch (done)       -> spies['b/fetch'](); done()

      class @C extends Joosy.Widget
        @paint (done)       -> spies['c/paint'](); done()
        @beforePaint (done) -> spies['c/beforePaint'](); done()
        @erase (done)       -> spies['c/erase'](); done()
        @fetch (done)       -> spies['c/fetch'](); done()

      class @D extends Joosy.Widget
        @paint (done)       -> spies['d/paint'](); done()
        @beforePaint (done) -> spies['d/beforePaint'](); done()
        @erase (done)       -> spies['d/erase'](); done()
        @fetch (done)       -> spies['d/fetch'](); done()

      @a = new @A
      @b = new @B
      @c = new @C 'params', @b
      @d = new @D

      for instance in entries
        sinon.spy @[instance], '__load'
        sinon.spy @[instance], '__unload'

      @nestingMap =
        '#content':
          instance: @b
          nested:
            '#subcontent': {instance: @d}

    it 'calls paint callbacks', ->
      @a.__bootstrap null, @nestingMap, @$ground

      expect(@spies["a/paint"].callCount).toEqual 1
      expect(@spies["b/paint"].callCount).toEqual 0
      expect(@spies["c/paint"].callCount).toEqual 0
      expect(@spies["a/beforePaint"].callCount).toEqual 1
      expect(@spies["b/beforePaint"].callCount).toEqual 0
      expect(@spies["c/beforePaint"].callCount).toEqual 0
      expect(@spies['a/fetch'].callCount).toEqual 1
      expect(@spies['b/fetch'].callCount).toEqual 1
      expect(@spies['c/fetch'].callCount).toEqual 0
      expect(@spies['a/erase'].callCount).toEqual 0
      expect(@spies['b/erase'].callCount).toEqual 0
      expect(@spies['c/erase'].callCount).toEqual 0

      @c.__bootstrap null, {}, $('#content', @$ground)

      ['paint', 'beforePaint'].each (filter) =>
        expect(@spies["a/#{filter}"].callCount).toEqual 1
        expect(@spies["b/#{filter}"].callCount).toEqual 0
        expect(@spies["c/#{filter}"].callCount).toEqual 1

      expect(@spies['a/fetch'].callCount).toEqual 1
      expect(@spies['b/fetch'].callCount).toEqual 1
      expect(@spies['c/fetch'].callCount).toEqual 1
      expect(@spies['a/erase'].callCount).toEqual 0
      expect(@spies['b/erase'].callCount).toEqual 1
      expect(@spies['c/erase'].callCount).toEqual 0

    it 'calls load/unload callbacks', ->
      @a.__bootstrap null, @nestingMap, @$ground

      expect(@a.__load.callCount).toEqual 1
      expect(@b.__load.callCount).toEqual 1
      expect(@c.__load.callCount).toEqual 0
      expect(@d.__load.callCount).toEqual 1
      expect(@a.__unload.callCount).toEqual 0
      expect(@b.__unload.callCount).toEqual 0
      expect(@c.__unload.callCount).toEqual 0
      expect(@d.__unload.callCount).toEqual 0

      @c.__bootstrap @a, {}, $('#content', @$ground)

      expect(@a.__load.callCount).toEqual 1
      expect(@b.__load.callCount).toEqual 1
      expect(@c.__load.callCount).toEqual 1
      expect(@d.__load.callCount).toEqual 1
      expect(@a.__unload.callCount).toEqual 0
      expect(@b.__unload.callCount).toEqual 1
      expect(@c.__unload.callCount).toEqual 0
      expect(@d.__unload.callCount).toEqual 1

      @a.__unload()
      expect(@a.__load.callCount).toEqual 1
      expect(@b.__load.callCount).toEqual 1
      expect(@c.__load.callCount).toEqual 1
      expect(@d.__load.callCount).toEqual 1
      expect(@a.__unload.callCount).toEqual 1
      expect(@b.__unload.callCount).toEqual 1
      expect(@c.__unload.callCount).toEqual 1
      expect(@d.__unload.callCount).toEqual 1

  describe 'widgets manager', ->

    @beforeEach ->

      D = class @D extends Joosy.Widget
        @view "D"

      C = class @C extends Joosy.Widget
        @view "C"

      B = class @B extends Joosy.Widget
        @view """
          <div id="c"></div>
        """

        @mapWidgets
          '#c': -> C

      class @A extends Joosy.Widget
        @view """
          <div id="b"></div>
        """

        @mapWidgets
          '#b': B

    it 'bootstraps registered widgets', ->
      (new @A).__bootstrapDefault null, @$ground
      expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c">C</div></div>'

    it 'bootstraps registered independent widgets', ->
      @C.fetch (complete) -> setTimeout complete, 0
      @C.independent()

      runs ->
        (new @A).__bootstrapDefault null, @$ground
        expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c"></div></div>'

      waits 0

      runs ->
        expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c">C</div></div>'

    it 'registeres widgets on the fly', ->
      a = new @A
      a.__bootstrapDefault null, @$ground
      expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c">C</div></div>'

      d = a.registerWidget '#b', @D
      expect(d.parent).toEqual a

      expect(@$ground.html()).toEqualHTML '<div id="b">D</div>'

    it 'replaces widget', ->
      a = new @A
      a.__bootstrapDefault null, @$ground
      expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c">C</div></div>'

      d = a.registerWidget '#b', @D
      sinon.spy d, '__unload'

      c = a.replaceWidget d, @C
      expect(c.parent).toEqual a
      expect(@$ground.html()).toEqualHTML '<div id="b">C</div>'
      expect(d.__unload.callCount).toEqual 1

  describe 'synchronizer', ->

    @beforeEach ->
      class @A extends Joosy.Widget
        @view """
          <div id="b"></div>
        """

      class @B extends Joosy.Widget
        @view """
          <div id="c"></div>
          <div id="d"></div>
        """

      class @C extends Joosy.Widget
        @view """
          <div id="e"></div>
          <div id="f"></div>
        """

      class @D extends Joosy.Widget
        @view "D"

      class @E extends Joosy.Widget
        @view "E"

      class @F extends Joosy.Widget
        @view "F"

      ['a', 'b', 'c', 'd', 'e', 'f'].each (instance) =>
        @[instance] = new @[instance.toUpperCase()] 'params'

      @nestingMap =
        '#b':
          instance: @b
          nested:
            '#d': {instance: @d}
            '#c':
              instance: @c
              nested:
                '#e': {instance: @e}
                '#f': {instance: @f}

    describe 'fetcher', ->

      it 'triggers when no nesting defined', ->
        @f.__fetch(@nestingMap)
        expect(@f.__triggeredEvents?['section:fetched']).toEqual true

      it 'triggers whole dependency tree synchronously', ->
        @a.__fetch(@nestingMap)
        expect(@a.__triggeredEvents?['section:fetched']).toEqual true
        expect(@b.__triggeredEvents?['section:fetched']).toEqual true
        expect(@c.__triggeredEvents?['section:fetched']).toEqual true
        expect(@d.__triggeredEvents?['section:fetched']).toEqual true
        expect(@e.__triggeredEvents?['section:fetched']).toEqual true
        expect(@f.__triggeredEvents?['section:fetched']).toEqual true

      it 'triggers whole dependency tree asynchronously', ->
        @F.fetch (complete) -> setTimeout complete, 0
        @B.fetch (complete) -> setTimeout complete, 100

        runs ->
          @a.__fetch(@nestingMap)
          expect(@a.__triggeredEvents?['section:fetched']).toBeUndefined()
          expect(@b.__triggeredEvents?['section:fetched']).toBeUndefined()
          expect(@c.__triggeredEvents?['section:fetched']).toBeUndefined()
          expect(@d.__triggeredEvents?['section:fetched']).toEqual true
          expect(@e.__triggeredEvents?['section:fetched']).toEqual true
          expect(@f.__triggeredEvents?['section:fetched']).toBeUndefined()

        waits 0

        runs ->
          expect(@a.__triggeredEvents?['section:fetched']).toBeUndefined()
          expect(@b.__triggeredEvents?['section:fetched']).toBeUndefined()
          expect(@c.__triggeredEvents?['section:fetched']).toEqual true
          expect(@d.__triggeredEvents?['section:fetched']).toEqual true
          expect(@e.__triggeredEvents?['section:fetched']).toEqual true
          expect(@f.__triggeredEvents?['section:fetched']).toEqual true

        waits 100

        runs ->
          expect(@a.__triggeredEvents?['section:fetched']).toEqual true
          expect(@b.__triggeredEvents?['section:fetched']).toEqual true
          expect(@c.__triggeredEvents?['section:fetched']).toEqual true
          expect(@d.__triggeredEvents?['section:fetched']).toEqual true
          expect(@e.__triggeredEvents?['section:fetched']).toEqual true
          expect(@f.__triggeredEvents?['section:fetched']).toEqual true

      it 'skips independent nestings within tree', ->
        @C.fetch (complete) -> setTimeout complete, 0
        @C.independent()

        runs ->
          @a.__fetch(@nestingMap)
          expect(@a.__triggeredEvents?['section:fetched']).toEqual true
          expect(@d.__triggeredEvents?['section:fetched']).toEqual true

    describe 'bootstrap', ->

      describe 'dependent', ->

        it 'loads when no nesting defined', ->
          @f.__bootstrap null, @nestingMap, @$ground
          expect(@$ground.html()).toEqual 'F'

        it 'loads whole dependency tree synchronously', ->
          @a.__bootstrap null, @nestingMap, @$ground
          expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c"><div id="e">E</div><div id="f">F</div></div><div id="d">D</div></div>'

        it 'loads whole dependency tree asynchronously', ->
          @F.fetch (complete) -> setTimeout complete, 0
          @B.fetch (complete) -> setTimeout complete, 100

          runs ->
            @a.__bootstrap null, @nestingMap, @$ground
            expect(@$ground.html()).toEqualHTML ''

          waits 0

          runs ->
            expect(@$ground.html()).toEqualHTML ''

          waits 100

          runs ->
            expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c"><div id="e">E</div><div id="f">F</div></div><div id="d">D</div></div>'

        it 'skips independent nestings within tree', ->
          @C.fetch (complete) -> setTimeout complete, 0
          @C.independent()

          @a.__bootstrap null, @nestingMap, @$ground
          expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c"></div><div id="d">D</div></div>'

      describe 'independent', ->

        it 'loads independent children synchronously if they managed to fetch', ->
          @A.fetch (complete) -> setTimeout complete, 100

          @C.fetch (complete) -> setTimeout complete, 0
          @C.independent()

          runs ->
            @a.__bootstrap null, @nestingMap, @$ground

          waits 100

          runs ->
            expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c"><div id="e">E</div><div id="f">F</div></div><div id="d">D</div></div>'

        it 'loads whole dependency tree', ->
          @C.fetch (complete) -> setTimeout complete, 0
          @C.independent()

          @E.fetch (complete) -> setTimeout complete, 100
          @E.independent()

          runs ->
            @a.__bootstrap null, @nestingMap, @$ground
            expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c"></div><div id="d">D</div></div>'

          waits 0

          runs ->
            expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c"><div id="e"></div><div id="f">F</div></div><div id="d">D</div></div>'

          waits 100

          runs ->
            expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c"><div id="e">E</div><div id="f">F</div></div><div id="d">D</div></div>'

      describe 'mixed', ->

        it 'loads whole dependency tree', ->
          @B.fetch (complete) -> setTimeout complete, 0
          @B.independent()

          @E.fetch (complete) -> setTimeout complete, 100

          runs ->
            @a.__bootstrap null, @nestingMap, @$ground
            expect(@$ground.html()).toEqualHTML '<div id="b"></div>'

          waits 0

          runs ->
            expect(@$ground.html()).toEqualHTML '<div id="b"></div>'

          waits 100

          runs ->
            expect(@$ground.html()).toEqualHTML '<div id="b"><div id="c"><div id="e">E</div><div id="f">F</div></div><div id="d">D</div></div>'
