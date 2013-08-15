module.exports =

  generate: ->
    console.log 'Usage:'
    console.log '  joosy generate :generator'
    console.log ''
    console.log 'Description:'
    console.log '  Runs one of the following generators to create something for you:'
    console.log ''
    console.log '  page         create new page'
    console.log '  resource     create new resource'
    console.log '  widget       create new widget'
    console.log '  layout       create new layout'

  new: ->
    console.log 'Usage:'
    console.log '  joosy new :name'
    console.log ''
    console.log 'Description:'
    console.log '  Generates brand new Joosy application named :name (directory with the name of application will be created)'

  banner: ->
    console.log '     __________________________'
    console.log '    /_    ____ ____ ____ __ __/'
    console.log '   __/  /    /    / ___/  /  /'
    console.log '  / /  / /  /  / /__  /  /  /'
    console.log ' /____/____/____/____/__   /'
    console.log '/_________________________/'
    console.log ''
    console.log 'Usage:'
    console.log '  joosy COMMAND [ARGS]'
    console.log ''
    console.log 'Available commands:'
    console.log '  generate    Insert new entity in the application (short-cut alias "g")'
    console.log '  new         Create a new application'
    console.log ''
    console.log 'Description:'
    console.log '  Help is also available on per-command basis (joosy help command)'