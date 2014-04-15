describe "Joosy", ->

  it "loads", ->
    result = false

    runs ->
      requirejs ['joosy'], (joosy) ->
        result = true
        expect(joosy.Application).toBeDefined()

    waitsFor (-> result), 'Unable to download Joosy', 1000

  it "allows for separate module inclusion", ->
    result = false

    runs ->
      requirejs ['joosy/module'], (module) ->
        result = true
        expect(typeof(module.hasAncestor) == 'function').toBeTruthy()

    waitsFor (-> result), 'Unable to download Joosy', 1000

  it "registers internal components as modules", ->
    expect(Object.keys(require.s.contexts._.registry).sort()).toEqual [
      'joosy/application',
      'joosy/form',
      'joosy/layout',
      'joosy/modules/dom',
      'joosy/modules/events',
      'joosy/modules/filters',
      'joosy/modules/log',
      'joosy/modules/renderer',
      'joosy/modules/resources/cacher',
      'joosy/modules/time_manager',
      'joosy/page',
      'joosy/resources/array',
      'joosy/resources/collection',
      'joosy/resources/entity',
      'joosy/resources/hash',
      'joosy/resources/rest',
      'joosy/resources/rest_collection',
      'joosy/resources/scalar',
      'joosy/router',
      'joosy/templaters/jst',
      'joosy/widget'
    ]