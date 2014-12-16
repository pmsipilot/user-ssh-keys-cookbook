require 'chef/data_bag'

module PMSIpilot
  module SshKeys
    module User
      def self.valid?(username, user)
        begin
          Dir.home(username)
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

      def self.raise_if_invalid!(username, user)
        raise Chef::Exceptions::ConfigurationError, 'Invalid user configuration' unless valid?(username, user)

        user
      end

      def self.normalize!(username, user, node, data_bag_proc)
        normalized = raise_if_invalid!(username, user).dup

        normalized['databag'] = data_bag_proc.call(node['ssh_keys']['databag'], username)
        normalized['databag'] ||= []
        normalized['home'] = Dir.home(username)
        normalized['authorized_keys'] ||= []
        normalized['authorized_users'] ||= []
        normalized['keys'] = []

        normalized['databag']['keys'].each do |key|
          normalized['keys'] << PMSIpilot::SshKeys::Key.normalize!(key)
        end

        normalized['authorized_users'].each do |authorized_user|
          authorized_user_bag = data_bag_proc.call(node['ssh_keys']['databag'], authorized_user)

          raise Chef::Exceptions::ConfigurationError, "User #{authorized_user} does not exist" if authorized_user_bag.nil?

          authorized_user_bag['keys'].each do |authorized_user_key|
            normalized['authorized_keys'] << PMSIpilot::SshKeys::Key.normalize!(authorized_user_key)['pub']
          end
        end

        normalized
      end
    end
  end
end
