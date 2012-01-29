guard 'coffeescript', :output => 'tmp/spec/javascripts' do
  watch(%r{^spec/javascripts/(.+)[sS]pec\.js\.coffee$})
end

guard 'coffeescript', :output => 'tmp/spec/javascripts/helpers' do
  watch(%r{^spec/javascripts/helpers/(.+)\.js\.coffee$})
end

jquery_path = File.join(Gem.loaded_specs['jquery-rails'].full_gem_path, 'vendor/assets/javascripts')

guard 'sprockets', :destination => 'tmp/javascripts',
  :asset_paths => ['app/assets/javascripts', 'vendor/assets/javascripts', jquery_path],
  :root_file => 'app/assets/javascripts/joosy.js.coffee' do
  watch %r{^app/assets/javascripts/joosy/core.+\.js}
  watch 'app/assets/javascripts/joosy.js.coffee'
end

guard 'sprockets', :destination => 'tmp/javascripts',
  :asset_paths => ['app/assets/javascripts', 'vendor/assets/javascripts', jquery_path],
  :root_file => 'app/assets/javascripts/joosy/preloaders/caching.js.coffee' do
  watch 'app/assets/javascripts/joosy/preloaders/caching.js.coffee'
end

guard 'sprockets', :destination => 'tmp/javascripts',
  :asset_paths => ['app/assets/javascripts', 'vendor/assets/javascripts', jquery_path],
  :root_file => 'app/assets/javascripts/joosy/preloaders/inline.js.coffee' do
  watch 'app/assets/javascripts/joosy/preloaders/inline.js.coffee'
end

puts 'HI! Hit <Enter> to generate all stuff.'
