require 'rails_helper'

describe UsersController do

  describe '#show' do
    subject { get :show, username: username }

    let(:username) { user.username }

    before do
      subject
    end

    context "when confirmed user username given" do
      let(:user) { create(:user) }

      it 'renders "show" template' do
        should render_template('show')
      end
    end

    context "when unconfirmed user username given" do
      let(:user) { create(:unconfirmed_user) }

      it "responds with 404" do
        expect(subject).to be_not_found
      end
    end

    context "when fictional username given" do
      let(:username) { 'nononono-no' }

      it "responds with 404" do
        expect(subject).to be_not_found
      end
    end
  end

end
