require 'transproc/registry'
require 'transproc/transformer'

module ROM
  class Changeset
    # Composable data transformation pipe used by default in changesets
    #
    # @api private
    class Pipe < Transproc::Transformer
      extend Transproc::Registry

      import Transproc::HashTransformations

      attr_reader :processor

      def self.add_timestamps(data)
        now = Time.now
        data.merge(created_at: now, updated_at: now)
      end

      def self.touch(data)
        data.merge(updated_at: Time.now)
      end

      def initialize(processor = self.class.transproc)
        @processor = processor
      end

      def [](name)
        self.class[name]
      end

      def bind(context)
        if processor.is_a?(Proc)
          self.class.new(Pipe[-> *args { context.instance_exec(*args, &processor) }])
        else
          self
        end
      end

      def >>(other)
        if processor
          Pipe.new(processor >> other)
        else
          Pipe.new(other)
        end
      end

      def call(data)
        if processor
          processor.call(data)
        else
          data
        end
      end
    end
  end
end
