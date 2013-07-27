describe "Joosy", ->

  it "loads", ->
    expect(Joosy).toBeDefined()

  it "keeps environment clean", ->
    result = false
    ghetto = {}

    runs ->
      $.ajax
        url: '../build/joosy.js'
        dataType: 'text'
        success: (script) ->
          (new Function( "with(this) { " + script + "}")).call(ghetto)
          result = true

    waitsFor (-> result), 'Unable to download Joosy', 1000

    runs ->
      expect(Object.keys ghetto).toEqual ['Joosy', 'Metamorph']