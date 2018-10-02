require 'librato_resque'

##
# Email password reset to customer.
#
# ### Metrics
#
# - completed
# - failed
# - timing
#
# ### Monitoring
#
# Alert conditions:
#
# - 1 failure
#
class ResetPasswordEmailJob
  extend LibratoResque

  @queue = :general
  
  def self.perform(user_id)
    user = User.find(user_id)
    user_mailer = UserMailer.new
    user_mailer.reset_password(user)
  end
end