guard 'coffeescript',
  :output => 'tmp/javascripts',
  :all_on_start => true do
    watch(%r{^vendor/assets/javascripts/(.+)\.js\.coffee$})
end

guard 'coffeescript',
  :output => 'tmp/spec/javascripts',
  :all_on_start => true do
    watch(%r{^spec/javascripts/(.+)[sS]pec\.js\.coffee$})
end

guard 'coffeescript',
  :output => 'tmp/spec/javascripts/helpers',
  :all_on_start => true do
    watch(%r{^spec/javascripts/helpers/(.+)\.js\.coffee$})
end