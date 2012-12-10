require 'spec_helper'

describe AsciicastDecorator do
  let(:asciicast) { Asciicast.new }
  let(:decorated) { AsciicastDecorator.new(asciicast) }

  subject { decorated.send(method) }

  describe '#os' do
    let(:method) { :os }

    context 'for Linux-like uname' do
      before do
        asciicast.uname = "Linux t430u 3.5.0-18-generic #29-Ubuntu SMP"
      end

      it { should == 'Linux' }
    end

    context 'for Darwin-like uname' do
      before do
        asciicast.uname = "Darwin local 10.3.0 Darwin Kernel Version 10.3.0"
      end

      it { should == 'OSX' }
    end

    context 'for other systems' do
      before do
        asciicast.uname = "Jola Misio Foo"
      end

      it 'should return first token' do
        should == 'Jola'
      end
    end

    context 'when uname is nil' do
      before do
        asciicast.uname = nil
      end

      it { should == 'unknown' }
    end

    context 'when uname is blank string' do
      before do
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

    context 'when title is present' do
      before do
        asciicast.title = 'tit'
      end

      it { should == 'tit' }
    end

    context 'when no title but command is present' do
      before do
        asciicast.title = nil
        asciicast.command = 'cmd'
      end

      it { should == '$ cmd' }
    end

    context 'when no title nor command is present' do
      before do
        asciicast.title = nil
        asciicast.command = nil
        asciicast.id = 999
      end

      it 'should be in the form of "#<id>"' do
        should == "##{asciicast.id}"
      end
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

      it { should == '<em>No description.</em>' }
    end
  end

  describe '#thumbnail' do
    pending
  end

  describe '#author' do
    let(:method) { :author }

    context 'when user present' do
      let(:nickname) { double('nickname') }
      let(:user) { double('user', :nickname => nickname) }

      before do
        asciicast.user = User.new
      end

      it 'returns nickname from decorated user' do
        decorated.should_receive(:user).twice.and_return(user)
        subject.should == nickname
      end
    end

    context 'when username present on asciicast' do
      before do
        asciicast.user = nil
        asciicast.username = 'foo'
      end

      it { should == '~foo' }
    end

    context 'when no user nor username present' do
      before do
        asciicast.user = nil
        asciicast.username = nil
      end

      it { should == 'anonymous' }
    end
  end

  describe '#author_link' do
    let(:method) { :author_link }

    context 'when user present' do
      let(:link) { double('link') }
      let(:user) { double('user', :link => link) }

      before do
        asciicast.user = User.new
      end

      it 'returns link from decorated user' do
        decorated.should_receive(:user).twice.and_return(user)
        subject.should == link
      end
    end

    context 'when no user present' do
      let(:author) { double('author') }

      before do
        asciicast.user = nil
      end

      it 'returns author from decorated user' do
        decorated.should_receive(:author).and_return(author)
        subject.should == author
      end
    end
  end

  describe '#author_img_link' do
    let(:method) { :author_img_link }

    context 'when user present' do
      let(:img_link) { double('img_link') }
      let(:user) { double('user', :img_link => img_link) }

      before do
        asciicast.user = User.new
      end

      it 'returns img_link from decorated user' do
        decorated.should_receive(:user).twice.and_return(user)
        subject.should == img_link
      end
    end

    context 'when no user present' do
      let(:avatar_image) { double('avatar_image') }
      let(:h) { double('h') }

      before do
        asciicast.user = nil
      end

      it 'returns avatar_image_tag' do
        decorated.stub!(:h => h)
        h.should_receive(:avatar_image_tag).with(nil).and_return(avatar_image)
        subject.should == avatar_image
      end
    end
  end

  describe '#other_by_user' do
    pending
  end
end
