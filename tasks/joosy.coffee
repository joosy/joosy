#
# Joosy utilizes Grill to setup standalone environment
# Check out https://github.com/inossidabile/grill
#
Grill = require('grill')

module.exports = (grunt) ->

  Grill.setup grunt,
    prefix: 'joosy'
    assets:
      vendor: ['vendor/*', 'node_modules/joosy/source']