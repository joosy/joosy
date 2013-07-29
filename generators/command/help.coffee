module.exports = class

  generate: ->
    console.log "Usage: `generate :generator`\n"
    console.log 'Possible generators are:'
    console.log '  page         create new page'
    console.log '  resource     create new resource'
    console.log '  widget       create new widget'
    console.log '  layout       create new layoyt'

  new: ->
    console.log 'Usage: `new :name`\n'
    console.log '  name     create new application'
