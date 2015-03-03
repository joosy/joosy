# Joosy 1.2: Feather

![Joosy](http://f.cl.ly/items/2N2J453J2B353F1A0t0I/joocy1.1.png)

Joosy is a javascript framework. Being a harmonious extensions to Rails it introduces everything you like about backend right to your browser. Ready conventions set, extensive CoffeeScript, HAML support, Helpers, seamless backend integration, automatic code generation and more.

[![NPM version](https://badge.fury.io/js/joosy.png)](http://badge.fury.io/js/joosy)
[![Build Status](https://travis-ci.org/joosy/joosy.png)](https://travis-ci.org/joosy/joosy)
[![Dependency Status](https://gemnasium.com/joosy/joosy.png)](https://gemnasium.com/joosy/joosy)

---

## WARNING!!!

Master branch is currently totally incompatible with the stable 1.1 and 1.0 branches. 1.2 features
total restructuring of the way we build the gem and the way you are supposed to include it.

To keep things working please use either

```ruby
  gem 'joosy', '~> 1.1.1'
```

or

```ruby
  gem 'joosy', github: 'joosy/joosy', branch: '1.1'
```

[Guides](http://guides.joosy.ws/) are still bound to 1.1 branch! [API](http://api.joosy.ws/) docs
are available for all current versions. Again – make sure you use proper gem versions.

### Whatever! I'm ninja!

Below in this README you will find new installation instructions. 1.2 branch is currently in beta.
It means we are in feature-freeze mode and interface is unlikely to change. But things are still
unstable and the release can contain tiny inconsistencies that might be required to make things work.

Keep track on what's going on at the [Wiki](https://github.com/joosy/joosy/wiki#12-feather)

---

## What is Joosy

Joosy allows you to create web apps which work completely in the browser. So that, it helps you to relocate all your Rails Views to the client side. It also helps you with managing the growing quantity of JS code. On another hand, it makes your backend to have exactly one function – to be a simple REST provider. That leads to easier development support and improves the scalability greatly.

Besides Rails, Joosy is based on top of [CoffeeScript](http://coffeescript.org/), [jQuery](http://jquery.com/) and [Sugar.js](http://sugarjs.com/) in role of ActiveSupport.

Finally, Joosy boosts your development drastically. Just like the Rails framework does.

### Jump in with Rails

Add Joosy gem to your Gemfile:

```ruby
  gem 'joosy-rails', '~> 1.0.0.RC2'
```

Use built-in generator to seed a basic application:

    rails g joosy:application

Make sure to remove `public/index.html` and you are ready to go with [localhost:3000](http://localhost:3000/). The main application code can be found at `app/assets/javascripts` directory. HTML canvas of the application is at `app/views/layouts/joosy.html.erb`.

### Jump in with Sinatra

### Standalone application

Standalone mode of Joosy is based on [Yeoman](http://yeoman.io) and [Grill](https://github.com/joosy/grill). Start from installing proper Yeoman extension:

    npm install -g yo generator-joosy

Now create a directory to use a project root and run application generator:

    mkdir new dummy
    cd dummy
    yo joosy

The main application code will appear at `source` directory. `stylesheets` is for Stylus-based styles and the main canvas of page is defined at `source/haml/index.haml`. Now you can `grunt server` to start development server at [localhost:4000](http://localhost:4000/).

To generate assets statically prior to the deployment run:

    grunt compile

You assets are at `public/` directory, enjoy!

* [List of supported generators](https://github.com/joosy/generator-joosy#available-in-app-generators)
* [Commands and options of Grill](https://github.com/joosy/grill#commands)

## Hacking

  * Ensure you have Node.js available on your system
  * Clone the project
  * Run `npm install` to get required Node modules
  * Run `bower install` to get required JS components
  * Run `grunt testem` to run all specs in all available browsers
  * Run `grunt testem:*` where `*` is then name of an environment to run the environment in the development mode. Check `Gruntfile.coffee` (section **testem**) for the list of existing environments.

While current repository is at the same time NPM package, Ruby gem and Bower component, – the main Core
environment is Node.js.

## Maintainers

* Boris Staal, [@inossidabile](http://staal.io)
* Andrew Shaydurov, [@ImGearHead](http://twitter.com/ImGearHead)
* Alexander Pavlenko, [@alerticus](http://twitter.com/alerticus)

## License

Copyright 2011-2013 [Boris Staal](http://staal.io)

It is free software, and may be redistributed under the terms of MIT license.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/joosy/joosy/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

