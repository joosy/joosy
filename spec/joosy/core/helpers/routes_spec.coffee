describe "Joosy.Helpers.Routes", ->

  it "renders data-joosy links", ->
    link = Joosy.Helpers.Routes.linkTo 'test', '/app/link', nice: true
    expect(link).toBeTag 'a', 'test',
      'data-joosy': 'true'
      nice: 'true'
      href: '/app/link'

  it "renders data-joosy links yielding block", ->
    link = Joosy.Helpers.Routes.linkTo '/app/link', nice: true, -> 'test'
    expect(link).toBeTag 'a', 'test',
      'data-joosy': 'true'
      nice: 'true'
      href: '/app/link'