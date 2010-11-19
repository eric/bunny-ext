require 'bunny'

module Bunny
  Timer = if RUBY_VERSION < "1.9"
            begin
              require 'system_timer'
              SystemTimer
            rescue LoadError
              Timeout
            end
          else
            Timeout
          end

  private
  def self.setup(version, opts)  
    if version == '08'
      # AMQP 0-8 specification
      require 'qrack/qrack08'
      require 'bunny-ext/qrack/client'
      require 'bunny/client08'
      require 'bunny-ext/bunny/client08'
      require 'bunny/exchange08'
      require 'bunny/queue08'
      require 'bunny/channel08'
      require 'bunny/subscription08'

      client = Bunny::Client.new(opts)
    else
      # AMQP 0-9-1 specification
      require 'qrack/qrack09'
      require 'bunny-ext/qrack/client'
      require 'bunny/client09'
      require 'bunny-ext/bunny/client09'
      require 'bunny/exchange09'
      require 'bunny/queue09'
      require 'bunny/channel09'
      require 'bunny/subscription09'

      client = Bunny::Client09.new(opts)
    end
  end
end
