describe "Joosy.Modules.Container", ->

  beforeEach ->
    @seedGround()
    class @TestContainer extends Joosy.Module
      @include Joosy.Modules.Container
      elements:
        footer: '.footer'
      events:
        'test': 'onContainerTest'
      container: $('#application', @ground)
    @box = new @TestContainer()


  it "should have property named per declared element in container", ->
    @ground.prepend('<div class="footer" />')  # out of container
    @box.refreshElements()
    target = @box.footer.get 0
    expect(target).toBeTruthy()
    expect(target).toBe $('.footer', @box.container).get 0
    expect(target).toBe @box.$('.footer').get 0

  it "should reinitialize container", ->
    old_container = @box.container
    parent = old_container.parent()
    callback = sinon.spy()
    old_container.bind 'test', callback
    old_container.trigger 'test'
    new_container = Joosy.Modules.Container.swapContainer old_container, 'new content'
    new_container.trigger 'test'
    expect(new_container.html()).toEqual 'new content'
    expect(new_container.parent().get(0)).toBe parent.get 0
    expect(callback.callCount).toEqual 1

  it "should inherit element declarations", ->
    class SubContainerA extends @TestContainer
      elements:
        first: 'first'
        second: 'second'
    class SubContainerB extends SubContainerA
      elements:
        first: 'overrided'
        third: 'third'
    subBox = new SubContainerB()
    target = subBox.__collectElements()
    expect(target).toEqual Object.extended
      first: 'overrided'
      second: 'second'
      third: 'third'
      footer: '.footer'
    target = (new @TestContainer()).__collectElements()
    expect(target).toEqual Object.extended(footer: '.footer')

  it "should resolve element selector", ->
    target = @box.__extractSelector '$footer'
    expect(target).toEqual '.footer'

  it "should inherit event declarations", ->
    class SubContainerA extends @TestContainer
      events:
        'test .post': 'callback2'
        'custom' : 'method'
    class SubContainerB extends SubContainerA
      events:
        'test $footer': 'onFooterTest'
        'custom' : 'overrided'
    subBox = new SubContainerB()
    target = subBox.__collectEvents()
    expect(target).toEqual Object.extended
      'test': 'onContainerTest'
      'test .post': 'callback2'
      'test $footer': 'onFooterTest'
      'custom' : 'overrided'
    target = (new @TestContainer()).__collectEvents()
    expect(target).toEqual Object.extended('test': 'onContainerTest')

  it "should delegate events", ->
    callback = 1.upto(3).map -> sinon.spy()
    @box.events = Object.extended(@box.events).merge
      'test .post': callback[2]
      'test $footer': 'onFooterTest'

    @box.onContainerTest = callback[0]
    @box.onFooterTest = callback[1]
    @box.__delegateEvents()
    @box.container.trigger 'test'
    $('.footer', @box.container).trigger 'test'
    $('.post', @box.container).trigger 'test'
    expect(callback[0].callCount).toEqual 5
    expect(callback[1].callCount).toEqual 1
    expect(callback[2].callCount).toEqual 3
