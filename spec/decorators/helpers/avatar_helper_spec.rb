require 'rails_helper'

describe AvatarHelper do

  def expected_img(src)
    %(<img alt="satyr" class="avatar" src="#{src.gsub('&', '&amp;')}" />)
  end

  let(:decorator) { double('decorator', h: h, model: model).
                    extend(described_class) }
  let(:model) { double('model', id: 1, username: 'satyr', email: email) }

  describe '#avatar_image_tag' do
    subject { decorator.avatar_image_tag }

    context "when user has an email" do
      let(:email) { 'foo@email.com' }

      it { should eq(expected_img(
        '//gravatar.com/avatar/9dcfeb70fe212ea12562dddd22b0fc92?s=128&d=retro')) }
    end

    context "when user has no email" do
      let(:email) { nil }

      it { should eq(expected_img(
        '//gravatar.com/avatar/40affe80f7becd02ac38d316f7fe7057?s=128&d=retro')) }
    end
  end

end
