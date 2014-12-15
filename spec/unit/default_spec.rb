require 'spec_helper'

describe 'ssh-keys::default' do
  describe 'With empty attribute' do
    it 'Throws a ConfigurationError with missing attributes' do
      chef_run = ChefSpec::SoloRunner.new do |node|
        node.set['ssh_keys'] = nil
      end

      expect { chef_run.converge(described_recipe) }.to raise_error(Chef::Exceptions::ConfigurationError)
    end

    it 'Throws a ConfigurationError with empty attributes' do
      chef_run = ChefSpec::SoloRunner.new do |node|
        node.set['ssh_keys'] = {}
      end

      expect { chef_run.converge(described_recipe) }.to raise_error(Chef::Exceptions::ConfigurationError)
    end
  end

  describe 'Deploys SSH keys' do
    describe 'With one user' do
      it 'Throws a ConfigurationError with missing attributes' do
        chef_run = ChefSpec::SoloRunner.new do |node|
          node.set['ssh_keys'] = {
            :bob => {}
          }
        end

        expect { chef_run.converge(described_recipe) }.to raise_error(Chef::Exceptions::ConfigurationError)
      end

      it 'Throws a ConfigurationError if user does not exist' do
        chef_run = ChefSpec::SoloRunner.new do |node|
          node.set['ssh_keys'] = {
            :users => {
              :bob => {
                :authorized_keys => [
                  'foobar'
                ]
              }
            }
          }
        end

        expect { chef_run.converge(described_recipe) }.to raise_error(Chef::Exceptions::ConfigurationError)
      end

      it 'Should create .ssh directory if it does not exist' do
        allow(Dir).to receive(:home) { '/home/bob' }
        stub_command('test -e /home/bob/.ssh').and_return(false)
        stub_data_bag(:ssh_keys).and_return({})

        chef_run = ChefSpec::SoloRunner.new do |node|
          node.set['ssh_keys'] = {
            :users => {
              :bob => {
                :authorized_keys => [
                  'foobar'
                ]
              }
            }
          }
        end

        expect(chef_run.converge(described_recipe)).to create_directory('/home/bob/.ssh').with({
          :user => 'bob',
          :group => 'bob',
          :mode => '0600'
        })
      end

      it 'Should not create .ssh directory if it exists' do
        allow(Dir).to receive(:home) { '/home/bob' }
        stub_command('test -e /home/bob/.ssh').and_return(true)
        stub_data_bag(:ssh_keys).and_return({})

        chef_run = ChefSpec::SoloRunner.new do |node|
          node.set['ssh_keys'] = {
            :users => {
              :bob => {
                :authorized_keys => [
                  'foobar'
                ]
              }
            }
          }
        end

        expect(chef_run.converge(described_recipe)).to_not create_directory('/home/bob/.ssh')
      end

      describe 'With a single key' do
        it 'Should deploy user\'s SSH key' do
          allow(Dir).to receive(:home) { '/home/bob' }
          stub_command('test -e /home/bob/.ssh').and_return(false)
          stub_data_bag(:ssh_keys).and_return({
            :bob => [
              {
                :id => 'the_key',
                :pub => 'the_public_key',
                :priv => 'the_private_key'
              }
            ]
          })

          chef_run = ChefSpec::SoloRunner.new do |node|
            node.set['ssh_keys'] = {
              :users => {
                :bob => {
                    :databag => 'ssh_keys'
                }
              }
            }
          end

          expect(chef_run.converge(described_recipe)).to create_file('/home/bob/.ssh/the_key.pub').with({
            :user => 'bob',
            :group => 'bob',
            :mode => '0600',
            :content => 'the_public_key'
          })
          expect(chef_run.converge(described_recipe)).to create_file('/home/bob/.ssh/the_key').with({
            :user => 'bob',
            :group => 'bob',
            :mode => '0600',
            :content => 'the_private_key'
          })
        end
      end

      describe 'With multiple keys' do
        it 'Should deploy user\'s SSH keys' do
          allow(Dir).to receive(:home) { '/home/bob' }
          stub_command('test -e /home/bob/.ssh').and_return(false)
          stub_data_bag(:ssh_keys).and_return({
            :bob => [
              {
                :id => 'the_key',
                :pub => 'the_public_key',
                :priv => 'the_private_key'
              },
              {
                :id => 'other_key',
                :pub => 'other_public_key',
                :priv => 'other_private_key'
              }
            ]
          })

          chef_run = ChefSpec::SoloRunner.new do |node|
            node.set['ssh_keys'] = {
              :users => {
                :bob => {
                    :databag => 'ssh_keys'
                }
              }
            }
          end

          expect(chef_run.converge(described_recipe)).to create_file('/home/bob/.ssh/the_key.pub').with({
            :user => 'bob',
            :group => 'bob',
            :mode => '0600',
            :content => 'the_public_key'
          })
          expect(chef_run.converge(described_recipe)).to create_file('/home/bob/.ssh/the_key').with({
            :user => 'bob',
            :group => 'bob',
            :mode => '0600',
            :content => 'the_private_key'
          })

          expect(chef_run.converge(described_recipe)).to create_file('/home/bob/.ssh/other_key.pub').with({
            :user => 'bob',
            :group => 'bob',
            :mode => '0600',
            :content => 'other_public_key'
          })
          expect(chef_run.converge(described_recipe)).to create_file('/home/bob/.ssh/other_key').with({
            :user => 'bob',
            :group => 'bob',
            :mode => '0600',
            :content => 'other_private_key'
          })
        end
      end
    end
  end

  describe 'Add authorized keys' do
    describe 'With one user' do
      it 'Should add authorized key' do
        allow(Dir).to receive(:home) { '/home/bob' }
        stub_command('test -e /home/bob/.ssh').and_return(false)
        stub_data_bag(:ssh_keys).and_return({})

        chef_run = ChefSpec::SoloRunner.new do |node|
          node.set['ssh_keys'] = {
            :users => {
              :bob => {
                :authorized_keys => [
                  'foobar'
                ]
              }
            }
          }
        end

        expect(chef_run.converge(described_recipe)).to render_file('/home/bob/.ssh/authorized_keys').with_content('foobar')
      end
    end
  end

  describe 'Add authorized users' do
    describe 'With one user' do
      it 'Throws a ConfigurationError if user does not exist in databag' do
        chef_run = ChefSpec::SoloRunner.new do |node|
          node.set['ssh_keys'] = {
            :users => {
              :bob => {
                :authorized_users => [
                  'joe'
                ]
              }
            }
          }
        end

        expect { chef_run.converge(described_recipe) }.to raise_error(Chef::Exceptions::ConfigurationError)
      end

      it 'Should add authorized user\'s key' do
        allow(Dir).to receive(:home) { '/home/bob' }
        stub_command('test -e /home/bob/.ssh').and_return(false)
        allow(Dir).to receive(:home) { '/home/bob' }
        stub_command('test -e /home/bob/.ssh').and_return(false)
        stub_data_bag(:ssh_keys).and_return({
          :bob => [
            {
              :id => 'bob_key',
              :pub => 'bob_public_key',
              :priv => 'bob_private_key'
            }
          ],
          :joe => [
            {
              :id => 'job_key',
              :pub => 'joe_public_key',
              :priv => 'joe_private_key'
            }
          ]
        })

        chef_run = ChefSpec::SoloRunner.new do |node|
          node.set['ssh_keys'] = {
            :users => {
              :bob => {
                :authorized_users => [
                  'joe'
                ]
              }
            }
          }
        end

        expect(chef_run.converge(described_recipe)).to render_file('/home/bob/.ssh/authorized_keys').with_content('joe_public_key')
      end

      it 'Should add authorized user\'s keys' do
        allow(Dir).to receive(:home) { '/home/bob' }
        stub_command('test -e /home/bob/.ssh').and_return(false)
        allow(Dir).to receive(:home) { '/home/bob' }
        stub_command('test -e /home/bob/.ssh').and_return(false)
        stub_data_bag(:ssh_keys).and_return({
          :bob => [
            {
              :id => 'bob_key',
              :pub => 'bob_public_key',
              :priv => 'bob_private_key'
            }
          ],
          :joe => [
            {
              :id => 'joe_key',
              :pub => 'joe_public_key',
              :priv => 'joe_private_key'
            },
            {
              :id => 'joe_other_key',
              :pub => 'joe_other_public_key',
              :priv => 'joe_other_private_key'
            }
          ]
        })

        chef_run = ChefSpec::SoloRunner.new do |node|
          node.set['ssh_keys'] = {
            :users => {
              :bob => {
                :authorized_users => [
                  'joe'
                ]
              }
            }
          }
        end

        expect(chef_run.converge(described_recipe)).to render_file('/home/bob/.ssh/authorized_keys').with_content("joe_public_key\njoe_other_public_key")
      end
    end
  end
end
