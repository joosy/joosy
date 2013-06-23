module.exports = (grunt) ->

  grunt.loadNpmTasks 'joosy'

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
        include: ['source', 'components', 'vendor', 'node_modules/joosy/src']
        src: 'application.coffee'
        dest: 'public/assets/application.js'

    stylus:
      application:
        options:
          paths: ['stylesheets', 'public']
        files: 'public/assets/application.css': 'stylesheets/application.styl'

    uglify:
      application:
        options:
          sourceMap: 'public/assets/application.js.map'
        files:
          'public/assets/application.js': 'public/assets/application.js'

    cssmin:
      application:
        files:
          'public/assets/application.css': 'public/assets/application.css'