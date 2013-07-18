describe "Joosy.Helpers.Widgets", ->

  h = Joosy.Helpers.Application

  it "renders widget tag", ->
    expect(h.widget 'div', ->).toBeTag 'div', false,
      id: /__joosy\d+/

  it "renders widget tag with given classes", ->
    expect(h.widget 'div.class1.class2', ->).toBeTag 'div', false,
      id: /__joosy\d+/,
      class: 'class1 class2'
