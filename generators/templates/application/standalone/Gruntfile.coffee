module.exports = (grunt) ->

  grunt.loadNpmTasks 'joosy'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  #
  # Config
  #
  grunt.initConfig
    joosy:
      # Pass data to Stylus and HAML templates
      # config: require('./config.json')

      # Setup built-in development proxy to workaround Cross-Origin
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
          path: '/'
          src: 'index.haml'
          dest: 'public/index.html'
          url: ['/', '/index.html']

    uglify:
      application:
        files:
          'public/assets/application.js': 'public/assets/application.js'

    cssmin:
      styles:
        files:
          'public/assets/application.css': 'public/assets/application.css'

    jasmine:
      application:
        src: 'public/assets/application.js'
        options: 
          keepRunner: true
          outfile: 'spec/application.html'
          specs: '.grunt/spec/*_spec.js'
          helpers: '.grunt/spec/helpers/environment.js'

  #
  # Tasks
  #
  grunt.loadTasks 'tasks'

  grunt.registerTask 'compile', ['joosy:compile', 'uglify', 'cssmin']
  grunt.registerTask 'server',  ['joosy:server']

  grunt.registerTask 'spec', ['coffee', 'joosy:compile', 'jasmine']

  grunt.registerTask 'joosy:postinstall', ['joosy:bower', 'joosy:compile:production']
