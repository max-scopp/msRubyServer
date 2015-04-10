require 'socket'
require "#{SERVER}/client"

class Server

  #
  # Starts the Server
  #
  # @since 1.0a
  def self.init
    Log.info " ** Starting server..."

    begin
      @server = TCPServer.open(CONFIG[:host], CONFIG[:port])
    rescue Exception => e
      Log.fatal " ** #{e.message.colorize(:red)}"
      exit!
    end

    Log.info " ** running on #{@server.local_address.ip_unpack.join("/")}"

    @blacklist = Array.new
    File.new(BLACKLIST).each { |address|
      @blacklist << address.chomp
    }

    loop do
      begin
        # accept client, fork a Thread and handle it with a seperate class
        Thread.fork(@server.accept) { |connection|
          client = Client.new connection

          begin
            if @blacklist.include?(connection.remote_address.ip_address)
              client.respond_code(403, "Blacklisted")
            elsif CONFIG[:make_unavailable]
              client.respond_code(503)
            else
              client.handle
            end
          rescue Exception => e
            Log.error "[#{client.getid}] #{e.to_s.red}\n" + e.backtrace.join("\n\t")
            client.respond_code(500)
          end
        }
      rescue Interrupt
        puts "Received Interrupt signal, killing server...".red.on_yellow
        @server.close
        exit!
      end
    end
    nil
  end

  #
  # Returns the Address which the Server is running on
  #
  # @since 0.1b
  def self.running_address
    @server.connect_address
  end
end
