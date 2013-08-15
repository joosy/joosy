module.exports = (grunt) ->

  grunt.config.data.coffee ||= {}

  grunt.config.data.coffee.specs =
    expand: true
    src: 'spec/**/*_spec.coffee'
    dest: '.grunt'
    ext: '.js'

  grunt.config.data.coffee.spec_helpers =
      expand: true
      src: 'spec/helpers/**/*.coffee'
      dest: '.grunt'
      ext: '.js'