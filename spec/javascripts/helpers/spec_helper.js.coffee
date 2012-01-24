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

afterEach ->
  @ground.remove() unless @polluteGround