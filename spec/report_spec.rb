require File.join(File.dirname(__FILE__), 'spec_helper')

describe Txtlocal::Report do
  context "without api" do
    it "should call the fetch_for_days method" do
      Txtlocal::Report.should_receive(:fetch_for_days).exactly(1).times.and_return([])
      Txtlocal::Report.new
    end

    it "fetch_for_days should call the fetch method" do
      Txtlocal::Report.should_receive(:fetch).exactly(1).times.and_return([])
      Txtlocal::Report.fetch_for_days(1)
    end

    it "should call the fetch method twice if fetch returns something" do
      now = Time.now
      day_ago = Chronic.parse("1 day ago").to_date.to_time.to_i
      three_hours_ago = Chronic.parse("3 hours ago")
      Txtlocal::Report.should_receive(:fetch).with(now.to_i, day_ago.to_i).exactly(1).times.and_return([{"datetime" => three_hours_ago.to_s}])
      Txtlocal::Report.should_receive(:fetch).with(now.to_i, three_hours_ago.to_i).exactly(1).times.and_return([])
      Txtlocal::Report.fetch_for_days(1)
    end
  end


  context "api test mode" do
    before(:each) do
      yaml = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'api_login.yml'))
      WebMock.allow_net_connect!
      Txtlocal.config do |c|
        c.from = "testing"
        c.username = yaml["api_username"]
        c.password = yaml["api_password"]
        c.test = true
      end
    end

    it "should combine records over a period of time when given multiple days" do
      Txtlocal::Report.fetch_for_days(3)
    end

    it "should fetch records when given a max time and min time" do
      Txtlocal::Report.fetch(Time.now.to_i, Chronic.parse("1 day ago").to_i)
    end

    it "should receive data from the api endpoint" do
      Txtlocal::Report.new
    end
  end
end
