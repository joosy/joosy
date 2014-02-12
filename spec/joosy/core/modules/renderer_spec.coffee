describe "Joosy.Modules.Renderer", ->

  beforeEach ->
    class @Renderer extends Joosy.Module
      @concern Joosy.Modules.Renderer
      @include Joosy.Modules.TimeManager

    @renderer = new @Renderer

  it "renders default template", ->
    template = sinon.stub()
    template.returns "result"

    @Renderer.view template

    expect(@renderer.__renderDefault(foo: 'bar')).toEqual 'result'
    expect(template.getCall(0).args[0].foo).toEqual 'bar'
    expect(template.getCall(0).args[0].__renderer).toEqual @renderer

  describe "rendering", ->
    beforeEach ->
      @template = (locals) =>
        expect(locals.foo).toEqual 'bar'
        expect(locals.__renderer).toEqual @renderer
        "result"

    it "accepts lambda", ->
      expect(@renderer.render @template, foo: 'bar').toEqual 'result'

    it "expects templater definition", ->
      expect(=> @renderer.render 'template', foo: 'bar').toThrow()

    it "accepts template", ->
      Joosy.templater
        buildView: ->
          -> 'result'

      expect(@renderer.render 'template', foo: 'bar').toEqual 'result'

      Joosy.templater false

    it "runs constructor", ->
      callback = sinon.spy()
      template = (locals) =>
        locals.onRendered callback
        'result'

      runs ->
        expect(@renderer.render template).toEqual 'result'

      waits 0

      runs ->
        expect(callback.callCount).toEqual 1

    it "runs destructor", ->
      callback = sinon.spy()
      template = (locals) =>
        locals.onRemoved callback
        'result'

      runs ->
        expect(@renderer.render template).toEqual 'result'

      waits 0

      runs ->
        expect(callback.callCount).toEqual 0
        @renderer.__destructRenderingStack()
        expect(callback.callCount).toEqual 1

  describe "dynamic rendering", ->
    beforeEach ->
      # Instance we are going to use to trigger dynamic rendering
      class @Entity extends Joosy.Module
        @include Joosy.Modules.Events

        constructor: (@value) ->

        update: (@value) ->
          @trigger 'changed'

      @entity = new @Entity("initial")

    it "updates content", ->
      template = (locals) -> locals.entity.value

      runs ->
        @$ground.html @renderer.renderDynamic(template, entity: @entity)
        expect(@$ground.text()).toBe "initial"

      runs ->
        @entity.update "new"

      waits 0

      runs ->
        expect(@$ground.text()).toBe "new"

    it "runs callback during update", ->
      template = (locals) -> locals.entity.value
      callback = sinon.spy()

      runs ->
        @$ground.html @renderer.renderDynamic(template, {entity: @entity}, callback)
        expect(@$ground.text()).toBe "initial"
        expect(callback.callCount).toEqual 0

      runs ->
        @entity.update "new"

      waits 0

      runs ->
        expect(@$ground.text()).toBe "new"
        expect(callback.callCount).toEqual 1

    it "does not update unloaded content", ->
      template = (locals) -> locals.entity.value

      runs ->
        @$ground.html @renderer.renderDynamic(template, entity: @entity)
        expect(@$ground.text()).toBe "initial"
        @renderer.__destructRenderingStack()

      runs ->
        @entity.update "new"

      waits 0

      runs ->
        expect(@$ground.text()).toBe "initial"

    it "runs constructor", ->
      callback = sinon.spy()
      template = (locals) =>
        locals.onRendered callback
        locals.entity.value

      runs ->
        @$ground.html @renderer.renderDynamic(template, entity: @entity)
        expect(@$ground.text()).toBe "initial"

      waits 0

      runs ->
        expect(callback.callCount).toEqual 1

      runs ->
        @entity.update "new"

      waits 0

      runs ->
        expect(@$ground.text()).toBe "new"
        expect(callback.callCount).toEqual 1

    it "runs destructor", ->
      callback = sinon.spy()
      template = (locals) =>
        locals.onRemoved callback
        locals.entity.value

      runs ->
        @$ground.html @renderer.renderDynamic(template, entity: @entity)
        expect(@$ground.text()).toBe "initial"

      waits 0

      runs ->
        expect(callback.callCount).toEqual 0
        @entity.update "new"

      waits 0

      runs ->
        expect(@$ground.text()).toBe "new"
        expect(callback.callCount).toEqual 1
        @entity.update "new 2"

      waits 0

      runs ->
        expect(@$ground.text()).toBe "new 2"
        expect(callback.callCount).toEqual 2

    describe "Metamorph magic", ->
      beforeEach ->
        sinon.spy window, 'Metamorph'

        template = (locals) -> locals.entity.value
        @$ground.html @renderer.renderDynamic(template, entity: @entity)

        # With this we intercept calls to Metamorph updates
        @updater = sinon.spy window.Metamorph.returnValues[0], 'html'

      afterEach ->
        Metamorph.restore()

      it "debounces", ->
        @entity.update "new"
        @entity.update "don't make"
        @entity.update "me evil"

        waits 0

        runs ->
          expect(@updater.callCount).toEqual 1
          expect(@$ground.text()).toEqual "me evil"

      it "catches manually removed nodes", ->
        @$ground.html ''

        @entity.update "new"
        @entity.update "don't make"
        @entity.update "me evil"

        waits 0

        runs ->
          expect(@updater.callCount).toEqual 0

  describe "helpers includer", ->

    it "works with modules", ->
      Joosy.namespace 'Joosy.Helpers.Hoge', ->
        @multiplier = (value) -> "#{value * 5}"

      @Renderer.helper Joosy.Helpers.Hoge
      template = (locals) -> locals.multiplier(10)

      expect(@renderer.render template).toBe "50"

    it "works with local methods", ->
      @Renderer::multiplier = (value) -> "#{value * 10}"
      @Renderer.helper 'multiplier'
      template = (locals) -> locals.multiplier(10)

      expect(@renderer.render template).toBe "100"
      delete @Renderer::multiplier

    it "works with globals", ->
      Joosy.Helpers.Application.multiplier = (value) -> "#{value * 3}"
      template = (locals) -> locals.multiplier(10)

      expect(@renderer.render template).toBe "30"
      delete Joosy.Helpers.Application.multiplier

