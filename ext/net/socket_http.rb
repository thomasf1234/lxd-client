require 'net/http'
require 'socket'

module Net
  #  Overrides the connect method to simply connect to a unix domain socket.
  class SocketHttp < HTTP
    attr_reader :socket_path

    #  URI should be a relative URI giving the path on the HTTP server.
    #  socket_path is the filesystem path to the socket the server is listening to.
    def initialize(uri, socket_path)
      @socket_path = socket_path
      super(uri)
    end

    #  Create the socket object.
    def connect
      D "opening connection to #{conn_address}:#{conn_port}..."
      s = Timeout.timeout(@open_timeout, Net::OpenTimeout) {
        UNIXSocket.open(@socket_path)
      }
      D "opened"
      @socket = Net::BufferedIO.new(s)
      @socket.read_timeout = @read_timeout
      @socket.continue_timeout = @continue_timeout
      @socket.debug_output = @debug_output
      on_connect
    end

    #  Override to prevent errors concatenating relative URI objects.
    def addr_port
      File.basename(socket_path)
    end
  end
end