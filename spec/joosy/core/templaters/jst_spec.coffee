describe "Joosy.Templaters.JST", ->

  describe "builder", ->

    beforeEach ->
      window.JST = {}
      window.I18n = {locale: 'en'}

    afterEach ->
      delete window.JST
      delete window.I18n

    describe "with empty application name", ->

      beforeEach ->
        @templater = new Joosy.Templaters.JST

      it "resolves plain template", ->
        JST['templates/test'] = 'template'
        expect(@templater.buildView('test')).toEqual 'template'

      it "preffers localized template", ->
        JST['templates/test'] = 'error'
        JST['templates/test-en'] = 'template'
        expect(@templater.buildView('test')).toEqual 'template'

    describe "with set application name", ->

      beforeEach ->
        @templater = new Joosy.Templaters.JST(prefix: 'application')

      it "resolves plain template", ->
        JST['application/templates/test'] = 'template'
        expect(@templater.buildView('test')).toEqual 'template'

      it "preffers localized template", ->
        JST['application/templates/test'] = 'error'
        JST['application/templates/test-en'] = 'template'
        expect(@templater.buildView('test')).toEqual 'template'

  it "resolves templates correctly", ->
    templater = new Joosy.Templaters.JST

    class Klass extends Joosy.Module

    Joosy.namespace 'British.Cities', ->
      class @Klass extends Joosy.Module

    expect(templater.resolveTemplate(undefined, "/absolute", undefined)).
      toEqual "absolute"

    expect(templater.resolveTemplate('widgets', 'fuga', {})).
      toEqual 'widgets/fuga'

    expect(templater.resolveTemplate('widgets', 'fuga', new Klass)).
      toEqual 'widgets/fuga'

    expect(templater.resolveTemplate('widgets', 'fuga', new British.Cities.Klass)).
      toEqual 'widgets/british/cities/fuga'

    expect(templater.resolveTemplate('widgets', 'hoge/fuga', new British.Cities.Klass)).
      toEqual 'widgets/british/cities/hoge/fuga'