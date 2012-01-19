beforeEach ->
  $('body').append('<div id="ground">')
  @ground = $('body #ground')

afterEach ->
  @ground.remove() unless @polluteGround