require 'net/http'
require 'uri'
require 'cgi'
require 'rubygems'
require 'json'
require 'digest/md5'
require 'mandrill'

# More details @ https://mandrillapp.com/api/docs/messages.ruby.html

module Mandrill

  API_KEY = GlobalConstant::MANDRILL_API_KEY

  def initialize(api_key =nil)
    @api_key = api_key || API_KEY
    @mandrill = Mandrill::API.new @api_key

  end


  #def call_api(api_call, api_params={})
  #  begin
  #    Timeout::timeout(100) do
  #      response = SOAP_CLIENT.call(api_call.to_sym, :message => {api_key: @api_key}.merge(api_params))
  #      return {success:true, response:response, exception:''}
  #    end
  #  rescue Exception => e
  #    puts "Something went wrong, Please check. #{e.inspect}"
  #  end
  #end

  #TEST MAIL CONTENT SENT
  #{
  #    "key": "mtFYiSZ4xFJbbLXD7pt20Q",
  #    "message": {
  #    "html": "<p>Example HTML content</p>",
  #    "text": "This is through API Call.",
  #    "subject": "API CAll email",
  #    "from_email": "shaadimadeeasy.com@gmail.com",
  #    "from_name": "ShaadiMadeEasy",
  #    "to": [
  #    {
  #        "email": "er.arnav.87@gmail.com",
  #    "name": "Arnav Agarwal",
  #    "type": "to"
  #}
  #],
  #    "headers": {
  #    "Reply-To": "shaadimadeeasy.com@gmail.com"
  #},
  #    "important": false,
  #"track_opens": null,
  #"track_clicks": null,
  #"auto_text": null,
  #"auto_html": null,
  #"inline_css": null,
  #"url_strip_qs": null,
  #"preserve_recipients": null,
  #"view_content_link": null,
  #"bcc_address": "",
  #    "tracking_domain": null,
  #"signing_domain": null,
  #"return_path_domain": null,
  #"merge": true,
  #"global_merge_vars": [
  #    {
  #        "name": "merge1",
  #    "content": "merge1 content"
  #}
  #],
  #    "merge_vars": [
  #    {
  #        "rcpt": "er.arnav.87@gmail.com",
  #    "vars": [
  #    {
  #        "name": "merge2",
  #    "content": "merge2 content"
  #}
  #]
  #}
  #],
  #    "tags": [
  #    "password-resets"
  #],
  #    "subaccount": "customer-123",
  #    "google_analytics_domains": [
  #    "example.com"
  #],
  #    "google_analytics_campaign": "shaadimadeeasy.com@gmail.com",
  #    "metadata": {
  #    "website": "www.example.com"
  #},
  #    "recipient_metadata": [
  #    {
  #        "rcpt": "er.arnav.87@gmail.com",
  #    "values": {
  #    "user_id": 123456
  #}
  #}
  #]
  #},
  #    "async": false,
  #"ip_pool": "Main Pool"
  #}


  def send_email(params)
    begin
      message = {"text"=>"Example text content",
                 "google_analytics_campaign"=>"message.from_email@example.com",
                 "images"=>
                     [{"type"=>"image/png", "content"=>"ZXhhbXBsZSBmaWxl", "name"=>"IMAGECID"}],
                 "subaccount"=>"customer-123",
                 "view_content_link"=>nil,
                 "html"=>"<p>Example HTML content</p>",
                 "metadata"=>{"website"=>"www.shaadimadeeasy.com"},
                 "merge"=>true,
                 "global_merge_vars"=>[{"content"=>"merge1 content", "name"=>"merge1"}],
                 "url_strip_qs"=>nil,
                 "headers"=>{"Reply-To"=>"contactus@shaadimadeeasy.com"},
                 "auto_text"=>nil,
                 "track_clicks"=>nil,
                 "to"=>
                     [{"type"=>"to",
                       "email"=>params[:recipient],
                       "name"=>params[:recipient_name]}],
                 "from_email"=>params[:sender_email],
                 "attachments"=>
                     [{"type"=>"text/plain",
                       "content"=>"ZXhhbXBsZSBmaWxl",
                       "name"=>"myfile.txt"}],
                 "google_analytics_domains"=>["example.com"],
                 "merge_vars"=>
                     [{"rcpt"=>"recipient.email@example.com",
                       "vars"=>[{"content"=>"merge2 content", "name"=>"merge2"}]}],
                 "return_path_domain"=>nil,
                 "signing_domain"=>nil,
                 "auto_html"=>nil,
                 "recipient_metadata"=>
                     [{"rcpt"=>"recipient.email@example.com", "values"=>{"user_id"=>123456}}],
                 "tracking_domain"=>nil,
                 "bcc_address"=>"message.bcc_address@example.com",
                 "inline_css"=>nil,
                 "important"=>false,
                 "from_name"=>"Example Name",
                 "tags"=>["password-resets"],
                 "preserve_recipients"=>nil,
                 "track_opens"=>nil,
                 "subject"=>"example subject"}
      async = false
      ip_pool = "Main Pool"
      #send_at = "example send_at"   #TODO: Need paid account for this, means for scheduling.
      result = @mandrill.messages.send message, async, ip_pool, send_at
        # [{"_id"=>"abc123abc123abc123abc123abc123",
        #     "reject_reason"=>"hard-bounce",
        #     "status"=>"sent",
        #     "email"=>"recipient.email@example.com"}]

    rescue Mandrill::Error => e
      # Mandrill errors are thrown as exceptions
      puts "A mandrill error occurred: #{e.class} - #{e.message}"
      # A mandrill error occurred: Mandrill::UnknownSubaccountError - No subaccount exists with the id 'customer-123'
      raise
    end
  end



  # Search the content of recently sent messages and return the aggregated hourly stats for matching messages
  #
  def search_time_series(params)
    begin
      
      query = "email:gmail.com"
      date_from = params[:from_date]#"2013-01-01"
      date_to = params[:to_date]#"2013-01-02"
      tags = params[:tags]#["password-reset", "welcome"]
      senders = params[:senders]#["sender@example.com"]
      result = @mandrill.messages.search_time_series query, date_from, date_to, tags, senders
        # [{"unique_opens"=>42,
        #     "unsubs"=>42,
        #     "clicks"=>42,
        #     "time"=>"2013-01-01 15:00:00",
        #     "complaints"=>42,
        #     "rejects"=>42,
        #     "soft_bounces"=>42,
        #     "hard_bounces"=>42,
        #     "sent"=>42,
        #     "unique_clicks"=>42,
        #     "opens"=>42}]

    rescue Mandrill::Error => e
      # Mandrill errors are thrown as exceptions
      puts "A mandrill error occurred: #{e.class} - #{e.message}"
      # A mandrill error occurred: Mandrill::ServiceUnavailableError - Service Temporarily Unavailable
      raise
    end
  end


  #Get the information for a single recently sent message

  def get_info(params)
    begin
      
      id = "abc123abc123abc123abc123"
      result = @mandrill.messages.info id
        # {"smtp_events"=>[{"diag"=>"250 OK", "ts"=>1365190001, "type"=>"sent"}],
        #  "template"=>"example-template",
        #  "opens_detail"=>
        #     [{"ts"=>1365190001,
        #         "location"=>"Georgia, US",
        #         "ip"=>"55.55.55.55",
        #         "ua"=>"Linux/Ubuntu/Chrome/Chrome 28.0.1500.53"}],
        #  "sender"=>"sender@example.com",
        #  "ts"=>1365190000,
        #  "email"=>"recipient.email@example.com",
        #  "_id"=>"abc123abc123abc123abc123",
        #  "metadata"=>{"website"=>"www.example.com", "user_id"=>"123"},
        #  "clicks_detail"=>
        #     [{"ts"=>1365190001,
        #         "location"=>"Georgia, US",
        #         "ip"=>"55.55.55.55",
        #         "ua"=>"Linux/Ubuntu/Chrome/Chrome 28.0.1500.53",
        #         "url"=>"http://www.example.com"}],
        #  "subject"=>"example subject",
        #  "state"=>"sent",
        #  "clicks"=>42,
        #  "opens"=>42,
        #  "tags"=>["password-reset"]}

    rescue Mandrill::Error => e
      # Mandrill errors are thrown as exceptions
      puts "A mandrill error occurred: #{e.class} - #{e.message}"
      # A mandrill error occurred: Mandrill::UnknownMessageError - No message exists with the id 'McyuzyCS5M3bubeGPP-XVA'
      raise
    end
  end



  # GEt the full content of the recently sent mail

  def get_recent_mail_content(params)
    begin
      
      id = "abc123abc123abc123abc123"
      result = @mandrill.messages.content id
        # {"text"=>"Some text content",
        #  "to"=>{"email"=>"recipient.email@example.com", "name"=>"Recipient Name"},
        #  "ts"=>1365190000,
        #  "from_email"=>"sender@example.com",
        #  "_id"=>"abc123abc123abc123abc123",
        #  "html"=>"Some HTML content",
        #  "subject"=>"example subject",
        #  "attachments"=>
        #     [{"type"=>"text/plain",
        #         "content"=>"QSBzaW1wbGUgdGV4dCBzdHJpbmcgYXR0YWNobWVudA==",
        #         "name"=>"example.txt"}],
        #  "tags"=>["password-reset"],
        #  "from_name"=>"Sender Name",
        #  "headers"=>{"Reply-To"=>"replies@example.com"}}

    rescue Mandrill::Error => e
      # Mandrill errors are thrown as exceptions
      puts "A mandrill error occurred: #{e.class} - #{e.message}"
      # A mandrill error occurred: Mandrill::UnknownMessageError - No message exists with the id 'McyuzyCS5M3bubeGPP-XVA'
      raise
    end
  end


  #Parse the full MIME document for an email message, returning the content of the message broken into its constituent pieces

  def message_as_content(params)
    begin
      
      raw_message = "From: #{params[:sender_email]}\nTo: #{params[:recipient]}\nSubject: #{params[:subject].to_s}\n\n #{params[:content].to_s}"
      result = @mandrill.messages.parse raw_message
        # {"subject"=>"Some Subject",
        #  "headers"=>{"Reply-To"=>"replies@example.com"},
        #  "images"=>
        #     [{"content"=>"ZXhhbXBsZSBmaWxl", "name"=>"IMAGEID", "type"=>"image/png"}],
        #  "text"=>"Some text content",
        #  "to"=>[{"name"=>"Recipient Name", "email"=>"recipient.email@example.com"}],
        #  "from_name"=>"Sender Name",
        #  "html"=>"Some HTML content",
        #  "from_email"=>"sender@example.com",
        #  "attachments"=>
        #     [{"content"=>"example non-binary content",
        #         "name"=>"example.txt",
        #         "binary"=>false,
        #         "type"=>"text/plain"}]}

    rescue Mandrill::Error => e
      # Mandrill errors are thrown as exceptions
      puts "A mandrill error occurred: #{e.class} - #{e.message}"
      # A mandrill error occurred: Mandrill::InvalidKeyError - Invalid API key
      raise
    end
  end

  # Take a raw MIME document for a message, and send it exactly as if it were sent through Mandrill's SMTP servers

  def send_mail_from_raw_mime(params)
    begin
      raw_message = "From: #{params[:sender_email]}\nTo: #{params[:recipient]}\nSubject: #{params[:subject].to_s}\n\n #{params[:content].to_s}"

      from_email = params[:sender_email]#"sender@example.com"
      from_name = "From Name"
      to = params[:recipient]#["recipient.email@example.com"]
      async = false
      ip_pool = "Main Pool"
      send_at = params[:send_at].presence || Time.now#"example send_at"
      return_path_domain = nil
      result = @mandrill.messages.send_raw raw_message, from_email, from_name, to, async, ip_pool, send_at, return_path_domain
        # [{"reject_reason"=>"hard-bounce",
        #     "email"=>"recipient.email@example.com",
        #     "_id"=>"abc123abc123abc123abc123",
        #     "status"=>"sent"}]

    rescue Mandrill::Error => e
      # Mandrill errors are thrown as exceptions
      puts "A mandrill error occurred: #{e.class} - #{e.message}"
      # A mandrill error occurred: Mandrill::UnknownSubaccountError - No subaccount exists with the id 'customer-123'
      raise
    end
  end


  # Queries your scheduled emails by sender or recipient, or both.
  def scheduled_email_by_email(params)
    begin
      
      to = params[:recipient]#"test.recipient@example.com"
      result = @mandrill.messages.list_scheduled to
        # [{"subject"=>"This is a scheduled email",
        #     "send_at"=>"2021-01-05 12:42:01",
        #     "to"=>"test.recipient@example.com",
        #     "from_email"=>"sender@example.com",
        #     "created_at"=>"2013-01-20 12:13:01",
        #     "_id"=>"I_dtFt2ZNPW5QD9-FaDU1A"}]

    rescue Mandrill::Error => e
      # Mandrill errors are thrown as exceptions
      puts "A mandrill error occurred: #{e.class} - #{e.message}"
      # A mandrill error occurred: Mandrill::InvalidKeyError - Invalid API key
      raise
    end
  end


  # Cancels a scheduled email.
  def cancel_scheduled_email
    begin
      
      id = nil
      result = @mandrill.messages.cancel_scheduled id
        # {"to"=>"test.recipient@example.com",
        #  "send_at"=>"2021-01-05 12:42:01",
        #  "subject"=>"This is a scheduled email",
        #  "from_email"=>"sender@example.com",
        #  "_id"=>"I_dtFt2ZNPW5QD9-FaDU1A",
        #  "created_at"=>"2013-01-20 12:13:01"}

    rescue Mandrill::Error => e
      # Mandrill errors are thrown as exceptions
      puts "A mandrill error occurred: #{e.class} - #{e.message}"
      # A mandrill error occurred: Mandrill::InvalidKeyError - Invalid API key
      raise
    end
  end


  # Rescheduled a scheduled email
  def reschedule_schedule_email
    begin
      
      id = "I_dtFt2ZNPW5QD9-FaDU1A"
      send_at = "2020-06-01 08:15:01"
      result = @mandrill.messages.reschedule id, send_at
        # {"subject"=>"This is a scheduled email",
        #  "created_at"=>"2013-01-20 12:13:01",
        #  "_id"=>"I_dtFt2ZNPW5QD9-FaDU1A",
        #  "to"=>"test.recipient@example.com",
        #  "from_email"=>"sender@example.com",
        #  "send_at"=>"2021-01-05 12:42:01"}

    rescue Mandrill::Error => e
      # Mandrill errors are thrown as exceptions
      puts "A mandrill error occurred: #{e.class} - #{e.message}"
      # A mandrill error occurred: Mandrill::UnknownMessageError - No message exists with the id 'McyuzyCS5M3bubeGPP-XVA'
      raise
    end

  end

end