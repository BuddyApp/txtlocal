module Txtlocal
  class Report
    API_ENDPOINT = URI.parse("https://api.txtlocal.com/get_history_api/")

    def initialize(options={})
      options[:days] ||= 1
      res = Txtlocal::Report.fetch_for_days(options[:days])
      return res.size
    end

    def self.fetch_for_days(days)
      from_timestamp = Time.now.to_i
      til_timestamp = (Date.today - days).to_time.to_i
      last_result = nil
      result = []
      while true
        current_result = fetch(from_timestamp, til_timestamp)
        if current_result.nil? || current_result.empty?
          break
        else
          end_result = current_result[-1]
          til_timestamp = Chronic.parse(end_result["datetime"]).to_i
          break if end_result == last_result
          last_result = end_result
          result += current_result
        end
      end
      result
    end

    def self.fetch(max_time, min_time)
      http = Net::HTTP.new(API_ENDPOINT.host, API_ENDPOINT.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Post.new(API_ENDPOINT.path)
      req.set_form_data(:format => "json",
                        :max_time => max_time,
                        :min_time => min_time,
                        :limit => 1000, # Maximum limit
                        :sort_order => "asc",
                        :test => Txtlocal.config.testing? ? 1 : 0,
                        :username => Txtlocal.config.username,
                        :hash => Txtlocal.config.password)
      result = http.start { |http| http.request(req) }
      JSON.parse(result.body)["messages"]
    end

  end
end
