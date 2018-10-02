require 'rails_helper'

describe Billing::Plans, :type => :model do
  let(:plans){ Billing::Plans.new }

  describe '#is_upgrade?(old_plan, new_plan)' do
    it 'returns true when old_plan is listed before new_plan in config' do
      truths = [
        plans.is_upgrade?('trial', 'basic'),
        plans.is_upgrade?('basic', 'pro'),
        plans.is_upgrade?('pro', 'business'),
        plans.is_upgrade?('business', 'per_minute'),
        plans.is_upgrade?('per_minute', 'enterprise')
      ]

      truths.each{|t| expect(t).to be_truthy}
    end

    it 'returns false when old_plan is listed after new_plan in config' do
      lies = [
        plans.is_upgrade?('business', 'pro'),
        plans.is_upgrade?('pro', 'basic'),
        plans.is_upgrade?('basic', 'trial'),
        plans.is_upgrade?('enterprise', 'per_minute'),
        plans.is_upgrade?('business', 'basic')
      ]

      lies.each{|l| expect(l).to be_falsey}
    end
  end

  describe '#buying_minutes?(plan, amount_paid)' do
    it 'returns true when plan == "per_minute" and amount_paid is greater than zero' do
      expect(plans.buying_minutes?('per_minute')).to be_truthy
      expect(plans.buying_minutes?('per_minute')).to be_truthy
      expect(plans.buying_minutes?('per_minute')).to be_truthy
    end

    it 'returns false otherwise' do
      expect(plans.buying_minutes?('basic')).to be_falsey
      expect(plans.buying_minutes?('pro')).to be_falsey
      expect(plans.buying_minutes?('enterprise')).to be_falsey
    end
  end

  describe '#recurring?(plan)' do
    it 'returns true when plan == basic' do
      expect(plans.recurring?('basic')).to be_truthy
    end
    it 'returns true when plan == pro' do
      expect(plans.recurring?('pro')).to be_truthy
    end
    it 'returns true when plan == business' do
      expect(plans.recurring?('business')).to be_truthy
    end
    it 'returns false when plan == per_minute' do
      expect(plans.recurring?('per_minute')).to be_falsey
    end
    it 'returns false when plan == enterprise' do
      expect(plans.recurring?('enterprise')).to be_falsey
    end
  end

  describe '#validate_transition!(old_plan, new_plan, minutes_available, opts)' do
    context 'raises InvalidPlanTransition when' do
      it 'transitioning to a recurring plan w/out a valid number of callers' do
        expect{
          plans.validate_transition!('basic', 'pro', false, {})
        }.to raise_error{ Billing::Plans::InvalidPlanTransition }
        expect{
          plans.validate_transition!('pro', 'business', false, {callers_allowed: -1})
        }.to raise_error{ Billing::Plans::InvalidPlanTransition }
        expect{
          plans.validate_transition!('pro', 'business', false, {callers_allowed: 0.5})
        }.to raise_error{ Billing::Plans::InvalidPlanTransition }
        expect{
          plans.validate_transition!('pro', 'business', false, {callers_allowed: 0})
        }.to raise_error{ Billing::Plans::InvalidPlanTransition }
      end
      it 'transitioning to a per minute plan from a recurring plan when minutes are available' do
        expect{
          plans.validate_transition!('pro', 'per_minute', true, {amount_paid: 3})
        }.to raise_error{ Billing::Plans::InvalidPlanTransition }
      end
      it 'transitioning to a per minute plan w/out a valid number of USD' do
        expect{
          plans.validate_transition!('business', 'per_minute', true, {amount_paid: 0.5})
        }.to raise_error{ Billing::Plans::InvalidPlanTransition }
        expect{
          plans.validate_transition!('per_minute', 'per_minute', true, {amount_paid: 0})
        }.to raise_error{ Billing::Plans::InvalidPlanTransition }
      end
    end

    context 'returns true when given valid arguments and' do
      it 'transitioning to a recurring plan from another recurring plan' do
        actual = plans.validate_transition!('trial', 'basic', true, {callers_allowed: 1})
        expect(actual).to be_truthy
      end
      it 'transitioning to a per minute plan from a recurring plan when NO minutes are available' do
        actual = plans.validate_transition!('pro', 'per_minute', false, {amount_paid: 3})
        expect(actual).to be_truthy
      end
      it 'transitioning to a recurring plan from a per minute plan' do
        actual = plans.validate_transition!('per_minute', 'pro', true, {callers_allowed: 2})
        expect(actual).to be_truthy
      end
      it 'adding callers to a recurring plan' do
        actual = plans.validate_transition!('basic', 'basic', true, {callers_allowed: 5})
        expect(actual).to be_truthy
      end
      it 'removing callers from a recurring plan' do
        actual = plans.validate_transition!('pro', 'pro', true, {callers_allowed: 3})
        expect(actual).to be_truthy
      end
      it 'adding minutes to a per minute plan' do
        actual = plans.validate_transition!('per_minute', 'per_minute', true, {amount_paid: 4})
        expect(actual).to be_truthy
      end
    end
  end

  describe '#find(plan_id)' do
    it 'returns an instance of Billing::Plans::Plan' do
      plan = plans.find('basic')
      expect(plan).to be_instance_of Billing::Plans::Plan
    end
    it 'loads plan config from @config' do
      ['basic', 'pro', 'business', 'per_minute'].each do |plan_id|
        plan = plans.find(plan_id)
        expect(plan.id).to eq plan_id
        expect(plan.minutes_per_quantity).to eq SUBSCRIPTION_PLANS[plan_id]['minutes_per_quantity']
        expect(plan.price_per_quantity).to eq SUBSCRIPTION_PLANS[plan_id]['price_per_quantity']
      end
    end
  end
end
