require 'spec_helper'
require 'stringio'

describe AsciicastParams do

  describe '.build' do
    subject { described_class.build(input, user_agent) }

    let(:input) { {
      meta:          StringIO.new(meta.to_json),
      stdout:        stdout_data_file,
      stdout_timing: stdout_timing_file,
    } }

    let(:user_agent) { 'asciinema/0.9.7' }

    let(:stdout_data_file) { double('stdout_data_file') }
    let(:stdout_timing_file) { double('stdout_timing_file') }

    let(:meta) { {
      command:    '/bin/bash',
      duration:   11.146430015563965,
      shell:      '/bin/zsh',
      term:       { lines: 26, columns: 96, type: 'screen-256color' },
      title:      'bashing :)',
      user_token: 'f33e6188-f53c-11e2-abf4-84a6c827e88b',
      username:   'kill',
    } }

    let(:user) { double('user') }

    let(:expected_attrs) { {
      command:          '/bin/bash',
      duration:         11.146430015563965,
      shell:            '/bin/zsh',
      stdin_data:       nil,
      stdin_timing:     nil,
      stdout_data:      stdout_data_file,
      stdout_timing:    stdout_timing_file,
      terminal_columns: 96,
      terminal_lines:   26,
      terminal_type:    'screen-256color',
      title:            'bashing :)',
      user:             user,
      user_agent:       'asciinema/0.9.7',
    } }

    before do
      allow(User).to receive(:for_api_token).
        with('f33e6188-f53c-11e2-abf4-84a6c827e88b', 'kill') { user }
    end

    it { should eq(expected_attrs) }

    context "when uname given" do
      before do
        meta[:uname] = 'Linux 3.9.9-302.fc19.x86_64'
        expected_attrs[:uname] = 'Linux 3.9.9-302.fc19.x86_64'
        expected_attrs.delete(:user_agent)
      end

      it { should eq(expected_attrs) }
    end
  end

end
