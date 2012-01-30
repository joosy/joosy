beforeEach ->
  window.JST = {}
  $('body').append('<div id="ground">')
  @ground = $('body #ground')
  @seedGround = ->
    @ground.html('
      <div id="application" class="application">
        <div id="header" class="header" />
        <div id="wrapper" class="wrapper">
          <div id="content" class="content">
            <div id="post1" class="post" />
            <div id="post2" class="post" />
            <div id="post3" class="post" />
          </div>
          <div id="sidebar" class="sidebar">
            <div id="widget1" class="widget" />
            <div id="widget2" class="widget" />
          </div>
        </div>
        <div id="footer" class="footer" />
      </div>
    ')
  @addMatchers
    toBeSequenced: () ->
      if !Object.isArray(@actual) || @actual.length == 0
        console.log 'toBeSequenced: not array or empty array given'
        return false
      i = 0
      for spy in @actual
        unless spy.callCount == 1
          console.log "toBeSequenced: spy ##{i} was called #{spy.callCount} times"
          return false
        i++
      if @actual.length > 1
        for spy in @actual.from(1)
          i = @actual.indexOf spy
          previous = @actual[i - 1]
          unless spy.calledAfter previous
            console.log "toBeSequenced: spy ##{i} wasn't called after spy ##{i - 1}"
            return false
      return true

afterEach ->
  @ground.remove() unless @polluteGround