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
        expect(Object.isFunction module.hasAncestor).toBeTruthy()

    waitsFor (-> result), 'Unable to download Joosy', 1000

  it "registers internal components as modules", ->
    expect(Object.keys(require.s.contexts._.registry).sortBy()).toEqual [
      'joosy/application',
      'joosy/layout',
      'joosy/modules/container',
      'joosy/modules/events',
      'joosy/modules/filters',
      'joosy/modules/log',
      'joosy/modules/renderer',
      'joosy/modules/time_manager',
      'joosy/modules/widgets_manager',
      'joosy/page',
      'joosy/resources/watcher',
      'joosy/router',
      'joosy/templaters/jst',
      'joosy/widget'
    ]