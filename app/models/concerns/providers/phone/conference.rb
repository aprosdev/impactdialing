module Providers::Phone::Conference
  def self.service
    Providers::Phone::Twilio
  end

  def self.by_name(name, opts={})
    response = list({friendly_name: name}, Providers::Phone.options(opts))
    return response.resource.first
  end

  def self.sid_for(name, opts={})
    conference = by_name(name, Providers::Phone.options(opts))
    return conference.sid
  end

  def self.toggle_mute_for(name, call_sid, opts={})
    conference_sid = sid_for(name)
    if opts[:mute]
      return mute(conference_sid, call_sid, Providers::Phone.options(opts))
    else
      return unmute(conference_sid, call_sid, Providers::Phone.options(opts))
    end
  end

  def self.call(method, *args)
    opts = args.pop
    retry_up_to = opts[:retry_up_to]
    response = nil
    RescueRetryNotify.on(SocketError, retry_up_to) do
      response = service.send(method, *args)
    end
    return response
  end

  def self.mute(conference_sid, call_sid, opts={})
    return call(:mute_participant, conference_sid, call_sid, opts)
  end

  def self.unmute(conference_sid, call_sid, opts={})
    return call(:unmute_participant, conference_sid, call_sid, opts)
  end

  def self.list(search_options={}, opts={})
    return call(:conference_list, search_options, opts)
  end

  def self.kick(participant, opts={})
    conference_sid  = sid_for(participant.session_key)
    call_sid        = participant.sid
    return call(:kick, conference_sid, call_sid, opts)
  end
end
