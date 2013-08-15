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
      # Pass static data to Stylus and HAML templates
      # config: require('./config.json')

      # Setup built-in development proxy to workaround Cross-Origin
      # proxy: '/joosy': 'http://joosy.ws'

      assets:
        root: 'application.*'
        greedy: '/'

    uglify:
      application:
        files:
          'public/application.js': 'public/application.js'

    cssmin:
      styles:
        files:
          'public/application.css': 'public/application.css'

    jasmine:
      application:
        src: 'public/application.js'
        options: 
          keepRunner: true
          outfile: 'spec/application.html'
          specs:   '.grunt/spec/*_spec.js'
          helpers: '.grunt/spec/helpers/environment.js'

  #
  # Tasks
  #
  grunt.loadTasks 'tasks'

  grunt.registerTask 'compile', ['joosy:compile', 'uglify', 'cssmin']
  grunt.registerTask 'server',  ['joosy:server']

  grunt.registerTask 'spec', ['coffee', 'joosy:compile', 'jasmine']

  grunt.registerTask 'joosy:postinstall', ['joosy:bower', 'joosy:compile']
