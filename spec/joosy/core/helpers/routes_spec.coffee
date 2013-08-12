describe "Joosy.Helpers.Routes", ->

  it "renders data-joosy links", ->
    link = Joosy.Helpers.Routes.linkTo 'test', '/app/link', nice: true
    expect(link).toEqual '<a nice="true" data-joosy="true" href="/app/link">test</a>'

  it "renders data-joosy links yielding block", ->
    link = Joosy.Helpers.Routes.linkTo '/app/link', nice: true, -> 'test'
    expect(link).toEqual '<a nice="true" data-joosy="true" href="/app/link">test</a>'
