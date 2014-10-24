require 'rails_helper'

module Api
  describe AsciicastsController do

    describe '#create' do
      subject { post :create, asciicast: attributes }

      let(:meta) {
        ActionDispatch::Http::UploadedFile.new(
          filename: 'meta.json',
          type: 'application/json',
          tempfile: StringIO.new('{ "username": "lol", "user_token": "token" }'),
        )
      }

      let(:attributes) { { 'title' => 'bar', 'meta' => meta } }
      let(:creator) { double('creator') }

      before do
        request.headers['User-Agent'] = 'Smith'
        allow(controller).to receive(:asciicast_creator) { creator }
        allow(AsciicastParams).to receive(:build) { { title: 'bar', user_agent: 'Smith' } }
      end

      context 'when the creator returns an asciicast' do
        let(:asciicast) { stub_model(Asciicast, id: 666) }

        before do
          allow(creator).to receive(:create).
            with({ title: 'bar', user_agent: 'Smith' }, 'token', 'lol') { asciicast }
          subject
        end

        it 'returns the status 201' do
          expect(response.status).to eq(201)
        end

        it 'returns the URL of created asciicast as the content body' do
          expect(response.body).to eq(asciicast_url(asciicast))
        end
      end

      context 'when the creator raises ActiveRecord::RecordInvalid' do
        let(:asciicast) { stub_model(Asciicast, errors: errors) }
        let(:errors) { double('errors', full_messages: full_messages) }
        let(:full_messages) { ['This is invalid'] }

        before do
          allow(creator).to receive(:create).
            with({ title: 'bar', user_agent: 'Smith' }, 'token', 'lol').
            and_raise(ActiveRecord::RecordInvalid.new(asciicast))
          post :create, asciicast: attributes
        end

        it 'returns the status 422' do
          expect(response.status).to eq(422)
        end

        it 'returns nothing as the content body' do
          expect(response.body).to be_blank
        end
      end
    end

  end
end
