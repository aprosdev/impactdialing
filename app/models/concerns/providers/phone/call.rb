module Providers::Phone::Call
  def self.service
    Providers::Phone::Twilio
  end

  def self.redirect(call_sid, url, opts={})
    retry_up_to = opts[:retry_up_to]
    info("Redirecting Call[#{call_sid}] to URL[#{url}]")
    resp = nil
    RescueRetryNotify.on(SocketError, retry_up_to) do
      resp = service.redirect(call_sid, url)
    end
    resp
  end

  def self.redirect_for(obj, type=:default)
    params = Params.for(obj, type)
    redirect(params.call_sid, params.url, Providers::Phone.default_options)
  end

  def self.make(from, to, url, params, opts={})
    retry_up_to = opts[:retry_up_to]
    info("Making From[#{from}] To[#{to}] using URL[#{url}] Params[#{params}]")
    RescueRetryNotify.on(SocketError, retry_up_to) do
      service.make(from, to, url, params)
    end
  end

  def self.make_for(obj, type=:default)
    params = Params.for(obj, type)
    make(params.from, params.to, params.url, params.params, Providers::Phone.default_options)
  end

  def self.play_message_for(call_sid)
    params = Providers::Phone::Call::Params::Call.new(call_sid)
    redirect(call_sid, params.url, Providers::Phone.default_options)
  end

  def self.info(msg)
    Rails.logger.info("[Providers::Phone::Call] #{msg}")
  end
end
