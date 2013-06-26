# Joosy 1.2: Feather

[![NPM version](https://badge.fury.io/js/joosy.png)](http://badge.fury.io/js/joosy)
[![Build Status](https://travis-ci.org/joosy/joosy.png)](https://travis-ci.org/joosy/joosy)
[![Dependency Status](https://gemnasium.com/joosy/joosy.png)](https://gemnasium.com/joosy/joosy)

## WARNING!!!

Master branch is currently totally incompatible with the stable 1.1 and 1.0 branches. 1.2 features
total restructuring of the way we build the gem and the way you are supposed to include it.

To keep things working please use either

```ruby
  gem 'joosy', '~> 1.1.0'
```

or

```ruby
  gem 'joosy', github: 'joosy/joosy', branch: '1.1'
```

[Guides](http://guides.joosy.ws/) and [API](http://api.joosy.ws/) are also bound to 1.1 branch.
Again – make sure you use proper gem versions.

### Whatever! I'm ninja!

Below in this README you will find new installation instructions. They are still very likely
to change or work not as expected while 1.2 branch is still early alpha.

Keep track on what's going on at the [Wiki](https://github.com/joosy/joosy/wiki#12-feather)

## What is Joosy

![Joosy](http://f.cl.ly/items/2N2J453J2B353F1A0t0I/joocy1.1.png)

Joosy is a javascript framework. Being a harmonious extensions to Rails it introduces everything you like about this framework right to your browser. Ready conventions set, extensive CoffeeScript, HAML support, Helpers, seamless backend integration, automatic code generation and more.

Joosy allows you to create web apps which work completely in the browser. So that, it helps you to relocate all your Rails Views to the client side. It also helps you with managing the growing quantity of JS code. On another hand, it makes your backend to have exactly one function – to be a simple REST provider. That leads to easier development support and improves the scalability greatly.

Besides Rails, Joosy is based on top of [CoffeeScript](http://coffeescript.org/), [jQuery](http://jquery.com/) and [Sugar.js](http://sugarjs.com/) in role of ActiveSupport.

Finally, Joosy boosts your development drastically. Just like the Rails framework does.

### Jump in with Rails

Add Joosy gem to your Gemfile:

```ruby
  gem 'joosy-rails', '~> 1.0.0'
```

Use built-in generator to seed a basic application:

    rails g joosy:application

Make sure to remove `public/index.html` and you are ready to go with [localhost:3000/](http://localhost:3000/). The main application code will appear at `app/assets/javascripts` directory. HTML canvas of the application can be found at `app/views/layouts/joosy.html.erb`.

### Jump in with Sinatra

### Standalone application

Make sure you have Node.js installed. Install joosy package globally to start with:

    npm install joosy -g

Now run basic application generator with the following command:

    joosy new dummy

The main application code will appear at `source` directory. `stylesheets` is for Stylus-based styles and the main canvas of page is defined at `source/index.haml`. Now you can `grunt joosy:server` to start development server at [localhost:4000/](http://localhost:4000/).

To generate assets statically prior to the deployment run

    grunt joosy:compile

Your assets will appear at `public/` directory.

## Hacking

  * Ensure you have Node.js available on your system
  * Clone the project
  * Run `npm install` to get required Node modules
  * Run `bower install` to get require JS components
  * Run `grunt test` to run specs once
  * Run `grunt` to watch sources (automatic changes compilations) and run test-server (get your browser to http://localhost:8888/)

While current repository is, at the same time: NPM package, Ruby gem and Bower component – the main Core
environment is Node.js.

## Credits

* Boris Staal ([@_inossidabile](http://twitter.com/#!/_inossidabile)) [![endorse](http://api.coderwall.com/inossidabile/endorsecount.png)](http://coderwall.com/inossidabile)
* Andrew Shaydurov ([@ImGearHead](http://twitter.com/#!/ImGearHead))
* Alexander Pavlenko ([@alerticus](http://twitter.com/#!/alerticus))
* Peter Zotov ([@whitequark](http://twitter.com/#!/whitequark))

## LICENSE

It is free software, and may be redistributed under the terms of MIT license.