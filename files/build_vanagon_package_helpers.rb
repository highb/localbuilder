require 'json'

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

  def self.merge_pr(component, pr_num)
    output, status = Open3.capture2e("git clone git@github.com:puppetlabs/#{component}")
    raise TaskHelper::Error.new("Failed to clone puppetlabs repo #{component}", 'barr.buildpackages/build-package-failed', output) if !status.exitstatus.zero?

    Dir.chdir component do
      output, status = Open3.capture2e("git fetch origin pull/#{pr_num}/head:merge-pr-local && git checkout merge-pr-local")
      raise TaskHelper::Error.new("Failed to fetch PR number #{pr_num} from puppetlabs/#{component}", 'barr.buildpackages/build-package-failed', output) if !status.exitstatus.zero?
    end
  end
end
