describe "Joosy.Helpers.View", ->

  # Shortcut
  h = Joosy.Helpers.Application

  it "renders tag with string content", ->
    tag = h.tag 'div', {id: 'id'}, 'content'
    expect(tag).toEqual '<div id="id">content</div>'

  it "renders tag with lambda content", ->
    tag = h.tag 'div', {id: 'id'}, -> 
      h.tag 'div', {id: 'id2'}, 'content'

    expect(tag).toEqual '<div id="id"><div id="id2">content</div></div>'