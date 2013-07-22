describe "Joosy", ->

  it "initializes", ->
    expect(Joosy.Application.config.debug).toBeFalsy()
    expect(Joosy.Modules).toBeDefined()
    expect(Joosy.Resources).toBeDefined()

  it "generates proper UUIDs", ->
    uuids = []
    2.times -> uuids.push Joosy.uuid()
    expect(uuids.unique().length).toEqual(2)
    expect(uuids[0]).toMatch /[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[0-9A-F]{4}-[0-9A-F]{12}/

  it "generates proper UIDs", ->
    uids = []
    5.times -> uids.push Joosy.uid()
    expect(uids.unique().length).toEqual(5)

  it "builds proper URLs", ->
    expect(Joosy.buildUrl 'http://www.org').toEqual('http://www.org')
    expect(Joosy.buildUrl 'http://www.org#hash').toEqual('http://www.org#hash')
    expect(Joosy.buildUrl 'http://www.org', {foo: 'bar'}).toEqual('http://www.org?foo=bar')
    expect(Joosy.buildUrl 'http://www.org?bar=baz', {foo: 'bar'}).toEqual('http://www.org?bar=baz&foo=bar')

  describe "namespacer", ->
    it "declares", ->
      Joosy.namespace 'Namespaces.Test1'
      Joosy.namespace 'Namespaces.Test2', ->
        @bingo = 'bongo'

      expect(window.Namespaces.Test1).toBeDefined()
      expect(window.Namespaces.Test2.bingo).toEqual('bongo')

    it "imprints path", ->
      Joosy.namespace 'Irish', ->
        class @Pub extends Joosy.Module

      Joosy.namespace 'British', ->
        class @Pub extends Joosy.Module

      Joosy.namespace 'Keltic', ->
        class @Pub extends Irish.Pub

      expect(Irish.Pub.__namespace__).toEqual ["Irish"]
      expect(British.Pub.__namespace__).toEqual ["British"]
      expect(Keltic.Pub.__namespace__).toEqual ["Keltic"]

      Joosy.namespace 'Deeply.Nested', ->
        class @Klass extends Joosy.Module

      expect(Deeply.Nested.Klass.__namespace__).toEqual ["Deeply", "Nested"]

      class @Flat extends Joosy.Module

      expect(@Flat.__namespace__).toEqual []

  it "declares helpers", ->
    Joosy.helpers 'Hoge', ->
      @fuga = ->
        "piyo"

    expect(window.Joosy.Helpers).toBeDefined()
    expect(window.Joosy.Helpers.Hoge).toBeDefined()
    expect(window.Joosy.Helpers.Hoge.fuga()).toBe "piyo"
