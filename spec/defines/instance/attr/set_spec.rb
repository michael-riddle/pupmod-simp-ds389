# frozen_string_literal: true

require 'spec_helper'

describe 'ds389::instance::attr::set', type: :define do
  context 'when on supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "with #{os}" do
        let(:facts) do
          os_facts
        end

        let(:title) do
          'test'
        end

        let(:params) do
          {
            key: 'test_key',
            value: 'test_value',
            root_dn: 'dn=thing',
            root_pw_file: '/some/seekrit/file.skrt',
            instance_name: 'my_service'
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to create_exec("Set #{params[:key]} on #{params[:instance_name]}")
            .with_command(
              sensitive(
                "/usr/sbin/dsconf -y #{params[:root_pw_file]} #{params[:instance_name]} config replace #{params[:key]}=#{params[:value]}",
              ),
            )
            .with_unless(
              sensitive(
                "/usr/sbin/dsconf #{params[:instance_name]} config get '#{params[:key]}' | grep -x '#{params[:key]}: #{params[:value]}'",
              ),
            )
            .that_requires("Ds389::Instance::Service[#{params[:instance_name]}]")
        }

        it { is_expected.not_to create_service(params[:instance_name]) }

        context 'when restarting the service' do
          let(:params) do
            {
              key: 'test_key',
              value: 'test_value',
              root_dn: 'dn=thing',
              root_pw_file: '/some/seekrit/file.skrt',
              instance_name: 'my_service',
              restart_instance: true
            }
          end

          it { is_expected.to compile.with_all_deps }

          it { is_expected.to create_ds389__instance__service(params[:instance_name]) }

          it {
            is_expected.to create_exec("Restart #{params[:instance_name]}")
              .with_command("/usr/sbin/dsctl #{params[:instance_name]} restart")
              .with_refreshonly(true)
          }
        end
      end
    end
  end
end
