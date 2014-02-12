require 'spec_helper'

describe AvatarHelper do

  def expected_img(src)
    %(<img alt="satyr" class="avatar" src="#{src}" />)
  end

  let(:decorator) { double('decorator', h: h, model: model).
                    extend(described_class) }
  let(:model) { double('model', username: 'satyr', avatar_url: avatar_url,
                                email: email) }

  describe '#avatar_image_tag' do
    subject { decorator.avatar_image_tag }

    context "when user has an avatar_url" do
      let(:avatar_url) { 'http://avatar/url' }

      context "and user has an email" do
        let(:email) { 'foo@email.com' }

        it { should eq(expected_img(
          '//gravatar.com/avatar/9dcfeb70fe212ea12562dddd22b0fc92?s=128')) }
      end

      context "and user has no email" do
        let(:email) { nil }

        it { should eq(expected_img("http://avatar/url")) }
      end
    end

    context "when user has neither email nor avatar_url" do
      let(:email) { nil }
      let(:avatar_url) { nil }

      it { should eq(expected_img('/assets/default_avatar.png')) }
    end
  end

end
