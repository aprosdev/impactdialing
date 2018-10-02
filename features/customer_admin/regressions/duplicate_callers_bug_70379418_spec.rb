require 'rails_helper'

feature 'Caller Management', admin: true do
  let(:admin){ create(:user) }
  let(:account){ admin.account }
  let(:campaign){ create(:power, account: account, active: true) }

  let(:admin2){ create(:user) }
  let(:account2){ admin2.account }
  let(:campaign2){ create(:preview, account: account2, active: true)}

  def create_caller(username, campaign)
    visit '/client/callers'
    click_on 'Add new caller'
    fill_in 'Username (no spaces)', with: username
    fill_in 'Password', with: 'secret'
    select campaign.name, from: 'Campaign'
    click_on 'Save'
  end

  it 'can create callers and assign them to a campaign' do
    expect(account.campaigns).to include(campaign)
    web_login_as(admin)

    create_caller('someguy', campaign)

    expect(page).to have_content I18n.t('activerecord.successes.models.caller.saved')
    expect(page).to have_content 'Displaying 1 caller'
    expect(page).to have_content 'someguy'

    click_on 'Log out'
    web_login_as(admin2)
    create_caller('Someguy', campaign2)
    expect(page).not_to have_content I18n.t('activerecord.successes.models.caller.saved')
    expect(page).to have_content 'Username in use by another caller, it may have been archived'
  end
end
