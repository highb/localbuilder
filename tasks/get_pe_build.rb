#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require_relative '../lib/pe_version_helpers.rb'
require 'open3'
require 'tmpdir'

class GetPEBuild < TaskHelper
  def get_latest_rc(pe_family)
    output, status = Open3.capture2e("curl -s enterprise.delivery.puppetlabs.net/#{pe_family}/ci-ready/LATEST")
    raise TaskHelper::Error.new("Failed to get most recent PE rc version based on PE Family #{pe_family}", 'barr.buildpackages/get-build-failed', output) if status.exitstatus != 0
    version = output.strip
  end

  def generate_curl_url(version, build_type, platform)
    url_base = 'enterprise.delivery.puppetlabs.net'
    pe_family = PEVersion::get_pe_family(version) 

    case build_type 
    when 'release'
      url = url_base + '/' + pe_family + "/release/ci-ready/puppet-enterprise-#{version}-#{platform}.tar" 
    when 'rc'
      url = url_base + '/' + pe_family + "/ci-ready/puppet-enterprise-#{version}-#{platform}.tar"
    when 'family'
      version = self.get_latest_rc(pe_family)
      url = url_base + '/' + pe_family + "/ci-ready/puppet-enterprise-#{version}-#{platform}.tar"
    end
  end

  def task(version:, **kwargs)
    # In case version is passed as a codename, convert to a generic version but remove trailing '.x'
    version = PEVersion::convert_codename_to_version(version).chomp('.x') if PEVersion::codenames.include?(version)
    
    # Default to el-7 if no platform value is given
    kwargs[:platform] ? platform = kwargs[:platform] : platform = 'el-7-x86_64'
    
    # Build types: rc (for a specific rc/sha version of PE), release (for an x.y.z release build), and family (for a generic x.y PE family version)
    build_type = PEVersion::get_build_type_from_version(version)
    url = generate_curl_url(version, build_type, platform)

    tarball_name = ''
    Dir.chdir '/Users/barr.iserloth/Desktop' do
      output, status = Open3.capture2e("curl --fail -Os #{url}")
      raise TaskHelper::Error.new("Failed to pull down PE tarball from url #{url}", 'barr.buildpackages/get-build-failed', output) if !status.exitstatus.zero?
      tarball_name = Open3.capture2e("ls | grep 'puppet-enterprise'")[0].strip
    end

    result = { tarball_name: tarball_name }
    result.to_json
  end
end

GetPEBuild.run if __FILE__ == $PROGRAM_NAME
