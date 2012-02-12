# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'jasmine', :server => :none, :jasmine_url => 'http://localhost:3000/jasmine' do
  watch(%r{app/assets/javascripts/(.+)\.(js\.coffee|js|coffee)$}) { |m| "spec/javascripts/#{m[1]}_spec.#{m[2]}" }
  watch(%r{spec/javascripts/(.+)_spec\.(js\.coffee|js|coffee)$})  { |m| puts m.inspect; "spec/javascripts/#{m[1]}_spec.#{m[2]}" }
  watch(%r{spec/javascripts/spec\.(js\.coffee|js|coffee)$})       { "spec/javascripts" }
end
