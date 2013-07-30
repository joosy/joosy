module.exports = class

  generate: ->
    console.log "Usage: `generate :generator`\n"
    console.log 'Possible generators are:'
    console.log '  page         create new page'
    console.log '  resource     create new resource'
    console.log '  widget       create new widget'
    console.log '  layout       create new layout'

  new: ->
    console.log 'Usage: `joosy new :name` - create a new application with given name'

  banner: ->
    console.log '\t\t\t     __________________________'
    console.log '\t\t\t    /_    ____ ____ ____ __ __/'
    console.log '\t\t\t   __/  /    /    / ___/  /  /'
    console.log '\t\t\t  / /  / /  /  / /__  /  /  /'
    console.log '\t\t\t /____/____/____/____/__   /'
    console.log '\t\t\t/_________________________/\n'
    console.log 'Usage: joosy COMMAND [ARGS]\n'
    console.log 'Available commands are: \n'
    console.log '  generate    Insert new entity in the application (short-cut alias "g")'
    console.log '  new         Create a new application\n'
    console.log 'Help is also available on per-command basis, use appropriate argument, Luke'
