#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'json'
require 'open3'
require 'tmpdir'

# platform, version (codename, not numeric)
class BuildPEInstallerPackage < TaskHelper
  def get_local_sha_pwd(dir)
    sha, pwd = nil, nil
    Dir.chdir dir do
      sha = Open3.capture2e('git rev-parse --verify HEAD')[0].strip
      pwd = Open3.capture2e('pwd')[0].strip
    end
    [sha, pwd]
  end

  def update_component_json(component, sha, pwd)
    component_json = File.read("configs/components/#{component}.json")
    component_hash = JSON.parse(component_json)

    component_hash['ref'] = sha
    component_hash['url'] = pwd
    f = File.open("configs/components/#{component}.json", 'w+')
    f.write(component_hash.to_json)
    f.close
  end

  def task(platforms: nil, **kwargs)
    version = kwargs[:version]
    enterprise_tasks = kwargs[:enterprise_tasks]
    enterprise_tasks_pr = kwargs[:enterprise_tasks_pr]
    higgs = kwargs[:higgs]
    higgs_pr = kwargs[:higgs_pr]

    enterprise_tasks_sha = nil
    enterprise_tasks_pwd = nil
    if enterprise_tasks
      enterprise_tasks_sha, enterprise_tasks_pwd = get_local_sha_pwd(enterprise_tasks)
    elsif enterprise_tasks_pr
    end

    higgs_sha = nil
    higgs_pwd = nil
    if higgs
      higgs_sha, higgs_pwd = get_local_sha_pwd(higgs)
    elsif higgs_pr
    end

    output = ''
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        output, status = Open3.capture2e("git clone -b #{version} --single-branch git@github.com:puppetlabs/pe-installer-vanagon.git")
        raise TaskHelper::Error.new("Unable to clone pe-installer-vanagon #{dir}", 'barr.buildpackages/pe-installer-failed', output) if !status.exitstatus.zero?

        Dir.chdir 'pe-installer-vanagon' do
          output, status = Open3.capture2e('bundle install')
          if enterprise_tasks_sha
            update_component_json('enterprise_tasks', enterprise_tasks_sha, enterprise_tasks_pwd)
          end

          if higgs_sha 
            update_component_json('higgs', higgs_sha, higgs_pwd)
          end

          platforms = [platforms]
          platforms.each do |platform|
            output, status = Open3.capture2e("bundle exec build pe-installer #{platform}")
            raise TaskHelper::Error.new("Unable to build PE Installer package for platform #{platform}", 'barr.buildpackages/pe-installer-failed', output) if !status.exitstatus.zero?
            output, status = Open3.capture2e("mv output/ ~/Desktop/pe-installer-package")
          end
        end
      end
    end

    result = { _output: output }
    result.to_json
  end
end

if __FILE__ == $PROGRAM_NAME
  begin
    BuildPEInstallerPackage.run 
  rescue TaskHelper::Error => e
    FileUtils.remove_entry_secure Dir.tmpdir
  end
end
