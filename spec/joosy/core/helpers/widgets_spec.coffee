describe "Joosy.Helpers.Widgets", ->

  h = Joosy.Helpers.Application

  beforeEach ->
    h.onRefresh = sinon.spy()

  afterEach ->
    delete h.onRefresh

  it "renders widget tag", ->
    expect(h.widget 'div', (->)).toBeTag 'div', '', id: /\S{36}/
    expect(h.onRefresh.callCount).toEqual 1

  it "renders widget tag with given classes", ->
    expect(h.widget 'div.class1.class2', (->)).toBeTag 'div', '', id: /\S{36}/, class: 'class1 class2'
    expect(h.onRefresh.callCount).toEqual 1
