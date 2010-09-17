#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3.  See
#   the COPYRIGHT file.



class MessageHandler


  NUM_TRIES = 5
  TIMEOUT = 5 #seconds

  def initialize
    @queue = EM::Queue.new
  end

  def add_get_request(destinations)
    [*destinations].each{ |dest| @queue.push(Message.new(:get, dest))}
  end

  def add_post_request(destinations, body)
    b = CGI::escape( body )
    [*destinations].each{|dest| @queue.push(Message.new(:post, dest, :body => b))}
  end

  def process
    @queue.pop{ |query|
      case query.type
      when :post
        http = EventMachine::HttpRequest.new(query.destination).post :timeout => query.timeout, :body =>{:xml => query.body}
        http.callback { process; process}
      when :get
        http = EventMachine::HttpRequest.new(query.destination).get :timeout => TIMEOUT
        http.callback {
          Rails.logger.info("Query succeeded")
          send_to_seed(query, http.response); process
        }
      else
        raise "message is not a type I know!"
      end

      http.errback {
        Rails.logger.info(http.response)
        Rails.logger.info(http.error)
        Rails.logger.info("(#{query.try_count+1}) Failure from #{query.destination}, retrying...")

        query.try_count +=1
        query.timeout *= 2 # Increase the timeout, because it might be a slow server
        @queue.push query unless query.try_count >= NUM_TRIES
        process
      }
    } unless @queue.size == 0
  end

  def send_to_seed(message, http_response)
    #DO SOMETHING!
  end

  def size
    @queue.size
  end

  class Message
    attr_accessor :type, :destination, :body, :callback, :owner_url, :try_count, :timeout
    def initialize(type, dest, opts = {})
      @type = type
      @owner_url = opts[:owner_url]
      @destination = dest
      @body = opts[:body]
      @callback = opts[:callback] ||= lambda{ process; process }
      @try_count = 0
      @timeout = TIMEOUT
    end
  end
end
