module.exports = (grunt) ->

  connect = require 'connect'

  grunt.joosy =
    server:
      start: (port, setup) ->
        console.log "=> Started on 4000"
        server = connect()
        setup?(server)
        server.listen port

      serveProxied: (server, map) ->
        return unless map?

        proxy = require 'proxy-middleware'
        url   = require 'url'

        for from, to of map
          console.log "=> Proxying #{from} to #{to}"
          server.use from, proxy(url.parse to)

      serveAssets: (server, mincer, path='/assets') ->
        console.log "=> Serving assets from #{path}"
        assets = new mincer.Environment(process.cwd())
        assets.appendPath 'source',
        assets.appendPath 'stylesheets',
        assets.appendPath 'components'
        assets.appendPath 'vendor'
        assets.appendPath 'node_modules/joosy/src'

        server.use path, mincer.createServer(assets)

      servePlayground: (server, path='/') ->
        console.log "=> Serving playground from #{path}"
        server.use path, (req, res, next) ->
          if req.url == path
            res.end grunt.joosy.compilePlayground()
          else
            next()

      serveStatic: (server, compress=false) ->
        console.log "=> Serving static from /public"
        unless compress
          server.use connect.static('public')
        else
          server.use require('gzippo').staticGzip('public')

    mincer: (environment='development') ->
      mincer  = require 'mincer'

      mincer.logger.use console
      mincer.StylusEngine.registerConfigurator (stylus) ->
        grunt.joosy.setupStylus stylus, environment

      mincer

    compilePlayground: (environment='development') ->
      require('haml-coffee').compile(grunt.file.read 'source/index.haml')(
        environment: environment
        config: grunt.config.get('joosy.config') || {}
      )

    setupStylus: (stylus, environment='production') ->
      stylus.options.paths.push require('path').join(process.cwd(), 'public')
      stylus.define '$environment', environment
      stylus.define '$config', grunt.config.get('joosy.config') || {}
      stylus.use require('nib')()

  # Dependencies
  grunt.loadNpmTasks 'grunt-mincer'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-bower-task'

  grunt.registerTask 'joosy:compile',        ['mince', 'uglify', 'cssmin', 'joosy:compile:playground']
  grunt.registerTask 'joosy:compile:code',   ['mince:code', 'uglify:application']
  grunt.registerTask 'joosy:compile:styles', ['mince:styles', 'cssmin:application']

  grunt.registerTask 'joosy:compile:playground', ->
    grunt.file.write 'public/index.html', grunt.joosy.compilePlayground('production')

  grunt.registerTask 'joosy:server', ->
    @async()
    
    grunt.joosy.server.start 4000, (server) ->
      grunt.joosy.server.serveAssets server, grunt.joosy.mincer()
      grunt.joosy.server.servePlayground server
      grunt.joosy.server.serveProxied server, grunt.config.get('joosy.server.proxy')
      grunt.joosy.server.serveStatic server

  grunt.registerTask 'joosy:server:production', ->
    @async()

    grunt.joosy.server.start process.env['PORT'] ? 4000, (server) ->
      grunt.joosy.server.serveStatic server, true

  grunt.registerTask 'joosy:postinstall', ->
    if grunt.file.exists('bower.json')
      grunt.task.run 'bower:install'

    if process.env['NODE_ENV'] == 'production'
      grunt.task.run 'joosy:compile'
