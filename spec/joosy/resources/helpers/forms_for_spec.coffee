describe "Joosy.Helpers.FormFor", ->
  class Test extends Joosy.Resources.REST
    @entity 'test'

  class Renderer extends Joosy.Module
    @concern Joosy.Modules.Renderer
    @include Joosy.Modules.TimeManager

  beforeEach ->
    @renderer = new Renderer
    @resource = new Test(id: 1, string: 'data', positive: true, negative: false)
    @render   = (template) ->
      runs ->
        @$ground.html @renderer.render(template, {resource: @resource})
        @$form = $(@$ground.find('form'))
      waits 0

  describe "wrapper rendering", ->
    it "outputs default form", ->
      @render (x) -> x.formFor x.resource
      runs -> expect(@$ground.html()).toBeTag 'form', '', id: /__joosy\d+/

    it "respects url property", ->
      @render (x) -> x.formFor x.resource, {url: 'test'}
      runs -> expect(@$ground.html()).toBeTag 'form', '', id: /__joosy\d+/, action: 'test'

    it "respects html property", ->
      @render (x) -> x.formFor x.resource, {html: {class: 'test'}}
      runs -> expect(@$ground.html()).toBeTag 'form', '', id: /__joosy\d+/, class: 'test'

    it "respects inline content with attributes given", ->
      @render (x) -> x.formFor(x.resource, {}, -> 'test')
      runs -> expect(@$ground.html()).toBeTag 'form', 'test', id: /__joosy\d+/

    it "respects inline content without attributes given", ->
      @render (x) -> x.formFor(x.resource, -> 'test')
      runs -> expect(@$ground.html()).toBeTag 'form', 'test', id: /__joosy\d+/

  describe "fields rendering", ->
    for type in [ 'text', 'file', 'hidden', 'password' ]
      do (type) =>
        it "renders #{type}Field", ->
          @render (x) ->
            x.formFor x.resource, (f) ->
              f["#{type}Field"] 'string'

          runs ->
            expect(@$form.html()).toBeTag 'input', '',
              value: 'data'
              type: type
              id: 'test_1_string'
              name: 'string1'
              'data-to': 'string'
              'data-form': /__joosy\d+/

    it "renders label", ->
      @render (x) ->
        x.formFor x.resource, (f) ->
          f.label 'string', ->
            'test'

      runs ->
        expect(@$form.html()).toBeTag 'label', 'test',
          for: 'test_1_string'