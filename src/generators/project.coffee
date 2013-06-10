module.exports = class
  @generate: (name) -> new @(name)

  constructor: (@name) ->
    console.log @name