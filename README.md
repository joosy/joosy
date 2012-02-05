# Joosy
## What's Joosy
Joosy is a full-stack javascript MVC framework, which follows Rails philosophy of using conventions over configuration, which eliminates boilerplate and makes it easy to extend an app.

## How is Joosy different from X
Honestly saying, Joosy is not typical JS MVC framework, some its concepts go against many common patterns. Basically, Joosy's purposes just differ from purposes of, say, Backbone, Spine or Ember.

Actually, all they try to provide well-known MVC on the client side, which just doesn't work. "But didn't you say Joosy is a MVC thingy?", you ask. Not really, it adopts some MVC patters, while trying to fit them into client-side nature.

## Core Joosy concepts
In Joosy you have several key concepts, they are Layouted templates, Pages, Resources, and Widgets.

Layouts should be familiar to you, especially if you've worked with Rails. They just are made of common parts of several pages. App can have as many layouts as you want.

Pages are like controller actions. They are routed. Pages fetch data and pass it to pretty much everywhere. Pages are the heart of the appp

Resources are quite like models. Compared to Backbone, you do not have to strictly specify your model fields, Joosy is smart enough to learn them interacting with your REST backend.

Widgets are independent pieces of logic and templates that can be included almost anywhere in the app.

## Installation
`gem 'joosy', git: 'https://github.com/roundlake/joosy.git'`

Then you can use the entire set of generators Joosy provides. 

First you need to generate a Joosy skeleton and loader for your application

`rails g joosy:application APP_NAME`

`rails g joosy:preloader APP_NAME`

These command will generate an app directory structure and app loader inside `assets/javascript`:

    .
    ├── helpers
    │   └── application.js.coffee
    ├── layouts
    │   └── application.js.coffee
    ├── pages
    │   ├── application.js.coffee
    │   └── welcome
    │       └── index.js.coffee
    ├── resources
    ├── routes.js.coffee
    ├── templates
    │   ├── layouts
    │   │   └── application.jst.hamlc
    │   ├── pages
    │   │   └── welcome
    │   │       └── index.jst.hamlc
    │   └── widgets
    └── widgets

As you can see, it partially mimics Rails app structure. You might notice that by default Joosy uses CoffeeScript and HAMLc (CoffeeHaml).

There is one thing that might confuse you, what the heck is layout in coffee script? Well, in Joosy we decided that Layout should be a separate class, not only some html code. But let's move on.

### Helpers
You should be quite familiar with helpers. They help you to keep your code as DRY as possible. While we tried Backbone and Ember, we thought, why don't they have such a must-have thing as helpers? So we implemented them in Joosy.

### Routes
Routes, as their name suggests, just route the piece of request path after `#!` to a specific page (but aren't limited only to).

### Pages
As we mentioned, Pages are the heart of the entire application. They fetch data, trig different visual effects, pass some data to templates.

While building Pages, we stole Rails concept of after/before filters. So that's how the page gets bootstrapped:

* `beforeLoad`
* `fetch`
* `beforePaint`
* `paint`
* `afterLoad`

### Resources
Resources specify the entity, which Joosy queries from the REST backend.

### Widgets
Widgets are independent and reusable pieces of logic and representation. They can nest each other, they can be embedded in any view (with proper initialization).

### Templates
So there templates come. Each layout and page should have a template. By default, Joosy expects you to write your templates in HAML. But you can also use Eco or Jade, or any other tempting engine you like.

The great thing about Joosy templates is that they're really like Rails ones. In Joosy you can nest templates to as deep level as you want to. Joosy also provides you sort of Rails partials so your code stays really DRY.

The great thing is, templates can be rendered dynamically. Let me explain that: if you render some partial for your app's object or some template local vars, and then you object or var gets changed, this change is dynamically reflected on the template.

# License
Joosy is licensed under MIT. See MIT-LICENSE for the full license text.
