class PEVersion
  def self.versions
    ['2017.1', '2017.2', '2017.3', '2018.1', '2019.0', '2019.1', '2019.2']
  end

  def self.codenames
    ['flanders', 'glisan', 'hoyt', 'irving', 'johnson', 'kearney', 'lovejoy']
  end

  def self.convert_version_to_codename(version)
    case version
    when /2017.1/
      'flanders'
    when /2017.2/
      'glisan'
    when /2017.3/
      'hoyt'
    when /2018.1/
      'irving'
    when /2019.0/
      'johnson'
    when /2019.1/
      'kearney'
    when /2019.2/
      'lovejoy'
    else
      raise "Version #{version} could not be converted to codename" 
    end
  end

  def self.convert_codename_to_version(codename)
    case codename 
    when /flanders/
      '2017.1.x'
    when /glisan/
      '2017.2.x'
    when /hoyt/
      '2017.3.x'
    when /irving/
      '2018.1.x'
    when /johnson/
      '2019.0.x'
    when /kearney/
      '2019.1.x'
    when /lovejoy/
      '2019.2.x'
    else
      raise "Codename #{codename} could not be converted to version" 
    end
  end

  # Take a starting repo branch and a PE version, return correct repo branch to check out
  # If the branch is 'master' or a version earlier than 2017.1, we do not change branches
  def self.match_version_to_git_branch(branch, version)
    # sanitize branch/version to ensure it'll match with our self.versions array
    branch = branch.chomp('.x') if branch.end_with?('.x')
    version_tmp = if version.end_with?('.x')
                    version.chomp('.x')
                  else
                    version
                  end

    if branch == version
      nil
    elsif self.versions.include?(branch) 
      if self.versions.include?(version_tmp)
        version 
      else
        self.convert_codename_to_version(version)
      end
    elsif self.codenames.include?(branch)
      if self.codenames.include?(version_tmp)
        version 
      else
        self.convert_version_to_codename(version)
      end
    else
      nil 
    end
  end

  # This method is for handling cases when the version is in x.y form
  #   or x.y.z form (where z is a number).
  # Converting the form to end in '.x' allows the version to match
  #   the version branches that we have in git.
  # This means release branches can't ever be used, but for now I'm 
  #   assuming this wouldn't be used with a release branch.
  def self.convert_to_git_version(version)
    if self.codenames.include?(version)
      version
    else
      version_array = version.split('.')
      if version_array.length == 3
        version_array[2] = 'x'
      else
        version_array.push('x')
      end
      version_array.join('.')
    end
  end

  def self.get_pe_family(version)
    # There should only be one match, so just grab the first match from the scan's result array
    version.scan(/\d{4}\.\d{1}/).first
  end


  # This method is for pulling down a build with a specific SHA
  #   from somewhere like http://enterprise.delivery.puppetlabs.net
  def self.get_build_type_from_version(version)
    case version
    when /\d{4}\.\d{1}.\d{1}\-rc.*/
      # Assume version exists, if it doesn't, the curl with this version will error and that's fine
      'rc'
    when /\d{4}\.\d{1}\.\d{1,2}/
      # For specific release version
      'release'
    when /\d{4}\.\d{1}/
      # For PE family with x.y version
      'family'
    else
      raise "The given PE version #{version} is not valid"
    end
  end
end
