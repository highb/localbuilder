require 'json'
require 'open3'
require_relative './pe_version_helpers.rb'

class BuildVanagonPackage
  def self.get_local_sha(dir)
    Dir.chdir dir do
      output, status = Open3.capture2e('git rev-parse --verify HEAD')
      raise TaskHelper::Error.new("Unable to get most recent git SHA from local dir #{dir}", 'barr.buildpackages/build-package-failed', output) if !status.exitstatus.zero?
      sha = output.strip
    end
  end

  def self.get_local_pwd(dir)
    Dir.chdir dir do
      Dir.pwd
    end
  end

  def self.update_component_json(vanagon_repo, component, sha, pwd)
    component_json = File.read("#{vanagon_repo}/configs/components/#{component}.json")
    component_hash = JSON.parse(component_json)

    component_hash['ref'] = sha
    component_hash['url'] = pwd
    f = File.open("#{vanagon_repo}/configs/components/#{component}.json", 'w+')
    f.write(component_hash.to_json)
    f.close
  end

  def self.get_branch
    # Double backslash to tell Ruby that I actually want that '*' to be escaped in the command line call
    branch = Open3.capture2e("git branch | grep \\* | cut -d ' ' -f2")[0].strip
  end

  def self.switch_to_correct_git_branch(version, component)
    branch = self.get_branch
    new_branch = PEVersion::match_version_to_git_branch(branch, version)

    output, status = Open3.capture2e("git checkout #{new_branch}") if new_branch
    raise TaskHelper::Error.new("Failed to checkout branch #{new_branch} in puppetlabs/#{component}", 'barr.buildpackages/build-package-failed', output) if status && !status.exitstatus.zero?
  end

  def self.merge_pr(component, pr_num, version)
    output, status = Open3.capture2e("git clone git@github.com:puppetlabs/#{component}")
    raise TaskHelper::Error.new("Failed to clone puppetlabs repo #{component}", 'barr.buildpackages/build-package-failed', output) if !status.exitstatus.zero?

    Dir.chdir component do
      # change to correct repo branch if the default does not match the given version
      # if the repo only has a master branch/the default branch is a version older than 2017.1, we don't switch branches
      # if the branch is already on the given version, don't switch branches
      self.switch_to_correct_git_branch(version, component)
      
      output, status = Open3.capture2e("git fetch origin pull/#{pr_num}/head:merge-pr-local && git checkout merge-pr-local")
      raise TaskHelper::Error.new("Failed to fetch PR number #{pr_num} from puppetlabs/#{component}", 'barr.buildpackages/build-package-failed', output) if !status.exitstatus.zero?
    end
  end
end
