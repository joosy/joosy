describe "Joosy.Helpers.View", ->

  h = Joosy.Helpers.Application

  it "renders tag with string inner", ->
    expect(h.tag 'div', {id: 'ololo'}, 'test').toEqual '<div id="ololo">test</div>'

  it "renders tag with lambda inner", ->
    data = h.tag 'div', {id: 'ololo'}, -> h.tag 'div', {id: 'ololo'}, 'test'
    expect(data).toEqual '<div id="ololo"><div id="ololo">test</div></div>'