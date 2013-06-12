module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-mincer'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-bower-task'

  grunt.initConfig
    bower:
      install:
        options:
          copy: false
          verbose: true

    connect:
      server:
        options:
          port: 4000
          base: 'public'

    mince:
      application:
        include: ['source', 'components', 'vendor', 'node_modules/joosy/lib']
        src: 'application.coffee'
        dest: 'public/assets/application.js'

    stylus:
      application:
        options:
          paths: ['stylesheets']
        files: 'public/assets/application.css': 'stylesheets/application.styl'

    uglify:
      application:
        options:
          sourceMap: 'public/assets/application.js.map'
        files:
          'public/assets/application.min.js': 'public/assets/application.js'

    cssmin:
      application:
        files:
          'public/assets/application.min.css': 'public/assets/application.css'

  grunt.registerTask 'joosy:compile', ['joosy:compile:code', 'joosy:compile:styles']
  grunt.registerTask 'joosy:compile:code', ['mince', 'uglify']
  grunt.registerTask 'joosy:compile:styles', ['stylus', 'cssmin']

  grunt.registerTask 'joosy:server', ->
    @async()
    connect = require('connect')
    mincer  = require('mincer')

    mincer.StylusEngine.registerConfigurator (stylus) -> stylus.use require('nib')()

    server = connect()
    assets = new mincer.Environment(process.cwd())
    assets.appendPath 'source',
    assets.appendPath 'stylesheets',
    assets.appendPath 'components'
    assets.appendPath 'vendor'
    assets.appendPath 'node_modules/joosy/lib'

    server.use '/assets', mincer.createServer(assets)
    server.use connect.static('public')
    server.listen 4000