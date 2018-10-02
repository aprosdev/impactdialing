class ReportApiStrategy
  require 'net/http'

  def initialize(result, account_id, campaign_id, callback_url)
    @result       = result
    @account_id   = account_id
    @campaign_id  = campaign_id
    @callback_url = callback_url
  end

  def response(params)
    if @result == "success"
      link = AmazonS3.new.object("download_reports", "#{params[:campaign_name]}.csv").url_for(:read, :expires => 24.hours.to_i).to_s
    else
      link = ""
    end
    uri          = URI.parse(@callback_url)
    http         = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request      = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({message: @result, download_link: link, account_id: @account_id, campaign_id: @campaign_id})
    http.start do
      response = http.request(request)
      p "ReportApiStrategy CallbackResponseBody: #{@callback_url}: #{response.try(:body)}"
      Rails.logger.error("ReportApiStrategy CallbackResponseBody: #{@callback_url}: #{response.try(:body)}")
    end
  end
end
