require "#{SERVER}/urlHandler"
require "#{SERVER}/parser"
require "colorize"

class Client

  #
  # Creates a new class instance of an TCP-Socket client
  #
  # @param client TCP-Socket The client to handle
  # @since 1.0a
  def initialize(client)
    @id = Thread.list.select.count - 1
    @client = client
    Thread.current['client'] = @client # "global" variable
    @remote_address = @client.remote_address.ip_address.to_s
    @response_header = Array.new
    @request_type,
      @request_url,
      http_version = @client.gets.match(/(.+) (.+) (.+)\r/).captures
    @head = Hash.new

    Log.info "[#{@id}] >> #{@request_type.light_green.on_green} "+
      "#{@request_url.green} #{http_version} (#{@remote_address})"

    # You should change this later maybe...
    loop {
      line_head = @client.gets
      break if line_head == "\r\n"
      index,
      content = line_head.match(/(.+)\:\s(.+)/).captures

      @head.store(index, content.chomp) # chomp last \r
    }
  end

  #
  # Process the request
  #
  # @todo implement more HTTP-Functions like POST
  # @since 0.1b
  def handle
    case @request_type.upcase
    when "GET"
      handle_get
    else
      respond_code(501)
    end
  end

  #
  # Will set a Header-Settings, before it is going to send out
  #
  # @param index The Header-Identifier, like "Content-Length"
  # @param content The Actual content assigned to the index
  # @param override [boolean] On true, will override the existing index
  # @since 0.1b
  def set_header(index, content, override = true)
    contains = false
    @response_header.each { |item|
      if item[0] == index
        item[1] = content if override
        contains = true
      end
    }
    @response_header.insert(0, [index, content]) if !contains
  end

  #
  # Retrieve a specific Header-Information
  #
  # @param index The index-name of the Header-information
  # @return [String,nil] If the Index is out of range, nil is getting returned
  # @since 0.1b
  def get_header(index)
    @response_header.each { |item|
      return item[1] if item[0] == index
    }
    nil
  end

  #
  # Will appen missing, but important Header-Informations
  # @since 0.1b
  def prepare_header
    set_header("Content-Length", @response.bytesize)
    set_header("Connection", "close")
    set_header("Content-Type", "text/html", false)
  end

  #
  # Checks if a file exists by the given path
  #
  # @return [Boolean] True when the file is found and is a file too, else false
  # @since 1.0a
  def file_exist?(path)
    return !!(File.exists?(path) && File.file?(path))
  end

  #
  # Will print out the Response-Message for the connected client
  # When this Function is done with writing, the Connection will be closed
  # and the Thread Terminated. Log files will remain.
  #
  # @param code The HTTP-Statuscode
  # @param message A additional message for the Code
  # @since 1.0a
  def send_response(code, message = nil)
    prepare_header

    case # prettify it for my granny eyes!
    when code >= 500 # server error
      code = code.to_s.on_red
    when code >= 400 # client error
      code = code.to_s.red
    when code >= 300 # redirect
      code = code.to_s.yellow
    when code >= 200 # successful operation
      code = code.to_s.green
    when code >= 100 # informational
      code = code.to_s.cyan
    end

    message = MESSAGE[code.uncolorize.to_i] if message == nil

    Log.info "[#{@id}] << #{code} #{message} \"#{get_header("Content-Type")}\""

    head = Array.new
    @response_header.each { |line|
      head.insert(0, "#{line[0]}: #{line[1]}")
    }

    # Send the Response-Status as required
    @client.print "HTTP/1.1 #{code.uncolorize}\r\n"

    # Send other Header-Response Informations
    head.join("\r\n").each_char { |char|
      @client.print char
    }

    # Send missing CLR from last Header-line and
    # one empty line as required by the protocol
    @client.print "\r\n" * 2

    # print the actual Response-Body
    @response.each_char { |char|
      @client.print char
    }

    # close connection and Terminate
    close
  end

  #
  # Will replace any response content with static HTML and the Status-Code
  # as given by the arguments
  #
  # @param code The Statuscode to be send
  # @param error_message An additional message that may explains the Statuscode
  # @since 1.0a
  def respond_code code, error_message = nil
    @response =
      "<!DOCTYPE html>\n"\
      "<html>\n"\
      "<head>\n"\
      "    <title>#{code} #{MESSAGE[code]}</title>\n"\
      "</head>\n"\
      "<body>\n"\
      "    <h1>#{MESSAGE[code] rescue "unknown"}</h1>\n"\
      "    <hr />\n"\
      "    <em>msRubyServer Version #{VERSION} &copy; 2015 Max Scopp.</em>\n"\
      "</body>\n"\
      "</html>"

    send_response(code)
  end

  #
  # Will serve a requested File under PATHS[:file_drops] in the config file
  #
  # @param path The path to the File which should be served
  # @param code Maybe a different Statuscode unless it's OK (200)
  # @since 1.0a
  def respond_file(path, code = 200)
    @response = ""
    File.readlines(path).each do |line|
      @response << line
    end

    send_response(code)
  end

  #
  # Will print out anything given as String to the Client with
  # a given mime-type, default is text/html
  #
  # @param response The Body-Content to be served to the Client
  # @param code The Statuscode for the Client, fallback is 200 (OK)
  # @param mime The Mime-Type which explains the Client what the Body is
  # @since 1.0a
  def respond(response, code = 200, mime = "text/html")
    @response = ""
    response.each_line do |line|
      @response << line
    end

    set_header("Content-Type", mime)
    send_response(code)
  end

  #
  # Will close the Connection to the Client and Terminated this Thread
  # @since 1.0a
  def close
    @client.close
    Thread.current.exit
  end

  #############################################################################
  ##                                                                         ##
  ##                                 HANDLERS                                ##
  ##                                                                         ##
  #############################################################################

  #
  # Will process the request as a GET-Method
  # @todo outsource HTTP-Methods to an extra file/class for better clarity
  # @since 1.0a
  def handle_get
    if URLHandler.routable? @request_url
      handler = URLHandler.new(@request_url)
      content = handler.get_generated_content
      code    = handler.get_response_code
      mime    = handler.get_mime_type

      respond(content, code, mime)
    else
      respond_code(404)
    end
  end
end
