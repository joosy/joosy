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
    target = @box.footer.get(0)
    expect(target).toBeTruthy()
    expect(target).toBe($('.footer', @box.container).get(0))
    expect(target).toBe(@box.$('.footer').get(0))

  it "should reinitialize container", ->
    old_container = @box.container
    parent = old_container.parent()
    callback = sinon.spy()
    old_container.bind('test', callback)
    old_container.trigger('test')
    new_container = Joosy.Modules.Container.swapContainer(old_container, 'new content')
    new_container.trigger('test')
    expect(new_container.html()).toEqual('new content')
    expect(new_container.parent().get(0)).toBe(parent.get(0))
    expect(old_container.parent().get(0)).toBeUndefined()
    expect(callback.callCount).toEqual(1)

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
    expect(target).toEqual(
      first: 'overrided'
      second: 'second'
      third: 'third'
      footer: '.footer'
    )
    target = (new @TestContainer()).__collectElements()
    expect(target).toEqual(footer: '.footer')

  it "should resolve element selector", ->
    target = @box.__extractSelector('$footer')
    expect(target).toEqual('.footer')

  it "should delegate event declarations", ->
    callback = 1.upto(3).map -> sinon.spy()
    class SubContainerA extends @TestContainer
      events:
        'test .post': callback[2]
      onFooterTest: callback[1]
    class SubContainerB extends SubContainerA
      events:
        'test $footer': 'onFooterTest'
      onContainerTest: callback[0]
    subBox = new SubContainerB()
    subBox.__delegateEvents()
    subBox.container.trigger('test')
    $('.footer', subBox.container).trigger('test')
    $('.post', subBox.container).trigger('test')
    expect(callback[0].callCount).toEqual(5)
    expect(callback[1].callCount).toEqual(1)
    expect(callback[2].callCount).toEqual(3)
