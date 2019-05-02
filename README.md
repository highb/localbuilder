# localbuilder - Make Local PE Dev Builds

This tool is for creating local dev builds of Puppet Enterprise using Bolt, where the custom build can be based on any changes to the components of the following vanagon packages:
* pe-modules-vanagon component repos:
  * puppet-enterprise-modules
  * puppetlabs-pe_r10k
  * puppetlabs-pe_razor
  * puppetlabs-pe_support_script
* pe-installer-vanagon component repos:
  * enterprise_tasks
  * higgs
* pe-backup-tools-vanagon component repos:
  * pe-backup-tools
* pe-tasks-vanagon component repos:
  * puppetlabs-facter_task
  * puppetlabs-package
  * puppetlabs-puppet_conf
  * puppetlabs-pe_installer_cd4pe
  * puppetlabs-service
  
This tool can be used to build packages based on locally committed changes to one of the above repositories, or based on a list of PRs to one of the repos above. If both local changes and PR changes are passed in for the same repo, they fight to the death and currently the PR changes will win every time and overwrite any of the locally passed-in changes. So there's room for improvement, is what I'm saying.

This is set up like a Bolt module, so it may need to get put into a boltdir (in a `site-modules/localbuilder/` directory, or listed as a local module in a Puppetfile and put into `<boltdir>/modules/localbuilder`) to actually allow it to work properly.

## Pre-requisites

To successfully use this module, there are a few requirements:
* Bolt
* An SSH key that can pull puppetlabs/ repos
* A valid VMPooler token (related: the ability to actually connect to VMPooler)

## Example usage

Currently, the only required parameter is `version`, which can be set to a codename (`irving`), a PE family (`2019.1`, which will pull the latest rc from Kearney), a release version (`2019.0.2`) or a specific rc (`2018.1.9-rc0-20-ge8eb489`). The `platform` parameter defaults to `el-7-x86_64`. Local changes can be passed in based on the parameters that are visible at the top of `plans/build_pe.pp`, but in short the parameter names are the names of the repos containing the changes (without "puppetlabs-", if the repo name has it), using only underscores since Bolt does not like parameter names that have hyphens. To pass in PR changes for a repo, use the same parameter name as for local changes, with `_pr` appended to the end, and pass in the integer number(s) of the PR(s).

Paths to local repos can be passed in as absolute paths or relative paths from wherever you're calling the command.

For the latest Irving rc build using local puppet-enterprise-modules changes and an enterprise_tasks PR (specifically, PR #42):

`bolt plan run localbuilder::build_pe platform=el-7-x86_64 version=irving puppet_enterprise_modules=<some-path-to>/puppet-enterprise-modules enterprise_tasks_pr=42`

For the latest Kearney build with local changes for the puppetlabs-pe_r10k repo
`bolt plan run localbuilder::build_pe platform=el-7-x86_64 version=2019.1 pe_r10k=<some-path-to>/puppetlabs-pe_r10k`

You can also pass in the `output_dir` parameter to define where you want your PE build to show up. If you don't pass in anything at all, the build will be placed into the `localbuilder/builds` directory.

## Limitations

* Currently (5/1/2019), this only works for creating PE builds for el-7-x86_64
* Can only be used to get builds of version PE 2017.1 or newer
* Can only build vanagon packages, so this can't make builds based on changes to any of PE's ezbake packages
  * This is a feature I'd like to add, but I have to actually learn how ezbake works first
