#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require_relative '../lib/build_vanagon_package_helpers.rb'
require_relative '../lib/pe_version_helpers.rb'
require 'json'
require 'open3'
require 'tmpdir'

class BuildVanagonPackage < TaskHelper
  # This method is for handling the edge cases for a couple of vanagon repos
    # where the component.json file names do not match the names of the puppetlabs repos
    # that they are associated with. Since the components start as the repo names, this method
    # changes them so that they match the actual vanagon component names
  def handle_component_name_transformations(vanagon_project, component)
    case vanagon_project
    when 'pe-backup-tools'
      # The json file is named rubygem-pe_backup_tools, so we need to handle that component name here
      component = 'rubygem-' + component.gsub('-', '_') if component = 'pe-backup-tools'
    when 'pe-tasks'
      # The pe-tasks-vanagon components (mostly) have 'puppetlabs-' removed from the start of the repo names
      # This case handles that, and transforms the repo names to drop 'puppetlabs-'
        # Except for the one case where 'puppetlabs-' stays
        # Because of course that case exists
      component = component.chomp('puppetlabs-') unless comp =~ /cd4pe/
    end
    component
  end

  def task(platforms: nil, local_vanagon_components: nil, vanagon_component_prs: nil, **kwargs)
    # If the version is passed in as 'x.y' or 'x.y.z', make sure it's git friendly (i.e. 2018.1.x instead of 2018.1 or 2018.1.7)
    # If version is a codename, it remains a codename
    version = PEVersion.convert_to_git_version(kwargs[:version])
    vanagon_project = kwargs[:vanagon_project]
    package_name = vanagon_project.chomp('-vanagon')

    # Grab pwd for local components
    local_vanagon_components.each do |k, v|
      if v
        v = BuildVanagonPackageHelpers::get_local_pwd(v)
        local_vanagon_components[k] = v
      else 
        # Remove any entries witih an undefined value
        local_vanagon_components.delete(k)
      end
    end if local_vanagon_components

    vanagon_component_prs.each do |k, v|
      if !v
        # Remove any entries witih an undefined value
        vanagon_component_prs.delete(k)
      end
    end if vanagon_component_prs


    output = ''
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        output, status = Open3.capture2e("git clone git@github.com:puppetlabs/#{vanagon_project}.git")
        raise TaskHelper::Error.new("Unable to clone #{vanagon_project} #{dir}", 'barr.buildpackages/build-vanagon-failed', output) if !status.exitstatus.zero?

        Dir.chdir vanagon_project do
          BuildVanagonPackageHelpers::switch_to_correct_git_branch(version, vanagon_project)
        end

        local_vanagon_components.each do |comp, path|
          sha = BuildVanagonPackageHelpers::get_local_sha(path)

          # pe-tasks and pe-backup-tools both have edge cases where the repository name does not match the vanagon component name
          comp = handle_component_name_transformations(vanagon_project, comp) if vanagon_project == 'pe-tasks' || vanagon_project == 'pe-backup-tools'

          BuildVanagonPackageHelpers::update_component_json(vanagon_project, comp, sha, path)
        end if local_vanagon_components

        vanagon_component_prs.each do |comp, pr_num|
          BuildVanagonPackageHelpers::merge_pr(comp, pr_num, version)
          path = BuildVanagonPackageHelpers::get_local_pwd(comp)
          sha = BuildVanagonPackageHelpers::get_local_sha(path)

          # pe-tasks and pe-backup-tools both have edge cases where the repository name does not match the vanagon component name
          comp = handle_component_name_transformations(vanagon_project, comp) if vanagon_project == 'pe-tasks' || vanagon_project == 'pe-backup-tools'

          BuildVanagonPackageHelpers::update_component_json(vanagon_project, comp, sha, path)
        end if vanagon_component_prs

        Dir.chdir vanagon_project do
          output, status = Open3.capture2e('bundle install')
          raise TaskHelper::Error.new("Failed to install gem dependencies for #{vanagon_project}", 'barr.buildpackages/build-vanagon-failed', output) if !status.exitstatus.zero?

          platforms.each do |platform|
            output, status = Open3.capture2e("bundle exec build #{package_name} #{platform}")
            raise TaskHelper::Error.new("Unable to build #{package_name} package for platform #{platform}", 'barr.buildpackages/build-vanagon-failed', output) if !status.exitstatus.zero?
            package = Open3.capture2e("find output -name '#{package_name}*'")[0].strip
            output, _ = Open3.capture2e("mv #{package} /tmp/localbuilder/packages")
          end
        end
      end
    end

    result = { _output: output }
    result.to_json
  end
end

BuildVanagonPackage.run if __FILE__ == $PROGRAM_NAME
