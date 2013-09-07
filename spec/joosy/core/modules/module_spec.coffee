describe "Joosy.Module", ->

  it "tracks inheritance", ->
    class A
    class B extends A
    class C extends B
    class D

    for a in [A, B, C, D]
      for b in [A, B, C, D]
        if (a == b) ||
            ((a == B) && (b == A)) ||
            ((a == C) && (b != D))
          expect(Joosy.Module.hasAncestor a, b).toBeTruthy()
        else
          expect(Joosy.Module.hasAncestor a, b).toBeFalsy()

  # We need this check to ensure we are not overpolluting the namespace
  it "has minimal set of properties", ->
    class Klass extends Joosy.Module

    expect(Object.extended(Klass).keys()).toEqual ['__namespace__', '__className', 'hasAncestor', 'aliasMethodChain', 'aliasStaticMethodChain', 'merge', 'include', 'extend', '__super__']
    expect(Object.extended(Klass.prototype).keys()).toEqual ['constructor']

  it "includes", ->
    Module =
      property: 'value'

    class Klass extends Joosy.Module
      @include Module

    expect(Klass::property).toEqual 'value'
    expect(Klass.property).toBeUndefined()

  it "extends", ->
    TestModule =
      property: 'value'

    class Klass extends Joosy.Module
      @extend TestModule

    expect(Klass.property).toEqual 'value'
    expect(Klass::property).toBeUndefined()

  it "runs callbacks", ->
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
