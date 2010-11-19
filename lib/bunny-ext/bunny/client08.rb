module Bunny
  class Client < Qrack::Client
    # Overwritten with a version that uses Bunny::Timer::timeout
    # instead of Object#timeout which is either timeout.rb (ruby 1.9.x)
    # or SystemTimer (ruby 1.8.x)
    # read: http://ph7spot.com/musings/system-timer
    def next_frame(opts = {})
      frame = nil

      case
        when channel.frame_buffer.size > 0
          frame = channel.frame_buffer.shift
        when opts.has_key?(:timeout)
          Bunny::Timer::timeout(opts[:timeout], Qrack::ClientTimeout) do
            frame = Qrack::Transport::Frame.parse(buffer)
          end
        else
          frame = Qrack::Transport::Frame.parse(buffer)
      end

      @logger.info("received") { frame } if @logging
        
      raise Bunny::ConnectionError, 'No connection to server' if (frame.nil? and !connecting?)

      # Monitor server activity and discard heartbeats
      @message_in = true

      case
        when frame.is_a?(Qrack::Transport::Heartbeat)
          next_frame(opts)
        when frame.nil?
          frame
        when ((frame.channel != channel.number) and (frame.channel != 0))
          channel.frame_buffer << frame
          next_frame(opts)
        else
          frame
      end

    end
  end
end