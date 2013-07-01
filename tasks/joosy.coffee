module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-mincer'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-bower-task'

  grunt.registerTask 'joosy:compile', ['mince', 'uglify', 'cssmin', 'joosy:compile:playground']
  grunt.registerTask 'joosy:compile:code', ['mince:code', 'uglify:application']
  grunt.registerTask 'joosy:compile:styles', ['mince:styles', 'cssmin:application']

  grunt.registerTask 'joosy:compile:playground', ->
    hamlc = require 'haml-coffee'
    grunt.file.write 'public/index.html', hamlc.compile(grunt.file.read 'source/index.haml')(
      environment: 'production'
      config: grunt.config.get('joosy.config') || {}
    )

  grunt.registerTask 'joosy:server', ->
    @async()
    connect = require 'connect'
    mincer  = require 'mincer'
    hamlc   = require 'haml-coffee'
    path    = require 'path'

    mincer.StylusEngine.registerConfigurator (stylus) ->
      stylus.options.paths.push path.join(process.cwd(), 'public')
      stylus.use require('nib')()

    server = connect()
    assets = new mincer.Environment(process.cwd())
    assets.appendPath 'source',
    assets.appendPath 'stylesheets',
    assets.appendPath 'components'
    assets.appendPath 'vendor'
    assets.appendPath 'node_modules/joosy/src'

    server.use '/assets', mincer.createServer(assets)

    server.use '/', (req, res, next) ->
      if req.url == '/'
        res.end hamlc.compile(grunt.file.read 'source/index.haml')(
          environment: 'development'
          config: grunt.config.get('joosy.config') || {}
        )
      else
        next()

    if grunt.config.get('joosy.proxy')
      proxy = require 'proxy-middleware'
      url   = require 'url'

      for from, to of grunt.config.get('joosy.proxy')
        console.log "-> Proxying #{from} to #{to}"
        server.use from, proxy(url.parse to)

    server.use connect.static('public')
    server.listen 4000
    console.log "-> Started on 4000\n"

  grunt.registerTask 'joosy:server:production', ->
    @async()
    connect = require('connect')
    server = connect()
    server.use require('gzippo').staticGzip('public')
    server.listen process.env['PORT'] ? 4000

  grunt.registerTask 'joosy:postinstall', ->
    @async

    if grunt.file.exists('bower.json')
      grunt.task.run 'bower:install'

    if process.env['NODE_ENV'] == 'production'
      grunt.task.run 'joosy:compile'
