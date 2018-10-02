require 'rails_helper'
require 'cancan/matchers'

describe Ability, :type => :model do
  let(:account){ create(:account) }
  let(:subscription){ account.billing_subscription }
  let(:quota){ account.quota }

  def subscribe(plan, status='active')
    subscription.plan = plan
    unless plan == 'trial'
      # mimic reality, where trial subs have no provider_status
      subscription.provider_status = status
    end
    subscription.save!
  end

  def toggle_calling(flag)
    quota.disable_calling = (flag == :off)
    quota.save!
  end

  def take_all_seats
    allow(CallerSession).to receive_message_chain(:on_call_in_campaigns, :count){ quota.callers_allowed + 1 }
  end

  def set_minutes_allowed(n)
    quota.minutes_allowed = n
    quota.save!
  end

  def use_all_minutes
    quota.minutes_used = quota.minutes_allowed
    quota.save!
  end

  def set_seats(n)
    quota.callers_allowed = n
    quota.save!
  end

  context 'plan permissions' do
    context 'account.billing_provider_customer_id is present' do
      before do
        account.billing_provider_customer_id = 'cus_abc123'
        account.save!
      end
      let(:ability){ Ability.new(account) }
      it 'can make payment' do
        expect(ability).to be_able_to :make_payment, subscription
      end
      it 'can change plans' do
        expect(ability).to be_able_to :change_plans, subscription
      end
      context 'plan is per minute' do
        before do
          subscribe 'per_minute'
        end
        let(:ability){ Ability.new(account) }
        it 'can add minutes' do
          expect(ability).to be_able_to :add_minutes, subscription
        end
      end
      context 'plan is not per minute' do
        it 'cannot add minutes' do
          ['trial', 'basic', 'pro', 'business'].each do |id|
            subscribe id
            ability = Ability.new(account)
            expect(ability).not_to be_able_to :add_minutes, subscription
          end
        end
      end
    end
    context 'account.billing_provider_customer_id is not present' do
      let(:ability){ Ability.new(account) }

      it 'cannot make payment' do
        expect(ability).not_to be_able_to :make_payment, subscription
      end
      it 'cannot change plans' do
        expect(ability).not_to be_able_to :change_plans, subscription
      end
      it 'cannot add minutes' do
        expect(ability).not_to be_able_to :add_minutes, subscription
      end
    end
    context 'plan is not trial and plan is not per minute and plan is not enterprise' do
      it 'can cancel subscription' do
        ['basic', 'pro', 'business'].each do |id|
          subscribe id
          ability = Ability.new(account)
          expect(ability).to be_able_to :cancel_subscription, subscription
        end
      end
    end
    context 'plan is trial, per minute or enterprise' do
      it 'cannot cancel subscription' do
        ['trial', 'per_minute', 'enterprise'].each do |id|
          subscribe id
          ability = Ability.new(account)
          expect(ability).not_to be_able_to :cancel_subscription, subscription
        end
      end
    end
  end

  context 'quota permissions' do
    shared_examples_for 'dialer access denied' do
      let(:ability){ Ability.new(account) }
      it 'cannot start calling' do
        expect(ability).not_to be_able_to :start_calling, Caller
      end
      it 'cannot access dialer' do
        expect(ability).not_to be_able_to :access_dialer, Caller
      end
      it 'cannot take seat' do
        expect(ability).not_to be_able_to :take_seat, Caller
      end
    end
    shared_examples_for 'dialer access granted' do
      let(:ability){ Ability.new(account) }
      it 'can access dialer' do
        expect(ability).to be_able_to :access_dialer, Caller
      end
    end
    # acct is funded if minutes are available
    shared_examples_for 'account is funded' do
      let(:ability){ Ability.new(account) }
      it 'can access dialer' do
        expect(ability).to be_able_to :start_calling, Caller
      end
    end
    shared_examples_for 'account is not funded' do
      let(:ability){ Ability.new(account) }
      it 'can access dialer' do
        expect(ability).not_to be_able_to :start_calling, Caller
      end
    end
    shared_examples_for 'caller seats available' do
      let(:ability){ Ability.new(account) }
      it 'can take a seat' do
        expect(ability).to be_able_to :take_seat, Caller
      end
    end
    shared_examples_for 'no caller seats available' do
      let(:ability){ Ability.new(account) }
      it 'cannot take a seat' do
        expect(ability).not_to be_able_to :take_seat, Caller
      end
    end
    context 'enterprise' do
      before do
        subscribe 'enterprise'
      end
      it_behaves_like 'dialer access granted'
      it_behaves_like 'account is funded'
      it_behaves_like 'caller seats available'
      context 'calling is disabled' do
        before do
          toggle_calling :off
        end
        it_behaves_like 'dialer access denied'
      end
    end
    context 'per minute' do
      before do
        subscribe 'per_minute'
      end
      context 'minutes are available, subscription is active and calling is enabled' do
        before do
          set_minutes_allowed 100
          toggle_calling :on
        end
        it_behaves_like 'dialer access granted'
        it_behaves_like 'account is funded'
        it_behaves_like 'caller seats available'
      end
      context 'no minutes available or subscription is not active or calling is disabled' do
        context 'no minutes' do
          before do
            use_all_minutes
          end
          it_behaves_like 'account is not funded'
        end
        context 'calling is disabled' do
          before do
            toggle_calling :off
          end
          it_behaves_like 'dialer access denied'
        end
      end
    end
    ['business', 'pro', 'basic', 'trial'].each do |plan_id|
      context "#{plan_id}" do
        before do
          subscribe plan_id
        end
        context 'calling is disabled' do
          before do
            toggle_calling :off
          end
          it_behaves_like 'dialer access denied'
        end
        context 'caller seats and minutes are available and subscription is active' do
          it_behaves_like 'dialer access granted'
          it_behaves_like 'account is funded'
          it_behaves_like 'caller seats available'
        end
        context 'no seats available' do
          before do
            take_all_seats
          end
          it_behaves_like 'no caller seats available'
        end
        context 'no minutes available' do
          before do
            use_all_minutes
          end
          it_behaves_like 'account is not funded'
        end
        unless plan_id == 'trial'
          context 'subscription is not active' do
            before do
              subscribe plan_id, 'unpaid'
            end
            it_behaves_like 'account is not funded'
          end
        end
      end
    end
  end

  context 'feature permissions' do
    ['enterprise', 'per_minute', 'business', 'trial'].each do |plan_id|
      context "#{plan_id}" do
        before do
          subscribe plan_id
        end
        let(:ability){ Ability.new(account) }

        it 'can add transfers' do
          expect(ability).to be_able_to :add_transfer, Script
        end
        it 'can manager caller groups' do
          expect(ability).to be_able_to :manage, CallerGroup
        end
        it 'can view campaign reports' do
          expect(ability).to be_able_to :view_reports, Account
        end
        it 'can view caller reports' do
          expect(ability).to be_able_to :view_reports, Account
        end
        it 'can view dashboard' do
          expect(ability).to be_able_to :view_dashboard, Account
        end
        it 'can record calls' do
          expect(ability).to be_able_to :record_calls, Account
        end
        it 'can manage Preview, Power and Predictive campaigns' do
          expect(ability).to be_able_to :manage, Preview
          expect(ability).to be_able_to :manage, Power
          expect(ability).to be_able_to :manage, Predictive
        end
      end
    end
    context 'pro' do
      before do
        subscribe 'pro'
      end
      let(:ability){ Ability.new(account) }
      it 'can add transfers' do
        expect(ability).to be_able_to :add_transfer, Script
      end
      it 'can manager caller groups' do
        expect(ability).to be_able_to :manage, CallerGroup
      end
      it 'can view campaign reports' do
        expect(ability).to be_able_to :view_reports, Account
      end
      it 'can view caller reports' do
        expect(ability).to be_able_to :view_reports, Account
      end
      it 'can view dashboard' do
        expect(ability).to be_able_to :view_dashboard, Account
      end
      it 'cannot record calls' do
        expect(ability).not_to be_able_to :record_calls, Account
      end
      it 'can manage Preview, Power and Predictive campaigns' do
        expect(ability).to be_able_to :manage, Preview
        expect(ability).to be_able_to :manage, Power
        expect(ability).to be_able_to :manage, Predictive
      end
    end
    context 'basic' do
      before do
        subscribe 'basic'
      end
      let(:ability){ Ability.new(account) }
      it 'cannot add transfers' do
        expect(ability).not_to be_able_to :add_transfer, Script
      end
      it 'can manage caller groups' do
        expect(ability).to be_able_to :manage, CallerGroup
      end
      it 'can view campaign reports' do
        expect(ability).to be_able_to :view_reports, Account
      end
      it 'can view caller reports' do
        expect(ability).to be_able_to :view_reports, Account
      end
      it 'cannot view dashboard' do
        expect(ability).not_to be_able_to :view_dashboard, Account
      end
      it 'cannot record calls' do
        expect(ability).not_to be_able_to :record_calls, Account
      end
      it 'can manage Preview and Power campaigns' do
        expect(ability).to be_able_to :manage, Preview
        expect(ability).to be_able_to :manage, Power
      end
      it 'cannot manage Predictive campaigns' do
        expect(ability).not_to be_able_to :manage, Predictive
      end
    end
  end
end
