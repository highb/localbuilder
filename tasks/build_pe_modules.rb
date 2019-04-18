#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require_relative '../files/build_vanagon_package_helpers.rb'
require_relative '../files/pe_version_helpers.rb'
require 'json'
require 'open3'
require 'tmpdir'

# platform, version (numeric, not codename)
class BuildPEModulesPackage < TaskHelper
  def task(platforms: nil, **kwargs)
    # If the version is passed in as 'x.y' or 'x.y.z', make sure it's git friendly (i.e. 2018.1.x instead of 2018.1 or 2018.1.7)
    version = PEVersion.convert_to_git_version(kwargs[:version])

    local_components = {}
    component_prs = {}
    kwargs.each do |k,v|
      k = k.to_s
      if k != 'platforms' && k != 'version' && !k.start_with?('_')
        # update key to match module repo names for modules not in puppet-enterprise-modules
        if k =~ /puppet_enterprise_modules/
          # ugly underscore/hyphen mangling since Bolt does not allow params with hyphens
          k = k.gsub('_', '-')
          k = k.chomp('-pr').concat('_pr') if k.end_with?('-pr')
        else
          k = 'puppetlabs-' + k
        end
        if k.end_with?('_pr')
          k = k.chomp('_pr')
          component_prs[k] = v 
        else
          v = BuildVanagonPackage::get_local_pwd(v)
          local_components[k] = v
        end
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

        local_components.each do |comp, path|
          sha = BuildVanagonPackage::get_local_sha(path)
          BuildVanagonPackage::update_component_json('pe-modules-vanagon', comp, sha, path)
        end

        component_prs.each do |comp, pr_num|
          BuildVanagonPackage::merge_pr(comp, pr_num, version)
          path = BuildVanagonPackage::get_local_pwd(comp)
          sha = BuildVanagonPackage::get_local_sha(path)
          BuildVanagonPackage::update_component_json('pe-modules-vanagon', comp, sha, path)
        end

        Dir.chdir 'pe-modules-vanagon' do
          output, status = Open3.capture2e('bundle install')
          raise TaskHelper::Error.new("Failed to install gem dependencies for pe-modules-vanagon", 'barr.buildpackages/pe-modules-failed', output) if !status.exitstatus.zero?

          platforms.each do |platform|
            output, status = Open3.capture2e("bundle exec build pe-modules #{platform}")
            raise TaskHelper::Error.new("Unable to build pe-modules package for platform #{platform}", 'barr.buildpackages/pe-modules-failed', output) if !status.exitstatus.zero?
            output, status = Open3.capture2e("mv output/ ~/Desktop/pe-modules-package")
          end
        end
      end
    end

    result = { _output: output }
    result.to_json
  end
end

BuildPEModulesPackage.run if __FILE__ == $PROGRAM_NAME
