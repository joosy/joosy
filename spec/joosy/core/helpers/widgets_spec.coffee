describe "Joosy.Helpers.Widgets", ->

  h = Joosy.Helpers.Application

  beforeEach ->
    h.__owner =
      constructor:
        mapWidgets: @spy = sinon.spy()

  afterEach ->
    delete h.__owner

  it "renders widget tag", ->
    expect(h.widget 'div', ->).toBeTag 'div', false,
      id: /__joosy\d+/

    expect(@spy.callCount).toEqual 1

  it "renders widget tag with given classes", ->
    expect(h.widget 'div', {class: 'class1 class2'}, ->).toBeTag 'div', false,
      id: /__joosy\d+/,
      class: 'class1 class2'

    expect(@spy.callCount).toEqual 1