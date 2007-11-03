# Source file containing the Rddb::Database class definition
module Rddb #:nodoc:
  # The database.
  class Database
    # A Logger for the database.
    attr_accessor :logger
    
    # The document store.
    attr_reader :document_store
    
    # The materializer (defaults to ThreadedMaterializer)
    attr_reader :materializer
    
    # Initialize the database.
    #
    # Options:
    # * <tt>:document_store</tt>: A DocumentStore instance
    # * <tt>:materializer_class</tt>: The Materializer class 
    def initialize(options={})
      @document_store = options[:document_store] || DocumentStore::RamDocumentStore.new
      @materializer = (options[:materializer_class] || Materializer::ThreadedMaterializer).new(self)
      @batch = false
      database_listeners << @materializer
    end
    
    # Add a document to the database. The document may either be a Hash or
    # a Rddb::Document instance.
    def <<(document)
      case document
      when Hash
        # create a Document from the Hash and then call << again
        self << Document.new(document)
      when Document
        document_store.store(document)
        # TODO: this may be a bottleneck, allow index updating
        document_store.write_indexes unless batch?
        document_added(document)
        document
      else
        raise ArgumentError, "The document must be either a Hash or a Document"
      end
    end
    
    # Batch process the given block, disabling materialization queue updating
    # and index writing until the block has completed. All views that are 
    # materialized will be refreshed upon completion of the block and any
    # document_store indexes will be written.
    def batch(&block)
      @batch = true
      yield
      refresh_views
      document_store.write_indexes
      @batch = false
    end
    
    # Return true if the database is currently in batch write mode.
    def batch?
      @batch
    end
    
    # Get a document by it's ID.
    def [](id)
      document_store.find(id)
    end
    
    # Return the total count of documents in the database
    def count
      document_store.count
    end
    
    # Query the named view
    def query(name, args={})
      raise ArgumentError, "View '#{name}' does not exist." unless views.key?(name)
      views[name].query(document_store, args)
    end
    
    # Create the named view with the given filter code.
    # Returns the newly created view object.
    def create_view(name, options={}, &block)
      returning View.new(self, name, options, &block) do |view|
        views[name] = view
      end
    end
    
    # Refresh all materialized views.
    def refresh_views
      @materializer.refresh_views
    end
    
    # Get named views.
    def views
      @views ||= {}
    end
    
    # Make sure the logger is instantiated. This method is nodoc'd because the 
    # attr_accessor :logger is defined in this class.
    def logger #:nodoc:
      unless @logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::FATAL
      end
      @logger
    end
    
    # Listeners that will be invoked when a document is added to the database.
    # Each object in this collection should have the method 
    # document_added(document)
    def database_listeners
      @database_listeners ||= []
    end
    
    private
    # Method that is invoked each time a document is added.
    def document_added(document)
      database_listeners.each { |l| l.document_added(document) }
    end
  end
end