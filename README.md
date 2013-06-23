# Joosy 1.2: Feather

Feather brings a total project restructuring:

  * Core assets separated from Ruby and switched to Node builders and environment (done)
  * Node-based static project generators and builders (done)
  * Bower-based dependency management (done)
  * Preloaders separated from core (in progress)
  * AMD support and basic integration (in progress)
  * Jasmine-based test-suite (in progress)

## Jumping in

  * Ensure you have Node.js available on your system
  * Clone the project
  * Run `npm install` to get required Node modules
  * Run `bower install` to get require JS components
  * Run `grunt build` to build Joosy and specs
  * Run `grunt test` to run specs once
  * Run `grunt` to watch sources (automatic changes compilations) and run test-server (get your browser to http://localhost:8888/)

## Incompatible changes

  * Elements now get assigned as `$name' instead of just `name`.