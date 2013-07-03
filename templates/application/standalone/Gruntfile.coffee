module.exports = (grunt) ->

  grunt.loadNpmTasks 'joosy'

  grunt.initConfig
    joosy:
      # config: require('./config.json')
      # proxy: [ {'/joosy': 'http://joosy.ws'} ]
      assets:
        application:
          src: 'application.coffee'
          dest: 'public/assets/application.js'
        styles:
          src: 'application.styl'
          dest: 'public/assets/application.css'
      haml:
        application:
          src: 'index.haml'
          dest: 'public/index.html'

    uglify:
      application:
        options:
          sourceMap: 'public/assets/application.js.map'
        files:
          'public/assets/application.js': 'public/assets/application.js'

    cssmin:
      styles:
        files:
          'public/assets/application.css': 'public/assets/application.css'