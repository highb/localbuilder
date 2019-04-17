#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'json'
require 'open3'
require 'tmpdir'

# platform, version (codename, not numeric)
class BuildPEInstallerPackage < TaskHelper
  def get_local_sha(dir)
    Dir.chdir dir do
      output, status = Open3.capture2e('git rev-parse --verify HEAD')
      raise TaskHelper::Error.new("Unable to get most recent git SHA from local dir #{dir}", 'barr.buildpackages/pe-installer-failed', output) if !status.exitstatus.zero?
      sha = output.strip
    end
  end

  def get_local_pwd(dir)
    Dir.chdir dir do
      Dir.pwd
    end
  end

  def update_component_json(component, sha, pwd)
    component_json = File.read("pe-installer-vanagon/configs/components/#{component}.json")
    component_hash = JSON.parse(component_json)

    component_hash['ref'] = sha
    component_hash['url'] = pwd
    f = File.open("pe-installer-vanagon/configs/components/#{component}.json", 'w+')
    f.write(component_hash.to_json)
    f.close
  end

  def merge_pr(component, pr_num)
    output, status = Open3.capture2e("git clone git@github.com:puppetlabs/#{component}")
    raise TaskHelper::Error.new("Failed to clone puppetlabs repo #{component}", 'barr.buildpackages/pe-installer-failed', output) if !status.exitstatus.zero?

    Dir.chdir component do
      output, status = Open3.capture2e("git fetch origin pull/#{pr_num}/head:merge-pr-local && git checkout merge-pr-local")
      raise TaskHelper::Error.new("Failed to fetch PR number #{pr_num} from puppetlabs/#{component}", 'barr.buildpackages/pe-installer-failed', output) if !status.exitstatus.zero?
    end
  end


  def task(platforms: nil, **kwargs)
    version = kwargs[:version]

    local_components = {}
    component_prs = {}
    kwargs.each do |k,v|
      if k.to_s != 'platforms' && k.to_s != 'version' && !k.to_s.start_with?('_')
        # If key points to a PR, add k:v to PR hash, else add k:v to local components hash
        if k.to_s.end_with?('_pr')
          k = k.to_s.chomp('_pr')
          component_prs[k] = v 
        else
          v = get_local_pwd(v)
          local_components[k] = v
        end
      end
    end
    
    output = ''
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        output, status = Open3.capture2e("git clone -b #{version} --single-branch git@github.com:puppetlabs/pe-installer-vanagon.git")
        raise TaskHelper::Error.new("Unable to clone pe-installer-vanagon #{dir}", 'barr.buildpackages/pe-installer-failed', output) if !status.exitstatus.zero?

        local_components.each do |comp, path|
          sha = get_local_sha(path)
          update_component_json(comp, sha, path)
        end

        component_prs.each do |comp, pr_num|
          merge_pr(comp, pr_num)
          path = get_local_pwd(comp)
          sha = get_local_sha(path)
          update_component_json(comp, sha, path)
        end

        Dir.chdir 'pe-installer-vanagon' do
          output, status = Open3.capture2e('bundle install')
          raise TaskHelper::Error.new("Failed to install gem dependencies for pe-installer-vanagon", 'barr.buildpackages/pe-installer-failed', output) if !status.exitstatus.zero?

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

BuildPEInstallerPackage.run if __FILE__ == $PROGRAM_NAME
