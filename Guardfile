guard 'coffeescript', :output => 'tmp/spec/javascripts' do
  watch(%r{^spec/javascripts/.+[sS]pec\.js\.coffee$})
end

guard 'coffeescript', :output => 'tmp/spec/javascripts/helpers' do
  watch(%r{^spec/javascripts/helpers/.+\.js\.coffee$})
end

require 'guard/sprockets'
jquery_path = File.join(Gem.loaded_specs['jquery-rails'].full_gem_path, 'vendor/assets/javascripts')
sprocket = Sprockets.new([], :destination => 'tmp/javascripts',
  :asset_paths => ['app/assets/javascripts', 'vendor/assets/javascripts', jquery_path])
guard 'shell' do
  watch(%r{^app/assets/javascripts/.+\.js}) do
    sprocket.run_on_change(['app/assets/javascripts/joosy.js.coffee'])
  end
end

ObjectSpace.each_object(Guard).select{|o| o.class == Shell }.first.instance_eval do
  def run_all
    run_on_change(Watcher.match_files(self, ['app/assets/javascripts/joosy.js.coffee']))
  end
end

puts 'HI! Hit <Enter> to generate all stuff.'
