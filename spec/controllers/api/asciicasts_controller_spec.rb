require 'spec_helper'

describe Api::AsciicastsController do

  describe '#create' do
    let(:creator) { double('creator') }
    let(:attributes) { { 'foo' => 'bar' } }

    before do
      allow(AsciicastCreator).to receive(:new).with(no_args()) { creator }
    end

    context 'when the creator returns an asciicast' do
      let(:asciicast) { stub_model(Asciicast, :id => 666) }

      before do
        allow(creator).to receive(:create).
          with(attributes, kind_of(ActionDispatch::Http::Headers)) { asciicast }
        post :create, :asciicast => attributes
      end

      it 'returns the status 201' do
        expect(response.status).to eq(201)
      end

      it 'returns the URL of created asciicast as the content body' do
        expect(response.body).to eq(asciicast_url(asciicast))
      end
    end

    context 'when the creator raises ActiveRecord::RecordInvalid' do
      let(:asciicast) { stub_model(Asciicast, :errors => errors) }
      let(:errors) { double('errors', :full_messages => full_messages) }
      let(:full_messages) { ['This is invalid'] }

      before do
        allow(creator).to receive(:create).
          with(attributes, kind_of(ActionDispatch::Http::Headers)).
          and_raise(ActiveRecord::RecordInvalid.new(asciicast))
        post :create, :asciicast => attributes
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
