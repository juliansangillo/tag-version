# bump-version
Bumps the version of a project based on latest commit and automatically creates a tag for it. Versions are in the format "\<major\>.\<minor\>.\<build\>[.\<pre-release-tag\>]".  
A commit marked with #major will increment the major revision.  
`git commit -m "Add new major feature #major"`  
This will increment 1.5.3 to 2.0.0.  
A commit marked with #minor will increment the minor revision.  
`git commit -m "Add new minor feature #minor"`  
This will increment 2.3.13 to 2.4.0.  
A commit with no mark will increment the build number.  
`git commit -m "Add new build"`  
This will increment 2.4.4 to 2.4.5  
The optional pre-release-tag is a string of capitalized ASCII characters marking the version as a non-production branch (example: 1.0.0.DEVELOP). In other words, running this action on your dev or test branches will append the name of the branch in all caps to the end of the tag to identify those releases as unstable. Your production tags, however, won't have a prerelease appended at the end.  
New tags starting in the dev branch get a CHANGELOG generated and a README with the updated version. If you wish to make use of the README feature, add the following line to your README and it will be used to output the version with each new run:  
`### Latest Stable`  
Running this action will tag your commits with an annotated tag upon each run to mark the version and will also create a "latest" lightweight tag which bookmarks the latest commit to get tagged by this action. This is required for maintaining the CHANGELOG. For commits to be added to the CHANGELOG, they must begin with one of the following words: Add, Update, Change, Remove, Replace, Revert, or Fix. Capitalization does not matter here. Any commit that doesn't follow this standard won't be added to the CHANGELOG. Also note that this action will disregard the Jira key at the beginning of the commit. If you use Jira keys in your commits, it will still work. Below are all examples of valid commit messages.  
`Fix null pointer exception`  
`Add shopping page #minor`  
`JIRA-1234 Update drop-down menu`  
`JIRA-5872 Fix security vulnerability #major`  
!Impotant Note! The checkout action must be set to fetch the whole git history in order for a proper CHANGELOG to be generated. Set "fetch-depth: 0" in checkout action.
## Inputs
production-branch: The branch to use for stable releases in production. Default is master  
uat-branch: The branch to use for uat deployments. Default is test  
dev-branch: The branch to use for dev deployments. Default is develop
## Ouputs
revision: The new version that was created and tagged in the format of \<major\>.\<minor\>.\<build\>[.\<pre-release-tag\>]  
is-prerelease: Is true if this is a release into a non-production environment and indicates the build may be unstable. Returns false otherwise.
## Error Codes
- 32: A 'latest' tag exists without a corresponding annotated tag marking the last known version on the same commit.  
- 64: A 'latest' tag doesn't exist when pulling commits into UAT or production.  
- 128: Version bump is being attempted on neither the production, UAT, or DEV branches. Branch is unknown.
## Example
```
- name: Version  
  id: version  
  uses: juliansangillo/bump-version  
  with:  
    production-branch: master  
    uat-branch: beta  
    dev-branch: alpha
```
