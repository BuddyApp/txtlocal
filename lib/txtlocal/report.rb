module Txtlocal
  class Report
    SENT_API_ENDPOINT = URI.parse("https://api.txtlocal.com/get_history_api/")
    RECEIVED_API_ENDPOINT = URI.parse("https://api.txtlocal.com/get_messages/?")

    def initialize(options={})
      options[:days] ||= 1
      sent_messages = Txtlocal::Report.fetch_for_days(options[:days], :sent)
      result = {:sent => sent_messages.size}
      if options[:inbox_id]
        received_messages = Txtlocal::Report.fetch_for_days(options[:days], :received, options[:inbox_id])
        result = result.merge({:received => received_messages.size})
      end
      result
    end

    def self.fetch_for_days(days, type, inbox_id=nil)
      from_timestamp = Time.now.to_i
      til_timestamp = (Date.today - days).to_time.to_i
      last_result = nil
      result = []
      while true
        current_result = case type
                         when :sent
                           fetch_sent_messages(from_timestamp, til_timestamp)
                         when :received
                           raise "Must supply inbox id" if inbox_id.nil?
                           fetch_received_messages(from_timestamp, til_timestamp, inbox_id)
                         else
                           raise "Incorrect type"
                         end
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

    def self.fetch_sent_messages(max_time, min_time)
      http = Net::HTTP.new(SENT_API_ENDPOINT.host, SENT_API_ENDPOINT.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Post.new(SENT_API_ENDPOINT.path)
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

    def self.fetch_received_messages(max_time, min_time, inbox_id)
      http = Net::HTTP.new(RECEIVED_API_ENDPOINT.host, RECEIVED_API_ENDPOINT.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Post.new(RECEIVED_API_ENDPOINT.path)
      req.set_form_data(:format => "json",
                        :max_time => max_time,
                        :min_time => min_time,
                        :limit => 1000, # Maximum limit
                        :sort_order => "asc",
                        :test => Txtlocal.config.testing? ? 1 : 0,
                        :username => Txtlocal.config.username,
                        :inbox_id => inbox_id,
                        :hash => Txtlocal.config.password)
      result = http.start { |http| http.request(req) }
      JSON.parse(result.body)["messages"]
    end
  end
end
