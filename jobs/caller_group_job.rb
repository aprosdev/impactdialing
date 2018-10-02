require 'resque-loner'
require 'librato_resque'

##
# Update +Caller#campaign_id+ for +Caller+ records associated with the
# +CallerGroup+ identified by the given `caller_group_id`.
# Queued after save in +CallerGroup+.
#
# ### Metrics
#
# - completed
# - failed
# - timing
# - sql timing
#
# ### Monitoring
#
# Alert conditions:
#
# - 1 failure
#
class CallerGroupJob
  include Resque::Plugins::UniqueJob
  extend LibratoResque

  @loner_ttl = 150
  @queue = :dial_queue

  def self.perform(caller_group_id)
    caller_group = CallerGroup.find(caller_group_id)
    caller_group.reassign_in_background
  end
end
