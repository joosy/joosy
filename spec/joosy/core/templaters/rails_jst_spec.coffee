describe "Joosy.Templaters.RailsJST", ->

  beforeEach ->
    @templater = new Joosy.Templaters.RailsJST()

    class @Klass extends Joosy.Module

    Joosy.namespace 'British.Cities', ->
      class @Klass extends Joosy.Module

  it "should resolve templates correctly", ->
    expect(@templater.resolveTemplate(undefined, "/absolute", undefined)).
        toEqual "absolute"

    expect(@templater.resolveTemplate('widgets', 'fuga', {})).
        toEqual 'widgets/fuga'

    expect(@templater.resolveTemplate('widgets', 'fuga', new @Klass)).
        toEqual 'widgets/fuga'

    expect(@templater.resolveTemplate('widgets', 'fuga', new British.Cities.Klass)).
        toEqual 'widgets/british/cities/fuga'

    expect(@templater.resolveTemplate('widgets', 'hoge/fuga', new British.Cities.Klass)).
        toEqual 'widgets/british/cities/hoge/fuga'