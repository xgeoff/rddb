module Rddb #:nodoc:
  module Server #:nodoc:
    # Server class.
    class Server
      # The options
      attr_reader :options
      
      # Initialize the server.
      def initialize(options={})
        @options = options
      end
      
      # Run the server.
      def run
        Daemons.run_proc('server') do
          ring_service_thread = RingService.new(options).run
          mongrel_service_thread = MongrelService.new(options).run
          ring_service_thread.join
          mongrel_thread.join
        end
      end
      
      class RingService #:nodoc:
        def initialize(options={})
          @options = options
        end
        def run
          # start DRb
          DRb.start_service
          puts "Starting DRb"

          # Create a TupleSpace to hold named services, and start running
          Rinda::RingServer.new Rinda::TupleSpace.new
          provider = Rinda::RingProvider.new(:TupleSpace, Rinda::TupleSpace.new, 'Tuple Space')
          provider.provide

          puts "Ring server running"
          
          DRb.thread
        end
      end
      
      class MongrelService #:nodoc:
        attr_reader :options
        def initialize(options={})
          @options = options
        end
        
        def run
          # Start the mongrel server
          options[:host] ||= 'localhost'
          options[:port] ||= 3000
          @http_server = Mongrel::HttpServer.new(options[:host], options[:port])
          @http_server.register('/documents/', DocumentHandler.new(document_store))
          @http_server.register('/views/', ViewHandler.new(view_store))
          @http_server.register('/', DefaultHandler.new)
          mongrel_thread = @http_server.run
          puts "Mongrel server running on port #{options[:port]}"
          mongrel_thread
        end
        
        private
        def view_store
          @view_store ||= Rddb::ViewStore::RamViewStore.new(options)
        end

        def document_store
          @document_store ||= Rddb::DocumentStore::RamDocumentStore.new(options)
        end
      end
      
    end
  end
end