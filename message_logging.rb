require 'logger'

module MessageLogging

  def self.included base
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods
      def logger
        @logger ||= begin
          logger = Logger.new($stdout)
          logger.level = Logger::DEBUG
          logger
        end
      end
    end

    module ClassMethods
      def logger
        Logging.logger
      end
    end
end
