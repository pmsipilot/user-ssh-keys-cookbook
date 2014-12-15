module PMSIpilot
  module SshKeys
    module Key
      def self.valid?(key)
        (
          (key.key?('id') and not key['id'].empty?) and
          (key.key?('priv') and not key['priv'].empty?)
        ) or (
          (key.key?(:id) and not key[:id].empty?) and
          (key.key?(:priv) and not key[:priv].empty?)
        )
      end

      def self.raise_if_invalid!(key)
        raise Chef::Exceptions::ConfigurationError, 'Invalid key configuration' unless valid?(key)

        key
      end

      def self.normalize!(key)
        normalized = raise_if_invalid!(key).dup

        normalized['pub'] ||= ''

        normalized
      end
    end
  end
end
