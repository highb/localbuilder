#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require_relative '../lib/build_vanagon_package_helpers.rb'
require_relative '../lib/pe_version_helpers.rb'
require 'json'
require 'open3'
require 'tmpdir'

class BuildPEModulesPackage < TaskHelper
  def task(platforms: nil, local_pe_modules_components: nil, pe_modules_component_prs: nil, **kwargs)
    # If the version is passed in as 'x.y' or 'x.y.z', make sure it's git friendly (i.e. 2018.1.x instead of 2018.1 or 2018.1.7)
    # If version is a codename, it remains a codename
    version = PEVersion.convert_to_git_version(kwargs[:version])

    # Grab pwd for local components
    local_pe_modules_components.each do |k, v|
      if v
        v = BuildVanagonPackage::get_local_pwd(v)
        local_pe_modules_components[k] = v
      else 
        local_pe_modules_components.delete(k)
      end
    end

    output = ''
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        output, status = Open3.capture2e("git clone git@github.com:puppetlabs/pe-modules-vanagon.git")
        raise TaskHelper::Error.new("Unable to clone pe-modules-vanagon #{dir}", 'barr.buildpackages/pe-modules-failed', output) if !status.exitstatus.zero?

        Dir.chdir 'pe-modules-vanagon' do
          BuildVanagonPackage::switch_to_correct_git_branch(version, 'pe-modules-vanagon')
        end

        local_pe_modules_components.each do |comp, path|
          sha = BuildVanagonPackage::get_local_sha(path)
          BuildVanagonPackage::update_component_json('pe-modules-vanagon', comp, sha, path)
        end if local_pe_modules_components

        pe_modules_component_prs.each do |comp, pr_num|
          BuildVanagonPackage::merge_pr(comp, pr_num, version)
          path = BuildVanagonPackage::get_local_pwd(comp)
          sha = BuildVanagonPackage::get_local_sha(path)
          BuildVanagonPackage::update_component_json('pe-modules-vanagon', comp, sha, path)
        end if pe_modules_component_prs

        Dir.chdir 'pe-modules-vanagon' do
          output, status = Open3.capture2e('bundle install')
          raise TaskHelper::Error.new("Failed to install gem dependencies for pe-modules-vanagon", 'barr.buildpackages/pe-modules-failed', output) if !status.exitstatus.zero?

          platforms.each do |platform|
            output, status = Open3.capture2e("bundle exec build pe-modules #{platform}")
            raise TaskHelper::Error.new("Unable to build pe-modules package for platform #{platform}", 'barr.buildpackages/pe-modules-failed', output) if !status.exitstatus.zero?
            file = Open3.capture2e("find output -name 'pe-modules*'")[0].strip
            output, _ = Open3.capture2e("mv #{file} /tmp/localbuilder/packages")
          end
        end
      end
    end

    result = { _output: output }
    result.to_json
  end
end

BuildPEModulesPackage.run if __FILE__ == $PROGRAM_NAME
