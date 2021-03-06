require 'hipchat'

class Service::HipChat < Service::Base
  title 'HipChat'

  string :api_token, :placeholder => 'API Token',
         :label => 'Your HipChat API Token. <br />' \
                   'You can create an API v1 notification token ' \
                   '<a href="https://www.hipchat.com/admin/api">here</a>.'
  checkbox :v2, :label => 'Is this an API v2 token?'
  string :room, :placeholder => 'Room ID or Name', :label => 'The ID or name of the room.'
  checkbox :notify, :label => 'Should a notification be triggered for people in the room?'
  string :url, :placeholder => 'https://api.hipchat.com', :label => 'The URL of the HipChat server.'

  page 'API Token', [:api_token, :v2]
  page 'Room', [:room, :notify]
  page 'URL', [:url]

  def receive_verification(config, _)
    send_message(config, receive_verification_message)
    [true, "Successfully sent a mesage to room #{ config[:room] }"]
  rescue => e
    log "Rescued a verification error in HipChat: #{ e }"
    [false, "Could not send a message to room #{ config[:room] }"]
  end

  def receive_issue_impact_change(config, payload)
    send_message(config, format_issue_impact_change_message(payload))
    :no_resource
  rescue => e
    log "Rescued an issue_impact_change error in HipChat: #{ e }"
  end

  private

  def receive_verification_message
    'Boom! Crashlytics issue change notifications have been added.  ' \
    '<a href="http://support.crashlytics.com/knowledgebase/articles/349341-what-kind-of-third-party-integrations-does-crashly">' \
    'Click here for more info</a>.'
  end

  def format_issue_impact_change_message(payload)
    "<a href=#{ payload[:url].to_s }>" \
    "[#{ payload[:app][:name] } - #{ payload[:app][:bundle_identifier] }] Issue ##{ payload[:display_id] }: " \
    "#{ payload[:title] } #{ payload[:method] }" \
    '</a>'
  end

  def send_message(config, message)
    token = config[:api_token]
    room = config[:room]
    url = config[:url]
    api_version = config[:v2] ? 'v2' : 'v1'
    notify = config[:notify] ? true : false
    options = { :api_version => api_version }
    server_url = url.to_s
    unless server_url.empty?
      options[:server_url] = server_url
    end
    client = HipChat::Client.new(token, options)
    client[room].send('Crashlytics', message, :notify => notify)
  end
end
