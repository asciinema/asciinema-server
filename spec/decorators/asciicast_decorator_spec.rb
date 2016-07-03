require 'rails_helper'

describe AsciicastDecorator do
  include Draper::ViewHelpers

  let(:asciicast) { Asciicast.new }
  let(:decorator) { described_class.new(asciicast) }

  subject { decorator.send(method) }

  describe '#os' do
    let(:method) { :os }

    context 'when user_agent is present' do
      context 'and the OS is Linux (pre-0.9.9 client)' do
        before do
          asciicast.user_agent =
            "asciinema/0.9.7 CPython/3.3.1 " \
            "Linux/3.8.0-30-generic-x86_64-with-Ubuntu-13.04-raring"
        end

        it { should == 'Linux' }
      end

      context 'and the OS is *BSD (pre-0.9.9 client)' do
        before do
          asciicast.user_agent =
            "asciinema/0.9.8 CPython/2.7.5 " \
            "FreeBSD/10.0-RELEASE-p7-amd64-64bit-ELF"
        end

        it { should == 'FreeBSD' }
      end

      context 'and the OS is Linux (0.9.9+ client)' do
        before do
          asciicast.user_agent =
            "asciinema/0.9.9 gc/go1.3 " \
            "linux-amd64"
        end

        it { should == 'Linux' }
      end

      context 'and the OS is OS X (pre-0.9.9 client)' do
        before do
          asciicast.user_agent =
            "asciinema/0.9.7 CPython/2.7.4 " \
            "Darwin/10.0.0-i386-64bit"
        end

        it { should == 'OS X' }
      end

      context 'and the OS is OS X (0.9.9+ client)' do
        before do
          asciicast.user_agent =
            "asciinema/0.9.9 gc/go1.3 " \
            "darwin-amd64"
        end

        it { should == 'OS X' }
      end

      context 'and the OS is other (pre-0.9.9 client)' do
        before do
          asciicast.user_agent = "asciinema/0.9.7 CPython/2.7.4 Jola/Misio-Foo"
        end

        it 'should return first token' do
          should == 'Jola'
        end
      end

      context 'and the OS is other (0.9.9+ client)' do
        before do
          asciicast.user_agent = "asciinema/0.9.9 gc/go1.3 jola-amd64"
        end

        it 'should return first token titleized' do
          should == 'Jola'
        end
      end
    end

    context 'when uname is present' do
      context "and it's Linux-like" do
        before do
          asciicast.uname = "Linux t430u 3.5.0-18-generic #29-Ubuntu SMP"
        end

        it { should == 'Linux' }
      end

      context "and it's Darwin-like" do
        before do
          asciicast.uname = "Darwin local 10.3.0 Darwin Kernel Version 10.3.0"
        end

        it { should == 'OS X' }
      end

      context "and it's other" do
        before do
          asciicast.uname = "Jola Misio Foo"
        end

        it 'should return first token' do
          should == 'Jola'
        end
      end
    end

    context 'when user_agent and uname are nil' do
      before do
        asciicast.user_agent = nil
        asciicast.uname = nil
      end

      it { should == 'unknown' }
    end

    context 'when user_agent and uname are a blank string' do
      before do
        asciicast.user_agent = ' '
        asciicast.uname = ' '
      end

      it { should == 'unknown' }
    end
  end

  describe '#terminal_type' do
    let(:method) { :terminal_type }

    it "returns asciicast's terminal_type when non-blank" do
      asciicast.terminal_type = 'foo'
      should == 'foo'
    end

    it 'returns "?" for blank terminal_type' do
      asciicast.terminal_type = nil
      should == '?'

      asciicast.terminal_type = ''
      should == '?'
    end
  end

  describe '#shell' do
    let(:method) { :shell }

    it 'returns last segment of shell path' do
      asciicast.shell = '/usr/bin/some/bar'
      should == 'bar'
    end
  end

  describe '#title' do
    let(:method) { :title }

    it "prefers model title to command and id" do
      asciicast.attributes = {
        title: 'the title',
        command: 'the-command',
        id: 123,
      }

      expect(subject).to eq('the title')
    end

    it "prefers command to id when command is not equal to shell" do
      asciicast.attributes = {
        title: '',
        command: '/bin/bash',
        shell: '/bin/zsh',
        id: 123,
      }

      expect(subject).to eq('/bin/bash')
    end

    it "prefers id to command when command is equal to shell" do
      asciicast.attributes = {
        title: '',
        command: '/bin/zsh',
        shell: '/bin/zsh',
        id: 123,
      }

      expect(subject).to eq('asciicast:123')
    end

    it "returns id when no model title nor command set" do
      asciicast.attributes = {
        title: '',
        command: '',
        shell: '/bin/zsh',
        id: 123,
      }

      expect(subject).to eq('asciicast:123')
    end
  end

  describe '#description' do
    let(:method) { :description }

    context 'when description present' do
      before do
        asciicast.description = '**yay**'
      end

      it 'should be processed with markdown processor' do
        should == "<p><strong>yay</strong></p>\n"
      end
    end

    context 'when no description' do
      before do
        asciicast.description = ''
      end

      it { should be(nil) }
    end
  end

  describe '#thumbnail' do
    let(:json) { [:qux] }
    let(:snapshot) { double('snapshot', :thumbnail => thumbnail) }
    let(:thumbnail) { double('thumbnail') }

    before do
      RSpec::Mocks.configuration.verify_partial_doubles = false # for stubbing "helpers"
    end

    after do
      RSpec::Mocks.configuration.verify_partial_doubles = true
    end

    before do
      allow(asciicast).to receive(:snapshot) { json }
      allow(Snapshot).to receive(:build).with(json) { snapshot }
      allow(helpers).to receive(:render).
        with('asciicasts/thumbnail', :thumbnail => thumbnail) { '<pre></pre>' }
    end

    it "returns snapshot's thumbnail rendered by SnapshotPresenter" do
      expect(decorator.thumbnail).to eq('<pre></pre>')
    end
  end

  describe '#formatted_duration' do
    subject { decorator.formatted_duration }

    context "when it's below 1 minute" do
      before do
        asciicast.duration = 7.49
      end

      it { should eq("00:07") }
    end

    context "when it's over 1 minute" do
      before do
        asciicast.duration = 77.49
      end

      it { should eq("01:17") }
    end
  end

end
