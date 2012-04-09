require 'spec_helper'

describe Api::AsciicastsController do

  describe '#create' do

    let(:asciicast) { stub_model(Asciicast, :id => 666) }

    before do
      new = asciicast
      Asciicast.should_receive(:new).and_return(new)
    end

    context 'when save succeeds' do
      before do
        asciicast.stub(:save => true)
      end

      it 'enqueues snapshot capture' do
        SnapshotWorker.should_receive(:perform_async).with(asciicast.id)

        post :create
      end

      it 'returns status 201' do
        post :create

        response.status.should == 201
      end

      it 'returns URL of created asciicast as content body' do
        post :create

        response.body.should == asciicast_url(asciicast)
      end
    end

    context 'when save fails' do
      before do
        asciicast.stub(:save => false)
      end

      it 'returns status 422' do
        post :create

        response.status.should == 422
      end

      it 'returns full error messages as content body' do
        full_messages = double.to_s
        errors = double('errors', :full_messages => full_messages)
        asciicast.should_receive(:errors).and_return(errors)
        post :create

        response.body.should == full_messages
      end
    end

  end
end
