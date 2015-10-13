require 'rails_helper'

describe PlaybackOptions do
  it 'coerces time' do
    expect(PlaybackOptions.new.t).to eq(nil)
    expect(PlaybackOptions.new(t: '').t).to eq(nil)
    expect(PlaybackOptions.new(t: '5').t).to eq(5)
    expect(PlaybackOptions.new(t: '5s').t).to eq(5)
    expect(PlaybackOptions.new(t: '2m9s').t).to eq(129)
    expect(PlaybackOptions.new(t: '2:09').t).to eq(129)
    expect(PlaybackOptions.new(t: '1:02:09').t).to eq(3600+129)
  end
end
