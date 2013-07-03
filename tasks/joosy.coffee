module.exports = (grunt) ->

  Sugar   = require 'sugar'
  Path    = require 'path'
  connect = require 'connect'
  Mincer  = require 'mincer'

  grunt.joosy =
    helpers:
      list: (task, config, entry) ->
        entries = grunt.config.get(config) || {} 

        return if entry
          task.requiresConfig "#{config}.#{entry}"
          [ entries[entry] ]
        else
          Object.values entries

    assets:
      instance: (environment='development') ->
        Mincer.logger.use console
        Mincer.StylusEngine.registerConfigurator (stylus) ->
          stylus.options.paths.push Path.join(process.cwd(), 'public')
          stylus.define '$environment', environment
          stylus.define '$config', grunt.config.get('joosy.config') || {}
          stylus.use require('nib')()

        assets = new Mincer.Environment(process.cwd())
        assets.appendPath 'source',
        assets.appendPath 'stylesheets',
        assets.appendPath 'components'
        assets.appendPath 'vendor'
        assets.appendPath 'node_modules/joosy/src'

        assets

      compile: (environment, map, callbacks) ->
        assets = grunt.joosy.assets.instance(environment)
        deepness = 0

        for entry in map
          do (entry) ->
            deepness++
            asset = assets.findAsset entry.src
            callbacks.error? "Cannot find #{entry.src}" unless asset

            asset.compile (err) ->
              deepness--
              callbacks.error? asset, err if err
              grunt.file.write entry.dest, asset.toString()
              callbacks.compiled? asset, entry.dest
              callbacks.success?() if deepness == 0

    haml:
      compile: (file, environment='development') ->
        HAMLC = require 'haml-coffee'

        HAMLC.compile(grunt.file.read file)(
          environment: environment
          config: grunt.config.get('joosy.config') || {}
        )

    server:
      start: (port, setup) ->
        server = connect()
        setup?(server)
        server.listen port

        console.log "=> Started on 4000\n"

      serveProxied: (server, map) ->
        URL   = require 'url'
        proxy = require 'proxy-middleware'

        return unless map?

        for entry in map
          [from, to] = if entry.src
            [entry.src, entry.dest]
          else
            key = Object.keys(entry).first()
            [key, entry[key]]

          server.use from, proxy(URL.parse to)
          console.log "=> Proxying #{from} to #{to}"

      serveAssets: (server, path='/assets') ->
        assets = grunt.joosy.assets.instance()
        server.use path, Mincer.createServer(assets)

        console.log "=> Serving assets from #{path}"

      serveHAML: (server, path='/', source='source/index.haml') ->
        server.use path, (req, res, next) ->
          if req.url == path
            console.log "Served #{path} (#{source})"
            res.end grunt.joosy.haml.compile(source)
          else
            next()

      serveStatic: (server, compress=false) ->
        Gzippo = require 'gzippo'

        unless compress
          server.use connect.static('public')
        else
          server.use Gzippo.staticGzip('public')

        console.log "=> Serving static from /public"

    bower: -> require('bower')

  # Tasks
  grunt.registerTask 'joosy:postinstall', ->
    complete  = @async()
    bowerized = ->
      if process.env['NODE_ENV'] == 'production'
        grunt.task.run 'joosy:compile'

      complete()

    if grunt.file.exists('bower.json')
      grunt.joosy.bower().commands.install()
        .on('data', (msg) -> grunt.log.ok msg)
        .on('error', (error) -> grunt.fail.fatal(error))
        .on('end', bowerized)
    else
      bowerized()

  grunt.registerTask 'joosy:server', ->
    @async()
    
    grunt.joosy.server.start 4000, (server) ->
      grunt.joosy.server.serveAssets server
      grunt.joosy.server.serveHAML server
      grunt.joosy.server.serveProxied server, grunt.config.get('joosy.server.proxy')
      grunt.joosy.server.serveStatic server

  grunt.registerTask 'joosy:server:production', ->
    @async()

    grunt.joosy.server.start process.env['PORT'] ? 4000, (server) ->
      grunt.joosy.server.serveStatic server, true

  grunt.registerTask 'compile', ['joosy:assets', 'joosy:haml']

  grunt.registerTask 'joosy:assets', ->
    complete = @async()
    assets   = grunt.joosy.helpers.list(@, 'joosy.assets', @args[0])

    grunt.joosy.assets.compile 'production', assets,
      error: (msg) -> grunt.fail.fatal msg
      compiled: (asset, dest) -> grunt.log.ok "Compiled #{dest}"
      success: complete

  grunt.registerTask 'joosy:haml', ->
    for _, entry of grunt.joosy.helpers.list(@, 'joosy.haml', @args[0])
      grunt.file.write entry.dest, grunt.joosy.haml.compile("source/#{entry.src}", 'production')
      grunt.log.ok "Compiled #{entry.dest}"