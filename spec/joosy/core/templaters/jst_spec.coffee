describe "Joosy.Templaters.JST", ->

  describe "builder", ->

    beforeEach ->
      window.JST = {}

    afterEach ->
      window.JST = undefined

    describe "with empty application name", ->

      beforeEach ->
        @templater = new Joosy.Templaters.JST(locale: 'en')

      it "resolves plain template", ->
        JST['templates/test'] = 'template'
        expect(@templater.buildView('test')).toEqual 'template'

      it "preffers localized template", ->
        JST['templates/test'] = 'error'
        JST['templates/test-en'] = 'template'
        expect(@templater.buildView('test')).toEqual 'template'

      it "preffers full path template", ->
        JST['templates/test'] = 'template'
        JST['templates/templates/test'] = 'error'
        expect(@templater.buildView('templates/test')).toEqual 'template'

    describe "with set application name", ->

      beforeEach ->
        @templater = new Joosy.Templaters.JST(prefix: 'application', locale: 'en')

      it "resolves plain template", ->
        JST['application/templates/test'] = 'template'
        expect(@templater.buildView('test')).toEqual 'template'

      it "preffers localized template", ->
        JST['application/templates/test'] = 'error'
        JST['application/templates/test-en'] = 'template'
        expect(@templater.buildView('test')).toEqual 'template'

      it "preffers full path template", ->
        JST['templates/test'] = 'template'
        JST['application/templates/templates/test'] = 'error'
        expect(@templater.buildView('templates/test')).toEqual 'template'

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