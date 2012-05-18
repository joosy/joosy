![Joosy](http://f.cl.ly/items/2N2J453J2B353F1A0t0I/joocy1.1.png)

## What is Joosy

Joosy is a javascript framework. Being a harmonious extensions to Rails it introduces everything you like about this framework right to your browser. Ready conventions set, extensive CoffeeScript, HAML support, Helpers, seamless backend integration, automatic code generation and more.

Joosy allows you to create web apps which work completely in the browser. So that, it helps you to relocate all your Rails Views to the client side. It also helps you with managing the growing quantity of JS code. On another hand, it makes your backend to have exactly one function --  to be a simple REST provider. That leads to easier development support and improves the scalability greatly.

Besides Rails, Joosy is based on top of [CoffeeScript](http://coffeescript.org/), [jQuery](http://jquery.com/) and [Sugar.js](http://sugarjs.com/) in role of ActiveSupport.

Finally, Joosy boosts your development drastically. Just like the Rails do.

* [Joosy basics](http://guides.joosy.ws/guides/basics/getting-started.html): introduction, backbone/ember comparison.
* [Joosy guides](http://guides.joosy.ws/): set of articles that will help you to learn the framework.
* [Joosy API](http://api.joosy.ws/): Codo-documented API of Joosy.

### Hello world app

Add Joosy gem to your Gemfile:

    gem 'joosy'

Using built-in generators you can quickly generate small app inside your Rails app to see Joosy application from inside a bit.

    rails g joosy:application dummy
    rails g joosy:preloader dummy

Now you can `rails s` and see Joosy placeholder at [localhost:3000/dummy](http://localhost:3000/dummy)

Generated application will consist of one `Layout` and one `Page` both including very basic practices of Joosy.

# Hacking

Don't forget to run tests!

```ruby
bundle install
rake guard
rake jasmine
```

http://localhost:8888/ <- they are here :)

Credits
-------

<img src="http://roundlake.ru/assets/logo.png" align="right" />

* Boris Staal ([@_inossidabile](http://twitter.com/#!/_inossidabile))
* Andrew Shaydurov
* Alexander Pavlenko ([@alerticus](http://twitter.com/#!/alerticus))
* Peter Zotov ([@whitequark](http://twitter.com/#!/whitequark))

LICENSE
-------

It is free software, and may be redistributed under the terms of MIT license.