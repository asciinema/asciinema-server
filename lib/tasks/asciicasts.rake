namespace :asciinema do
  desc "Assign anonymous asciicasts to dummy users"
  task assign_asciicasts_to_users: :environment do
    Asciicast.transaction do |tx|
      Asciicast.where('api_token IS NOT NULL').each do |asciicast|
        user = User.for_api_token(asciicast.api_token, asciicast.username)
        puts "assigning asciicast ##{asciicast.id} to user ##{user.id} (#{user.nickname})"
        asciicast.user = user
        asciicast.username = nil
        asciicast.api_token = nil
        asciicast.save!
      end
    end
  end
end
