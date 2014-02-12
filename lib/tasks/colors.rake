namespace :asciinema do
  desc 'Generate color palettes'
  task :gen_color_palettes do
    require 'yaml'

    default = YAML.load_file('config/colors/default.yml')
    rgb = YAML.load_file('config/colors/rgb.yml')
    colors = default.merge(rgb)

    out = ""

    colors.each do |n, value|
      out << ".fg#{n} { color: #{value} }\n"
      out << ".bg#{n} { background-color: #{value} }\n"
    end

    File.open('app/assets/stylesheets/colors.css', 'w') { |f| f.write out }

    File.open('app/assets/javascripts/player/colors.js', 'w') do |f|
      f.write "Asciinema.colors = #{JSON.dump(colors)};"
    end
  end
end
