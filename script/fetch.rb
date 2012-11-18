#!/usr/bin/env ruby

require 'open-uri'
require 'json'
require 'fileutils'
require 'base64'

id = ARGV[0]

id = id[/\d+/].to_i

url = "http://ascii.io/a/#{id}.json"

json = open(url).read
data = JSON.parse(json)

dir = "tmp/fetched/#{id}"
FileUtils.mkdir_p(dir)
Dir.chdir(dir)

File.open('stdout', 'wb') do |f|
  stdout_data = Base64.decode64(data['escaped_stdout_data'])
  f.write stdout_data
end

File.open('stdout.time', 'w') do |f|
  data['stdout_timing_data'].each do |line|
    f.puts line.join(' ')
  end
end

system "bzip2 stdout.time && mv stdout.time.bz2 stdout.time"

File.open('meta.json', 'w') do |f|
  json = {
    :duration => data['duration'],
    :term => {
      :columns => data['terminal_columns'],
      :lines => data['terminal_lines']
    }
  }

  f.write JSON.dump(json)
end
