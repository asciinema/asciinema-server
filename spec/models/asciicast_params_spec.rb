require 'spec_helper'

describe AsciicastParams do

  describe '.build' do
    let(:asciicast_params) { described_class.build(input, headers) }

    let(:input) { {
      meta:          meta_file,
      stdout:        stdout_data_file,
      stdout_timing: stdout_timing_file
    } }
    let(:headers) { { 'User-Agent' => 'asciinema/0.9.7' } }

    let(:stdout_data_file) { double('stdout_data_file') }
    let(:stdout_timing_file) { double('stdout_timing_file') }

    let(:required_attrs) { {
      stdout_data:      stdout_data_file,
      stdout_timing:    stdout_timing_file,
      stdin_data:       nil,
      stdin_timing:     nil,
      username:         'kill',
      user_id:          nil,
      duration:         11.146430015563965,
      recorded_at:      DateTime.parse('Thu, 25 Jul 2013 20: 08: 57 +0000'),
      title:            'bashing :)',
      command:          '/bin/bash',
      shell:            '/bin/zsh',
      terminal_columns: 96,
      terminal_lines:   26,
      terminal_type:    'screen-256color',
      user_agent:       'asciinema/0.9.7',
      uname:            nil,
      api_token:        nil
    } }

    let(:token) { 'f33e6188-f53c-11e2-abf4-84a6c827e88b' }

    subject { asciicast_params.attributes }

    context "when uname given" do
      let(:meta_file) {
        fixture_file_upload(
          'spec/fixtures/meta-with-uname.json', 'application/json'
        )
      }

      let(:expected_attrs) {
        required_attrs.merge(
          user_agent: nil,
          api_token:  token,
          uname:      'Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07' +
                      ' UTC 2013 x86_64'
        )
      }

      it { should eq(expected_attrs) }
    end

    context "when no api_token given" do
      let(:meta_file) { fixture_file_upload('spec/fixtures/meta-no-token.json',
                                            'application/json') }
      let(:expected_attrs) { required_attrs }

      it { should eq(expected_attrs) }
    end

    context "when api_token given" do
      let(:meta_file) { fixture_file_upload('spec/fixtures/meta.json',
                                            'application/json') }

      context "and user with this token exists" do
        let(:user) { create(:user) }
        let!(:api_token) { create(:api_token, token: token, user: user) }
        let(:expected_attrs) { required_attrs.merge(user_id: user.id) }

        it { should eq(expected_attrs) }
      end

      context "and user with this token doesn't exist" do
        let(:expected_attrs) { required_attrs.merge(api_token: token) }

        it { should eq(expected_attrs) }
      end
    end
  end

end
