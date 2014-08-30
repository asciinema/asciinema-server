require 'rails_helper'

describe ApplicationHelper do

  describe '#browser_id_user' do
    let(:session) { {} }

    subject { helper.browser_id_user }

    before do
      allow(helper).to receive(:session) { session }
      allow(helper).to receive(:current_user) { user }
    end

    context "when current_user is present" do
      let(:user) { double('user', email: 'foo@bar.com') }

      it { should eq("'foo@bar.com'".html_safe) }
    end

    context "when current_user isn't present" do
      let(:user) { nil }

      it { should eq('null') }

      context "when new_user_email is present in session" do
        before do
          session[:new_user_email] = 'qux@quux.com'
        end

        it { should eq("'qux@quux.com'".html_safe) }
      end
    end
  end

end
