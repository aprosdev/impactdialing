require 'rails_helper'

describe Monitors::CallersController, :type => :controller do
  let(:account){ create(:account) }
  let(:admin){ create(:user, account: account) }
  let(:campaign){ create(:power, {account: account}) }
  let(:caller){ create(:caller, campaign: campaign) }

  before do
    webmock_disable_net!
    login_as(admin)
  end

  describe '#switch_mode, params: session_id, monitor_session_id, type' do
    let(:caller_session){ create(:webui_caller_session, {caller: caller}) }
    let(:conference_sid){ 'CFww834eJSKDJFjs328JF92JSDFwe' }
    let(:call_sid){ caller_session.sid }
    let(:conference_name){ caller_session.session_key }
    let(:moderator) do
      create(:moderator, {
        call_sid: call_sid,
        caller_session: caller_session
      })
    end
    let(:valid_params) do
      {
        session_id: caller_session.id,
        monitor_session_id: moderator.id,
        type: 'eavesdrop'
      }
    end

    before do
      stub_twilio_conference_by_name_request
      stub_twilio_mute_participant_request
      stub_twilio_unmute_participant_request
    end

    it 'should be a success w/ valid params' do
      put :switch_mode, valid_params
      expect(response).to be_success
    end

    it 'loads CallerSession' do
      expect(CallerSession).to receive(:find).at_least(:once){ caller_session }
      put :switch_mode, valid_params
    end
    it 'loads Moderator' do
      expect(Moderator).to receive(:find){ moderator }
      put :switch_mode, valid_params
    end
    it 'updates Moderator#caller_session_id' do
      put :switch_mode, valid_params
      moderator.reload
      expect(moderator.caller_session_id).to eq caller_session.id
    end
    it 'requests the conference_id for CallerSession' do
      put :switch_mode, valid_params
      expect(@conf_by_name_request).to have_been_made
    end
    it 'renders not connected message if caller is not on a call' do
      put :switch_mode, valid_params
      expect(response.body).to eq "Status: Caller is not connected to a lead."
    end

    context 'a caller is on a call' do
      before do
        allow(caller_session).to receive(:connected_to_lead?){ true }
        allow(CallerSession).to receive(:find).with(valid_params[:session_id].to_s){ caller_session }
      end
      it 'renders a message with monitoring type and caller identity info when caller is on a call' do
        put :switch_mode, valid_params
        expect(response.body).to eq "Status: Monitoring in eavesdrop mode on #{caller_session.caller.identity_name}."
      end
      it 'when params[:type] != "breakin" it adds muted moderator' do
        put :switch_mode, valid_params
        expect(@mute_participant_request).to have_been_made
        expect(@unmute_participant_request).not_to have_been_made
      end
      it 'when params[:type] == "breakin" it adds unmuted moderator' do
        put :switch_mode, valid_params.merge({type: 'breakin'})
        expect(@unmute_participant_request).to have_been_made
        expect(@mute_participant_request).not_to have_been_made
      end
    end
  end
end

