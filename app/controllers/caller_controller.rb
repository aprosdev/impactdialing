class CallerController < TwimlController
  include SidekiqEvents
  layout "caller"
  skip_before_filter :verify_authenticity_token, only: [ 
    :call_voter, :stop_calling, :token,
    :end_session, :skip_voter, :ready_to_call,
    :continue_conf, :pause, :run_out_of_numbers,
    :callin_choice, :read_instruction_options,
    :conference_started_phones_only_preview,
    :conference_started_phones_only_power,
    :conference_started_phones_only_predictive,
    :gather_response, :submit_response, :next_question,
    :next_call, :time_period_exceeded,
    :account_out_of_funds, :datacentre, :kick,
    :play_message_error
  ]

  before_filter :check_login, except: [
    :login, :end_session,
    :phones_only, :call_voter, :stop_calling,
    :ready_to_call, :continue_conf, :pause, :run_out_of_numbers,
    :callin_choice, :read_instruction_options,
    :conference_started_phones_only_preview,
    :conference_started_phones_only_power,
    :conference_started_phones_only_predictive,
    :gather_response, :submit_response, :next_question,
    :next_call, :time_period_exceeded,
    :account_out_of_funds, :datacentre, :kick,
    :play_message_error
  ]

  before_filter :find_caller_session, only: [
    :pause, :stop_calling, :ready_to_call,
    :continue_conf, :pause, :run_out_of_numbers,
    :callin_choice, :read_instruction_options,
    :conference_started_phones_only_preview,
    :conference_started_phones_only_power,
    :conference_started_phones_only_predictive,
    :gather_response, :submit_response, :next_question,
    :next_call, :time_period_exceeded,
    :account_out_of_funds
  ]

  before_filter :find_session, only: [:end_session]

  before_filter :abort_caller_if_unprocessable_fallback_url, only: [
    :continue_conf, :ready_to_call, :callin_choice,
    :gather_response, :submit_response, :next_question, :next_call,
    :conference_started_phones_only_preview,
    :conference_started_phones_only_power,
    :conference_started_phones_only_predictive
  ]

  if instrument_actions?
    instrument_action :login, :logout, :ready_to_call, :continue_conf, :pause, :stop_calling,
                      :run_out_of_numbers, :callin_choice, :read_instruction_options,
                      :conference_started_phones_only_preview,
                      :conference_started_phones_only_power,
                      :conference_started_phones_only_predictive,
                      :gather_response, :submit_response, :next_question,
                      :next_call, :time_period_exceeded, :account_out_of_funds, :skip_voter,
                      :end_session, :call_voter, :play_message_error
  end

private
  def current_ability
    @current_ability ||= Ability.new(@caller.account)
  end

  def abort_json
    if cannot?(:access_dialer, @caller)
      return({json: {message: I18n.t('dialer.access.denied')}, status: 403})
    end
    if cannot? :start_calling, @caller
      return({json: {message: I18n.t('dialer.account.not_funded')}, status: 402})
    end
    if @caller.campaign.time_period_exceeded?
      start_time = @caller.campaign.start_time.strftime('%l %p').strip
      end_time   = @caller.campaign.end_time.strftime('%l %p').strip
      return({
        json: {
          message: I18n.t('dialer.campaign.time_period_exceeded', {
            start_time: start_time,
            end_time: end_time
          })
        },
        status: 403
      })
    end

    {}
  end

  def caller_line_completed?
    params['CallStatus'] == 'completed'
  end

  def find_session
    @caller_session = CallerSession.find_by_sid_cached(params[:CallSid])
  end

  def find_caller_session
    @caller_session = CallerSession.find_by_id_cached(params[:session_id]) || CallerSession.find_by_sid_cached(params[:CallSid])
    optiions = {digit: params[:Digits], question_id: params[:question_id]}
    optiions.merge!(question_number: params[:question_number]) if params[:question_number]
    RedisCallerSession.set_request_params(@caller_session.id, optiions)
    @caller_session
  end
public

  def logout
    session[:caller]=nil
    redirect_to callveyor_login_path
  end

  def login
    redirect_to callveyor_path and return
  end

  def index
    redirect_to callveyor_path if @caller.campaign
  end

  def v1
    redirect_to callveyor_path and return
  end

  def ready_to_call
    # render abort 'dial' twiml here and 'start_calling' twiml at Callin#identify
    render_abort_twiml_unless_fit_to(:dial, @caller_session) do
      render xml: @caller_session.ready_to_call
    end
  end

  def continue_conf
    render_abort_twiml_unless_fit_to(:dial, @caller_session) do            
      render xml: @caller_session.continue_conf
    end
  end

  # This is the Dial:action for most caller TwiML
  # so expect Caller to hit here for >1 state changes
  def pause
    if abort_request? or caller_line_completed?
      # CallStatus == 'completed' ie caller is no longer on the phone
      @caller_session.end_session
      xml = Twilio::TwiML::Response.new{|response| response.Hangup}.text
      render xml: xml and return
    end
    # ^^ Work around; this url can be removed from some Dial:actions
    # todo: remove pause_url from unnecessary TwiML responses
    unless @caller_session.skip_pause?
      RedisStatus.set_state_changed_time(@caller_session.campaign_id, "Wrap up", @caller_session.id) if @caller_session.campaign.predictive?
      @caller_session.pushit('caller_wrapup_voice_hit', {})

      xml = Twilio::TwiML::Response.new do |r|
        r.Say("Please enter your call results.")
        r.Pause("length" => 600)
      end.text
    else
      xml = Twilio::TwiML::Response.new do |r|
        # Wait quietly for .5 seconds
        # while caller joins transfer conference.
        r.Play("digits" => "www")
      end.text
      @caller_session.skip_pause = false
    end
    render xml: xml
  end

  def run_out_of_numbers
    render xml: @caller_session.campaign_out_of_phone_numbers
  end

  def callin_choice
    render xml: @caller_session.callin_choice
  end

  def read_instruction_options
    render xml: @caller_session.read_choice(params)
  end

  def conference_started_phones_only_preview
    render xml: @caller_session.conference_started_phones_only_preview(params)
  end

  def conference_started_phones_only_power
    render xml: @caller_session.conference_started_phones_only_power(params)
  end

  def conference_started_phones_only_predictive
    render xml: @caller_session.conference_started_phones_only_predictive
  end

  def gather_response
    render xml: @caller_session.gather_response(params)
  end

  def submit_response
    render xml: @caller_session.submit_response(params)
  end

  def next_call
    render xml: @caller_session.next_call
  end

  def time_period_exceeded
    render xml: @caller_session.time_period_exceeded
  end

  def account_out_of_funds
    render xml: @caller_session.account_has_no_funds
  end

  def play_message_error
    msg = I18n.t('dialer.message_drop.failed')
    xml = Twilio::TwiML::Response.new do |r|
      r.Say(msg)
      r.Pause("length" => 600)
    end.text

    render xml: xml
  end

  # Used by Preview & Power dial modes to dial a number.
  def call_voter
    # try loading records from params to avoid queueing jobs for nonsense resources
    session = CallerSession.find_by_id_and_caller_id(params[:session_id], params[:id])

    CallerPusherJob.add_to_queue(session, 'publish_calling_voter')
    enqueue_call_flow(PreviewPowerDialJob, [session.id, params[:phone]])

    source = [
      "ac-#{session.campaign.account_id}",
      "ca-#{session.campaign_id}",
      "dm-#{session.campaign.type}",
      "cl-#{session.caller_id}",
      "cs-#{session.id}",
      "phone-#{params[:phone]}"
    ].join('.')
    ImpactPlatform::Metrics.count('dialer.call_voter', 1, source)

    render :nothing => true
  end

  def stop_calling
    @caller_session.stop_calling unless @caller_session.nil?
    render :nothing => true
  end

  def end_session
    unless @caller_session.nil?
      xml = @caller_session.conference_ended
    else
      xml = Twilio::TwiML::Response.new do |twiml|
        twiml.Hangup
      end.text
    end
    render xml: xml
  end

  def skip_voter
    caller_session = CallerSession.includes(:campaign).where(id: params[:session_id], caller_id: params[:id]).first

    if caller_session.fit_to_dial?
      info = caller_session.campaign.caller_conference_started_event
      render json: info[:data].to_json
    else
      enqueue_call_flow(RedirectCallerJob, [caller_session.id])
      render abort_json
    end
  end

  def check_login
    if session[:caller].blank?
      redirect_to caller_login_path
      return
    end
    begin
      @caller = Caller.find(session[:caller])
    rescue
      logout
    end
  end

  def kick
    logger.debug "DoublePause: Caller#kick #{params[:participant_type]}"
    check_login
    @caller_session = @caller.caller_sessions.find(params[:caller_session_id])
    transfer_attempt = @caller_session.transfer_attempts.last
    participant_type = params[:participant_type]
    
    case participant_type
    when 'transfer'
      Providers::Phone::Conference.kick(transfer_attempt, {retry_up_to: ENV["TWILIO_RETRIES"]})
    when 'caller'
      Providers::Phone::Conference.kick(@caller_session, {retry_up_to: ENV["TWILIO_RETRIES"]})
      @caller_session.skip_pause = false
      # this redirect is only necessary in order to update the Call
      # and trigger the Dial:action from the caller conference twiml
      # in transfers#caller
      Providers::Phone::Call.redirect_for(@caller_session, :pause)
      @caller_session.pushit('caller_kicked_off', {})
    end
    render nothing: true
  end
end
