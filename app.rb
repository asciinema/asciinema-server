APP_ROOT = File.dirname(__FILE__)

require_relative 'config/init'
require_relative 'app/models'

set :root, File.dirname(__FILE__)
set :static, true
set :views, File.join(APP_ROOT, 'app', 'views')

helpers do
  def player_data(movie)
    data = File.read(movie.typescript.path).split("\n",2)[1]
    time = File.read(movie.timing.path)

    chars = "'" + data.bytes.map { |b| '\x' + format('%02x', b) }.join('') + "'";
    formatted_time = '[' + time.split("\n").map { |line| delay, n = line.split; '[' + delay.to_f.to_s + ',' + n.to_i.to_s + ']'}.join(',') + ']'

    out = "<script>\n"
    out << "var data = #{chars};\n"
    out << "var time = #{formatted_time};\n"
    out << "var cols = #{movie.terminal_cols};\n"
    out << "var lines = #{movie.terminal_lines};\n"
    out << "</script>"
    out
  end
end

def make_paperclip_mash(file_hash)
  mash = Mash.new
  mash['tempfile'] = file_hash[:tempfile]
  mash['filename'] = file_hash[:filename]
  mash['content_type'] = file_hash[:type]
  mash['size'] = file_hash[:tempfile].size
  mash
end

get %r{/(?<id>\d+)} do
  @movie = Movie.get(params[:id]) or pass
  erb :show
end

get '/' do
  @movies = Movie.all(:order => :created_at.desc)
  erb :index
end

get '/about' do
  erb :about
end

post '/scripts' do
  movie = Movie.new(
    :terminal_cols => params[:terminal_cols],
    :terminal_lines => params[:terminal_lines],
    :typescript => make_paperclip_mash(params[:typescript]),
    :timing => make_paperclip_mash(params[:timing])
  )

  if movie.save
    response.status = 201
    content_type = :json
    movie.to_json
  else
    response.status = 422
    content_type = :json
    movie.errors.to_json
  end
end
