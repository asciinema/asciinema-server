# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# # Run JS and CoffeeScript files in a typical Rails 3.1 fashion, placing Underscore templates in app/views/*.jst
# # Your spec files end with _spec.{js,coffee}.

# spec_location = "spec/javascripts/%s_spec"

# # uncomment if you use NerdCapsSpec.js
# # spec_location = "spec/javascripts/%sSpec"

# guard 'jasmine-headless-webkit' do
#   # watch(%r{^app/views/.*\.jst$})

#   watch(%r{^app/assets/javascripts/(.*?)\..*}) do |m|
#     newest_js_file("spec/javascripts/#{m[1]}_spec")
#   end

#   watch(%r{^spec/javascripts/(.*)_spec\..*}) do |m|
#     newest_js_file(spec_location % m[1])
#   end
# end

guard 'jasmine' do
  watch(%r{app/assets/javascripts/(.+)\.(js\.coffee|js|coffee)$}) { |m| "spec/javascripts/#{m[1]}_spec.#{m[2]}" }
  watch(%r{spec/javascripts/(.+)_spec\.(js\.coffee|js|coffee)$})  { |m| puts m.inspect; "spec/javascripts/#{m[1]}_spec.#{m[2]}" }
  watch(%r{spec/javascripts/spec\.(js\.coffee|js|coffee)$})       { "spec/javascripts" }
end
