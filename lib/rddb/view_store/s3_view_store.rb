require 'ftools'

module Rddb #:nodoc:
  module ViewStore #:nodoc:
    # View store implementation that stores view data in the file system.
    class S3ViewStore < Base
      include AWS::S3
      
      # Initialized the view store with the given options.
      #
      # Options:
      # * <tt>:s3</tt>: The S3 configuration
      # * <tt>:basedir</tt>: The base directory
      def initialize(bucket_name, options={})
        AWS::S3::Base.establish_connection!(options[:s3])
        @bucket_name = bucket_name
        @options = options
        @options[:basedir] ||= 'views'
      end
      
      # The bucket name
      def bucket_name
        returning @bucket_name do |name|
          begin
            Bucket.create(name)
          rescue => e
            #puts "Error creating bucket: #{e}"
          end
        end
      end
      
      # Find the view.
      def find(name)
        S3Object.value(File.join(basedir, name), bucket_name)
      end
      
      # Store the view.
      def store(name, view_code)
        S3Object.store(File.join(basedir, name), view_code, bucket_name)
      end
      
      # Delete the view.
      def delete(name)
        S3Object.delete(File.join(basedir, name), bucket_name)
      end
      
      # Return true if the view exists in storage.
      def exists?(name)
        S3Object.exists?(File.join(basedir, name), bucket_name)
      end
      
      # Return each view in the viewstore
      def each(&block)
        Bucket.find(bucket_name).each do |o|
          yield o.value
        end
      end
      
      # List all of the views in the viewstore
      def list
        Bucket.find(bucket_name).collect { |o| o.key.gsub(/#{basedir}\//, '') }
      end
      
      # Delete all views in the viewstore
      def delete_all #:nodoc
        Bucket.find(bucket_name).delete_all
      end
      
      protected
      # The viewstore options
      def options #:nodoc:
        @options
      end
      
      private
      def basedir
        options[:basedir]
      end
    end
  end
end