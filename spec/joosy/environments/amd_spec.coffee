describe "Joosy", ->

  it "keeps environment clean", ->
    expect(Joosy?).toBeFalsy()

  it "loads", ->
    result = false

    runs ->
      requirejs ['joosy'], (joosy) ->
        result = true
        expect(joosy.Application).toBeDefined()

    waitsFor (-> result), 'Unable to download Joosy', 1000