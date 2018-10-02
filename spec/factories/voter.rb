FactoryGirl.define do
  sequence :custom_id do |n|
    n
  end

  factory :bare_voter, class: 'Voter' do
    first_name { Forgery(:name).first_name }
    # phone { Forgery(:address).phone }
    updated_at Time.now
    enabled [:list]

    factory :voter do
      after(:build) do |voter|
        voter.account ||= create(:account)
        voter.campaign ||= create([:preview, :power, :predictive].sample, account: voter.account)
        campaign_account = {
          campaign: voter.campaign,
          account: voter.account
        }
        voter.household ||= create(:household, campaign_account)
        voter.voter_list ||= create(:voter_list, campaign_account)
      end
      last_name { Forgery(:name).last_name }
      email { Forgery(:email).address }
      address { Forgery(:address).street_address }
      city { Forgery(:address).city }
      state { Forgery(:address).state }
      zip_code { Forgery(:address).zip }
      country { Forgery(:address).country }
      enabled [:list]

      # tmp
      phone { Forgery(:address).phone.scan(/\d/).join }

      trait :ringing do
        status CallAttempt::Status::RINGING
        last_call_attempt_time { 30.seconds.ago }
      end

      trait :queued do
        status CallAttempt::Status::READY
        # last_call_attempt_time { Time.now }
      end

      trait :ready do
        status CallAttempt::Status::READY
      end

      trait :in_progress do
        status CallAttempt::Status::INPROGRESS
        last_call_attempt_time { 45.seconds.ago }
      end

      trait :failed do
        status CallAttempt::Status::FAILED
      end

      trait :disabled do
        enabled []
      end

      trait :deleted do
        active false
      end

      trait :blocked do
        enabled [:list, :blocked]
      end

      trait :busy do
        status CallAttempt::Status::BUSY
      end

      trait :abandoned do
        status CallAttempt::Status::ABANDONED
      end

      trait :no_answer do
        status CallAttempt::Status::NOANSWER
      end

      trait :hangup do
        status CallAttempt::Status::HANGUP
      end

      trait :voicemail do
        status CallAttempt::Status::VOICEMAIL
      end

      trait :success do
        status CallAttempt::Status::SUCCESS
      end

      trait :skipped do
        status Voter::Status::SKIPPED
        skipped_time 5.minutes.ago
      end

      trait :not_recently_skipped do
        status Voter::Status::SKIPPED
        skipped_time 25.hours.ago
      end

      trait :scheduled do
        status CallAttempt::Status::SCHEDULED
      end

      trait :scheduled_soon do
        :scheduled
        scheduled_date 1.minute.from_now
      end

      trait :scheduled_later do
        :scheduled
        scheduled_date 30.minutes.from_now
      end

      trait :high_priority do
        priority "1"
      end

      trait :recently_dialed do
        last_call_attempt_time { 5.minutes.ago }
      end

      trait :not_recently_dialed do
        last_call_attempt_time { 25.hours.ago }
      end

      trait :call_back do
        status CallAttempt::Status::SUCCESS
        call_back true
      end

      trait :retry do
        status Voter::Status::RETRY
      end

      trait :custom_id do
        custom_id { generate :custom_id }
      end

      factory :voter_with_custom_id, traits: [:custom_id]
      factory :abandoned_voter, traits: [:abandoned]
      factory :busy_voter, traits: [:busy]
      factory :no_answer_voter, traits: [:no_answer]
      factory :skipped_voter, traits: [:skipped]
      factory :hangup_voter, traits: [:hangup]
      factory :success_voter, traits: [:success]
      factory :ringing_voter, traits: [:ringing]
      factory :queued_voter, traits: [:queued]
      factory :failed_voter, traits: [:failed]
      factory :in_progress_voter, traits: [:in_progress]
      factory :disabled_voter, traits: [:disabled]
      factory :deleted_voter, traits: [:deleted]
    end
  end
end
