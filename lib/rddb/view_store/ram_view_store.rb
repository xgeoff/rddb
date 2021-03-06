module Rddb #:nodoc:
  module ViewStore #:nodoc:
    # View store implementation that stores view data in RAM.
    class RamViewStore < Base
      
      # Initialized the view store with the given options.
      def initialize(options={})
        @options = options
      end
      
      # Find the view.
      def find(name)
        views[name]
      end
      
      # Store the view.
      def store(name, view_code)
        views[name] = view_code
      end
      
      # Delete the view.
      def delete(name)
        views.delete(name)
      end
      
      # Return true if the view exists in storage.
      def exists?(name)
        views.key?(name)
      end
      
      # Return each view in the viewstore
      def each(&block)
        views.each do |name, view|
          yield view
        end
      end
      
      # List all of the views in the viewstore
      def list
        views.collect { |pair| pair.first }
      end
      
      # The viewstore options
      def options #:nodoc:
        @options
      end
      
      private
      def views
        @views ||= {}
      end
    end
  end
end