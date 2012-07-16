describe "Joosy.Helpers.Widgets", ->

  h = Joosy.Helpers.Application

  beforeEach ->
    h.onRefresh = sinon.spy()

  afterEach ->
    delete h.onRefresh

  it "renders widget tag", ->
    expect(h.widget 'div', (->)).toMatch /<div id="\S{36}"><\/div>/
    expect(h.onRefresh.callCount).toEqual 1

  it "renders widget tag with given classes", ->
    expect(h.widget 'div.class1.class2', (->)).toMatch /<div id="\S{36}" class="class1 class2"><\/div>/
    expect(h.onRefresh.callCount).toEqual 1
