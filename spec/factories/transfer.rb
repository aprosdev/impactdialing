FactoryGirl.define do
  sequence(:transfer_type) do
    ['warm','cold'].sample
  end

  factory :bare_transfer, class: 'Transfer' do
    label          { Forgery(:basic).text }
    phone_number   { Forgery(:address).phone }
    transfer_type  { generate(:transfer_type) }
  end

  trait :warm do
    transfer_type 'warm'
  end

  trait :cold do
    transfer_type 'cold'
  end
end