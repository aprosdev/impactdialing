class Providers::Phone::Call::Params::Transfer
  attr_reader :transfer, :transfer_attempt, :lead_call, :type

  include Rails.application.routes.url_helpers

  def initialize(transfer, type, transfer_attempt, lead_call)
    @transfer         = transfer
    @transfer_attempt = transfer_attempt
    @lead_call        = lead_call
    @type             = type == :default ? :connect : type
  end

  def dial_timeout
    ENV['DIAL_TRANSFER_TIMEOUT'] || '15'
  end

  def from
    return lead_call.storage[:phone]
  end

  def to
    return transfer.phone_number
  end

  def params
    return {
      'StatusCallback' => end_url,
      'Timeout' => dial_timeout
    }
  end

  def url_options
    return Providers::Phone::Call::Params.default_url_options
  end

  def caller_url_options
    return callee_url_options.merge({
      caller_session: transfer_attempt.caller_session.id
    })
  end

  def callee_url_options
    return url_options.merge({
      session_key: transfer_attempt.session_key,
      transfer_type: transfer_attempt.transfer_type
    })
  end

  def call_sid
    method_name = "#{type}_call_sid"
    return send(method_name)
  end

  def default_call_sid
    caller_call_sid
  end

  def caller_call_sid
    transfer_attempt.caller_session.sid
  end

  def callee_call_sid
    lead_call.sid
  end

  def url
    method_name = "#{type}_url"
    return send(method_name)
  end

  def end_url
    return end_transfer_url(transfer_attempt, url_options)
  end

  def connect_url
    return connect_transfer_url(transfer_attempt, url_options)
  end

  def callee_url
    return callee_transfer_index_url(callee_url_options)
  end

  def caller_url
    return caller_transfer_index_url(caller_url_options)
  end

  def disconnect_url
    return disconnect_transfer_url(transfer_attempt, url_options)
  end
end
