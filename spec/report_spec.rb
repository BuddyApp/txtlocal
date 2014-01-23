require File.join(File.dirname(__FILE__), 'spec_helper')

describe Txtlocal::Report do
  context "without api" do
    it "should call the fetch_for_days method once if inbox_id is not supplied" do
      Txtlocal::Report.should_receive(:fetch_for_days).exactly(1).times.and_return([])
      Txtlocal::Report.new
    end

    it "should call the fetch_for_days method once if inbox_id is not supplied" do
      Txtlocal::Report.should_receive(:fetch_for_days).exactly(2).times.and_return([])
      Txtlocal::Report.new(:inbox_id => 123)
    end

    describe "fetch_for_days" do
      it "should call the fetch_sent_messages method when looking for sent messages" do
        Txtlocal::Report.should_receive(:fetch_sent_messages).exactly(1).times.and_return([])
        Txtlocal::Report.fetch_for_days(1, :sent)
      end

      it "should call the fetch_received_messages method" do
        Txtlocal::Report.should_receive(:fetch_received_messages).exactly(1).times.and_return([])
        Txtlocal::Report.fetch_for_days(1, :received, 123)
      end

      it "should call the fetch method twice if fetch returns something" do
        now = Time.now
        day_ago = Chronic.parse("1 day ago").to_date.to_time.to_i
        three_hours_ago = Chronic.parse("3 hours ago")
        Txtlocal::Report.should_receive(:fetch_sent_messages).with(now.to_i, day_ago.to_i).exactly(1).times.and_return([{"datetime" => three_hours_ago.to_s}])
        Txtlocal::Report.should_receive(:fetch_sent_messages).with(now.to_i, three_hours_ago.to_i).exactly(1).times.and_return([])
        Txtlocal::Report.should_receive(:fetch_received_messages).with(now.to_i, day_ago.to_i, 123).exactly(1).times.and_return([{"datetime" => three_hours_ago.to_s}])
        Txtlocal::Report.should_receive(:fetch_received_messages).with(now.to_i, three_hours_ago.to_i, 123).exactly(1).times.and_return([])

        Txtlocal::Report.new(:days => 1, :inbox_id => 123)
      end

    end

  end


  context "api test mode" do
    before(:each) do
      @yaml = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'api_login.yml'))
      WebMock.allow_net_connect!
      Txtlocal.config do |c|
        c.from = "testing"
        c.username = @yaml["api_username"]
        c.password = @yaml["api_password"]
        c.test = true
      end
    end

    it "should combine records over a period of time when given no days" do
      Txtlocal::Report.fetch_for_days(0, :sent)
      Txtlocal::Report.fetch_for_days(0, :received, @yaml["received_inbox_id"])
    end

    it "should fetch sent records when given a max time and min time" do
      Txtlocal::Report.fetch_sent_messages(Time.now.to_i, Chronic.parse("1 day ago").to_i)
    end

    it "should fetch received records when given a max time and min time" do
      Txtlocal::Report.fetch_received_messages(Time.now.to_i, Chronic.parse("1 day ago").to_i, @yaml['received_inbox_id'])
    end

    it "should receive data from the api endpoint" do
      Txtlocal::Report.new(:inbox_id => @yaml['received_inbox_id'])
    end
  end
end
