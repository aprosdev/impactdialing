module ActiveSupport
  module SecurityUtils
    def secure_compare(a,b)
      return false unless a.bytesize == b.bytesize

      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift } 
      res == 0
    end
    module_function :secure_compare
    
    def variable_size_secure_compare(a,b)
      secure_compare(::Digest::SHA256.hexdigest(a), ::Digest::SHA256.hexdigest(b))
    end
    module_function :variable_size_secure_compare
  end
end

module ActionController
  class Base
    def self.http_basic_authenticate_with(options={})
      authenticate_or_request_with_http_basic(options[:realm] || "Application") do |name, password|
        # This comparison uses & so that it doesn't short circuit and
        # uses `variable_size_secure_compare` so that length information
        # isn't leaked.
        ActiveSupport::SecurityUtils.variable_size_secure_compare(name, options[:name]) &
          ActiveSupport::SecurityUtils.variable_size_secure_compare(password, options[:password])
      end
    end
  end
end
