# todo: remove credit_card_declined attribute
class Account < ActiveRecord::Base
  TRIAL_MINUTES_ALLOWED   = 50
  TRIAL_NUMBER_OF_CALLERS = 5

  has_many :users
  has_many :campaigns, -> { where active: true }
  has_many :all_campaigns, :class_name => 'Campaign'
  has_many :recordings
  has_many :custom_voter_fields

  has_one :billing_subscription, class_name: 'Billing::Subscription'
  has_one :billing_credit_card, class_name: 'Billing::CreditCard'
  has_one :quota

  has_many :scripts
  has_many :callers
  has_many :voter_lists
  has_many :voters
  has_many :households
  has_many :blocked_numbers
  has_many :moderators
  has_many :questions, :through => :scripts
  has_many :script_texts, :through => :scripts
  has_many :notes, :through => :scripts
  has_many :possible_responses, :through => :scripts, :source => :questions
  has_many :caller_groups

  before_create :assign_api_key
  after_create :setup_trial!
  validate :check_subscription_type_for_call_recording, on: :update

  delegate :minutes_available?, to: :quota

  scope :search, -> (query) {
    includes(:users).where(search_email(query).or(search_account_id(query)))
  }

  scope :search_email, -> (query) {
    User.arel_table[:email].matches("%#{query}%")
  }

  scope :search_account_id, -> (query) {
    arel_table[:id].eq(query)
  }

private
  def ability
    Ability.new(self)
  end

public
  def setup_trial!
    create_quota!({
      minutes_allowed: TRIAL_MINUTES_ALLOWED,
      callers_allowed: TRIAL_NUMBER_OF_CALLERS
    })
    create_billing_subscription!({
      plan: 'trial'
    })
  end

  def billing_provider_customer_created!(provider_id)
    Rails.logger.debug 'StripeEvent: updating account provider ident with: ' + provider_id
    self.billing_provider_customer_id = provider_id
    self.billing_provider             = 'stripe'
    save!
  end

  def check_subscription_type_for_call_recording
    if record_calls && ability.cannot?(:record_calls, self)
      errors.add(:base, 'Your subscription does not allow call recordings.')
    end
  end

  def time_zone
    campaigns.active.first.try(:time_zone) || ActiveSupport::TimeZone.new('Pacific Time (US & Canada)')
  end

  def administrators
    users.select{|x| x.administrator? }
  end

  def update_caller_password(password)
    hash_caller_password(password)
    self.save
  end

  def hash_caller_password(password)
    self.caller_hashed_password_salt = SecureRandom.base64(8)
    self.caller_password = Digest::SHA2.hexdigest(caller_hashed_password_salt + password)
  end

  def self.authenticate_caller?(pin, password)
    caller = Caller.find_by_pin(pin)
    return nil if caller.nil?
    account = caller.account
    if password.nil? || account.caller_password.nil? || account.caller_hashed_password_salt.nil?
      return nil
    end
    if account.caller_password == Digest::SHA2.hexdigest(account.caller_hashed_password_salt + password)
      caller
    else
      nil
    end
  end

  def callers_in_progress
    caller_seats_taken
  end

  def _campaign_ids
    @_campaign_ids ||= Campaign.where(account_id: id).pluck('id').uniq
  end
  def caller_seats_taken
    return CallerSession.on_call_in_campaigns(_campaign_ids).count
  end

  def funds_available?
    ability.can?(:start_calling, Caller)
  end

  # Only when moving to Basic - legacy hacked enforcement of feature policies
  def to_basic!
    update_attributes!(record_calls: false)
    campaigns.by_type(Campaign::Type::PREDICTIVE).each do |campaign|
      campaign.update_attributes!(type: Campaign::Type::PREVIEW)
    end
    scripts.each do |script|
      script.transfers.each { |transfer| transfer.delete }
    end
  end

  # Only when moving to Pro - legacy hacked enforcement of feature policies
  def to_pro!
    update_attributes!(record_calls: false)
  end

  def enable_api!
    self.update_attribute(:api_key, generate_api_key)
  end

  def disable_api!
    self.update_attribute(:api_key, "")
  end

  def api_is_enabled?
    !api_key.empty?
  end

  def toggle_call_recording!
    self.record_calls = !self.record_calls
    self.save
  end

  def terms_and_services_accepted?
    !self.tos_accepted_date.nil?
  end

  def account_after_change_in_tos?
    self.created_at >= Date.parse('24th June 2013')
  end

  def custom_fields
    custom_voter_fields
  end

  def variable_abandonment?
    abandonment == 'variable'
  end

  def abandonment_value
    if variable_abandonment?
      "Variable"
    else
      "Fixed"
    end
  end

  def assign_api_key
    self.api_key = generate_api_key
  end

  def generate_api_key
    CallFlow.generate_token
  end
end

# ## Schema Information
#
# Table name: `accounts`
#
# ### Columns
#
# Name                                | Type               | Attributes
# ----------------------------------- | ------------------ | ---------------------------
# **`id`**                            | `integer`          | `not null, primary key`
# **`created_at`**                    | `datetime`         |
# **`updated_at`**                    | `datetime`         |
# **`domain_name`**                   | `string(255)`      |
# **`activated`**                     | `boolean`          | `default(FALSE)`
# **`record_calls`**                  | `boolean`          | `default(FALSE)`
# **`lock_version`**                  | `integer`          | `default(0)`
# **`status`**                        | `string(255)`      |
# **`abandonment`**                   | `string(255)`      |
# **`caller_password`**               | `text`             |
# **`caller_hashed_password_salt`**   | `text`             |
# **`api_key`**                       | `string(255)`      | `default("")`
# **`tos_accepted_date`**             | `datetime`         |
# **`billing_provider_customer_id`**  | `string(255)`      |
# **`billing_provider`**              | `string(255)`      |
#
