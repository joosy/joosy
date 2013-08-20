module.exports = (grunt) ->

  grunt.loadNpmTasks 'joosy'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-contrib-testem'

  #
  # Config
  #
  grunt.initConfig
    joosy:
      assets:
        root: 'application.*'
        greedy: '/'

      # Pass static data to Stylus and HAML templates
      # config: require('./config.json')

      # Setup built-in development proxy to workaround Cross-Origin
      # proxy: '/joosy': 'http://joosy.ws'

    uglify:
      application:
        files:
          'public/application.js': 'public/application.js'

    cssmin:
      application:
        files:
          'public/application.css': 'public/application.css'

    testem:
      application:
        src: [
          'public/application.js',
          'spec/helpers/*.coffee',
          'spec/**/*_spec.coffee'
        ]
        options:
          parallel: 4
          launch_in_dev: ['PhantomJS'],
          launch_in_ci: ['PhantomJS']

  #
  # Tasks
  #
  grunt.registerTask 'compile', ['joosy:compile', 'uglify', 'cssmin']
  grunt.registerTask 'server',  ['joosy:server']

  grunt.registerTask 'spec', ['testem']

  grunt.registerTask 'deploy', ->
    if process.env['NODE_ENV'] == 'production'
      grunt.task.run ['joosy:bower', 'joosy:compile'] 
