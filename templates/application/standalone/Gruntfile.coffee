module.exports = (grunt) ->

  grunt.loadNpmTasks 'joosy'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'

  #
  # Config
  #
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
        files:
          'public/assets/application.js': 'public/assets/application.js'

    cssmin:
      styles:
        files:
          'public/assets/application.css': 'public/assets/application.css'

  #
  # Tasks
  #
  grunt.registerTask 'compile', ['joosy:compile', 'uglify', 'cssmin']
  grunt.registerTask 'server',  ['joosy:server']