require 'rails_helper'

describe TimeZoneHelper, :type => :helper do

  describe "set_date_range" do
    it "should raise exception if date not in correct format" do
      campaign = create(:campaign)
      expect { helper.set_date_range(campaign, "", "") }.to raise_error(InvalidDateException)
    end

    it "should format fromdate and to date if present" do
      campaign = create(:campaign, time_zone: "Eastern Time (US & Canada)")
      expect(helper.set_date_range(campaign, "08/08/2012", "08/09/2012").to_s).to eq([Time.parse("2012-08-08 04:00:00 UTC"), Time.parse("2012-08-10 03:59:59 UTC")].to_s)
    end

    it "should format campaigns first and last attempt if from and to not present" do
      campaign = create(:campaign, time_zone: "Eastern Time (US & Canada)")
      call_attempt1 = create(:call_attempt, campaign: campaign, created_at: "2012-08-08 10:00:00 UTC")
      call_attempt2 = create(:call_attempt, campaign: campaign, created_at: "2012-08-11 09:00:00 UTC")
      expect(helper.set_date_range(campaign, nil, nil).to_s).to eq([Time.parse("2012-08-08 04:00:00 UTC"), Time.parse("2012-08-12 03:59:59 UTC")].to_s)
    end
  end

  describe "set_date_range_account" do
    it "should raise exception if date not in correct format" do
      account = create(:account)
      expect { helper.set_date_range_account(account, "abc", "abc") }.to raise_error(InvalidDateException)
    end

    it "should format fromdate and to date if present" do
      account = create(:account)
      expect(helper.set_date_range_account(account, "08/08/2012", "08/09/2012").to_s).to eq([Time.parse("2012-08-08 00:00:00 UTC"), Time.parse("2012-08-09 23:59:59 UTC")].to_s)
    end

    it "should format accounts created date if no date present " do
      campaign = create(:account, created_at: "2012-08-01 10:00:00 UTC")
      expect(helper.set_date_range_account(campaign, nil, nil)[0].to_s).to eq(Time.parse("2012-08-01 00:00:00 UTC").to_s)
    end
  end

  describe "set_date_range_callers" do
    it "should raise exception if date not in correct format" do
      campaign = create(:campaign)
      expect { helper.set_date_range_callers(campaign, nil, "abc", "abc") }.to raise_error(InvalidDateException)
    end

    it "should format fromdate and to date if present" do
      campaign = create(:campaign, time_zone: "Eastern Time (US & Canada)")
      expect(helper.set_date_range_callers(campaign, nil, "08/08/2012", "08/09/2012").to_s).to eq([Time.parse("2012-08-08 04:00:00 UTC"), Time.parse("2012-08-10 03:59:59 UTC")].to_s)
    end

    xit "should format accounts created date if no date present " do
      campaign = create(:account, created_at: "2012-08-01 10:00:00 UTC")
      expect(helper.set_date_range_account(campaign, nil, nil)[0].to_s).to eq(Time.parse("2012-08-01 07:00:00 UTC").to_s)
    end
  end
end
