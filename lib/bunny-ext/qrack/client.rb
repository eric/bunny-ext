module Qrack
  class Client
    SOCKET_TIMEOUT  = 5.0

    alias initialize_without_timeout_opts initialize
    def initialize_with_timeout_opts
      initialize_without_timeout_opts
      @socket_timeout = opts[:socket_timeout] || SOCKET_TIMEOUT
      @use_timeout = RUBY_VERSION >= "1.9"
    end
    alias initialize initialize_with_timeout_opts

    # Overwritten with a version that uses Bunny::Timer::timeout
    # instead of Object#timeout which is either timeout.rb (ruby 1.9.x)
    # or SystemTimer (ruby 1.8.x)
    # read: http://ph7spot.com/musings/system-timer
    def send_command(cmd, *args)
      begin
        raise Bunny::ConnectionError, 'No connection - socket has not been created' if !@socket
        if @use_timeout
          Bunny::Timer::timeout(@socket_timeout, Qrack::ClientTimeout) do
            @socket.__send__(cmd, *args)
          end
        else
          @socket.__send__(cmd, *args)
        end
      rescue Errno::EPIPE, Errno::EAGAIN, Qrack::ClientTimeout, IOError => e
        raise Bunny::ServerDownError, e.message
      end
    end

    # Set socket send and receive timeouts and let the operating system deal
    # with these timeouts. If setting those isn't supported (for example on solaris)
    # we use the Bunny::Timer::timeout method to wrap all socket accesses
    def set_socket_timeouts
      return if @status == :not_connected
      secs   = Integer(@socket_timeout)
      usecs  = Integer((@socket_timeout - secs) * 1_000_000)
      optval = [secs, usecs].pack("l_2")
      begin
        @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
        @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
      rescue Errno::ENOPROTOOPT
        @use_timeout = true
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

      set_socket_timeouts

      @socket
    end
  end
end