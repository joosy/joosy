describe "Joosy.Helpers.Widgets", ->

  h = Joosy.Helpers.Application

  beforeEach ->
    h.__owner =
      setTimeout: (timeout, action) -> setTimeout action, timeout
      registerWidget: @spy = sinon.spy()

  afterEach ->
    delete h.__owner

  it "renders widget tag", ->
    runs ->
      expect(h.widget 'div', ->).toBeTag 'div', false,
        id: /__joosy\d+/

    waits 0

    runs ->
      expect(@spy.callCount).toEqual 1

  it "renders widget tag with given classes", ->
    runs ->
      expect(h.widget 'div', {class: 'class1 class2'}, ->).toBeTag 'div', false,
        id: /__joosy\d+/,
        class: 'class1 class2'

    waits 0

    runs ->
      expect(@spy.callCount).toEqual 1