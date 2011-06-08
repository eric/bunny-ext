require 'qrack/client'


module Qrack
  class Client

    alias initialize_without_timeout_opts initialize
    def initialize_with_timeout_opts(opts = {})
      initialize_without_timeout_opts(opts)
      @read_write_timeout = opts[:socket_timeout]
      @read_write_timeout = nil if @read_write_timeout == 0
    end
    alias initialize initialize_with_timeout_opts

    # Overwritten with a version that uses Bunny::Timer::timeout
    # instead of Object#timeout which is either timeout.rb (ruby 1.9.x)
    # or SystemTimer (ruby 1.8.x)
    # read: http://ph7spot.com/musings/system-timer
    def send_command(cmd, *args)
      begin
        raise Bunny::ConnectionError, 'No connection - socket has not been created' if !@socket
        if @read_write_timeout
          Bunny::Timer::timeout(@read_write_timeout, Qrack::ClientTimeout) do
            @socket.__send__(cmd, *args)
          end
        else
          @socket.__send__(cmd, *args)
        end
      rescue Errno::EPIPE, Errno::EAGAIN, Qrack::ClientTimeout, IOError => e
        raise Bunny::ServerDownError, e.message
      end
    end

    def socket
      return @socket if @socket and (@status == :connected) and not @socket.closed?

      begin
        # Attempt to connect.
        @socket = Bunny::Timer::timeout(@connect_timeout, ConnectionTimeout) do
          TCPSocket.new(host, port)
        end

        if Socket.constants.include? 'TCP_NODELAY'
          @socket.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
        end

        if @ssl
          require 'openssl' unless defined? OpenSSL::SSL
          @socket = OpenSSL::SSL::SSLSocket.new(@socket)
          @socket.sync_close = true
          @socket.connect
          @socket.post_connection_check(host) if @verify_ssl
          @socket
        end
      rescue => e
        @status = :not_connected
        raise Bunny::ServerDownError, e.message
      end

      @socket
    end

    def disconnect_timeout
      @read_write_timeout || @connect_timeout
    end

    def close
      return if @socket.nil? || @socket.closed?

      # Close all active channels
      channels.each { |c| Bunny::Timer::timeout(disconnect_timeout) { c.close if c.open? } }

      # Close connection to AMQP server
      Bunny::Timer::timeout(disconnect_timeout) { close_connection }
    rescue Exception
      # http://http://cheezburger.com/Asset/View/4033311488
    ensure
      @channels = []

      # Create channel 0
      @channel = create_channel()

      close_socket
    end

    alias stop close

  end
end
