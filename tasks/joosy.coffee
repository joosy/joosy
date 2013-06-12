module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-mincer'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-bower-task'

  grunt.registerTask 'joosy:compile', ['joosy:compile:code', 'joosy:compile:styles', 'joosy:compile:playground']
  grunt.registerTask 'joosy:compile:code', ['mince:application', 'uglify:application']
  grunt.registerTask 'joosy:compile:styles', ['stylus:application', 'cssmin:application']

  grunt.registerTask 'joosy:server', ['joosy:compile:playground', 'joosy:server:start']

  grunt.registerTask 'joosy:compile:playground', ->
    hamlc = require 'haml-coffee'
    grunt.file.write 'public/index.html', hamlc.compile(grunt.file.read 'source/index.haml')()

  grunt.registerTask 'joosy:server:start', ->
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