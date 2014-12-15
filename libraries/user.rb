require 'chef/data_bag'

module PMSIpilot
  module SshKeys
    module User
      def self.valid?(name, user)
        begin
          Dir.home(name)
        rescue
          raise Chef::Exceptions::ConfigurationError, "User #{user} does not exist"
        end

        (
          (user.key?('authorized_keys') and not user['authorized_keys'].empty?) or
          (user.key?('authorized_users') and not user['authorized_users'].empty?)
        ) or (
          (user.key?(:authorized_keys) and not user[:authorized_keys].empty?) or
          (user.key?(:authorized_users) and not user[:authorized_users].empty?)
        ) or (
          not user.key?('authorized_keys') and
          not user.key?('authorized_users') and
          not user.key?(:authorized_keys) and
          not user.key?(:authorized_users)
        )
      end

      def self.raise_if_invalid!(name, user)
        raise Chef::Exceptions::ConfigurationError, 'Invalid user configuration' unless valid?(name, user)

        user
      end

      def self.normalize!(name, user, node, data_bag_proc)
        normalized = raise_if_invalid!(name, user).dup

        databag = data_bag_proc.call(node['ssh_keys']['databag'])

        normalized['databag'] = databag[name]
        normalized['databag'] ||= []
        normalized['home'] = Dir.home(name)
        normalized['authorized_keys'] ||= []
        normalized['authorized_users'] ||= []
        normalized['keys'] = []


        normalized['databag'].each do |key|
          normalized['keys'] << PMSIpilot::SshKeys::Key.normalize!(key)
        end

        normalized['authorized_users'].each do |authorized_user|
          raise Chef::Exceptions::ConfigurationError, "User #{authorized_user} does not exist" if databag[authorized_user].nil?

          databag[authorized_user].each do |authorized_user_key|
            normalized['authorized_keys'] << PMSIpilot::SshKeys::Key.normalize!(authorized_user_key)['pub']
          end
        end

        normalized
      end
    end
  end
end
