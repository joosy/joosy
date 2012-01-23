describe "Joosy.Module", ->

  it "should track inheritance", ->
    class A
    class B extends A
    class C extends B
    class D
    for a in [A, B, C, D]
      for b in [A, B, C, D]
        if (a == b) ||
          ((a == B) && (b == A)) ||
          ((a == C) && (b != D))
            expect(Joosy.Module.hasAncestor.apply(null, [a, b])).toBeTruthy()
        else
          expect(Joosy.Module.hasAncestor.apply(null, [a, b])).toBeFalsy()

  it "should include properties into prototype", ->
    TestModule =
      property: 'value'
    class Klass extends Joosy.Module
      @include TestModule
    expect(Klass::property).toEqual 'value'
    expect((new Klass()).property).toEqual 'value'

  it "should extend object", ->
    TestModule =
      property: 'value'
    class Klass extends Joosy.Module
      @extend TestModule
    expect(Klass.property).toEqual 'value'
    expect((new Klass()).property).toBeUndefined()

  it "should run callbacks on include and extend", ->
    TestModule =
      property: 'value'
      included: sinon.spy()
      extended: sinon.spy()
    class Klass extends Joosy.Module
      @include TestModule
      @extend TestModule
    for callback in ['included', 'extended']
      expect(TestModule[callback].callCount).toEqual 1
      expect(TestModule[callback].getCall(0).calledOn(Klass)).toBeTruthy()

  it "should run init hook", ->
    class Klass extends Joosy.Module
      init: sinon.spy()
    target = (new Klass 1, 2).init
    expect(target.callCount).toEqual(1)
    expect(target.alwaysCalledWithExactly 1, 2).toBeTruthy()

  it "should have minimal set of properties", ->
    expect(Object.extended(Joosy.Module).keys()).toEqual ['hasAncestor', 'include', 'extend']
    expect(Object.extended(Joosy.Module.prototype).keys()).toEqual []
