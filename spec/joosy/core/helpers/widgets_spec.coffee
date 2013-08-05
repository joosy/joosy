describe "Joosy.Helpers.Widgets", ->

  beforeEach ->
    @$ground.seed()

    # Widget we are going to include using helper
    class @Widget extends Joosy.Widget
      @view -> "test"

    class @Renderer extends Joosy.Page

    @renderer = new @Renderer
    @widget   = new @Widget
    @template = (context) =>
      context.widget 'div', @widget

  it "renders widget tag", ->
    runs ->
      @$ground.find('#header').html @renderer.render(@template)

      expect(@$ground.find('#header').html()).toBeTag 'div', '',
        id: /__joosy\d+/

  it "renders widget tag", ->
    runs ->
      @template = (context) => context.widget 'div', {class: 'test'}, @widget

      @$ground.find('#header').html @renderer.render(@template)

      expect(@$ground.find('#header').html()).toBeTag 'div', '',
        id: /__joosy\d+/
        class: 'test'

  it "bootstraps widget", ->
    runs ->
      @$ground.find('#header').html @renderer.render(@template)

      # At the first step only the container will be injected into HTML
      expect(@$ground.find('#header').html()).toBeTag 'div', '',
        id: /__joosy\d+/

    waits 0

    runs ->
      # But at the next asynchronous tick, widget will be emerged
      expect(@$ground.find('#header').html()).toBeTag 'div', 'test',
        id: /__joosy\d+/