# Tag-Version v1
Provides automated versioning of your commits using git tags each time your CI/CD workflow runs.
## Features
* Generate a new revision based on the last version released and the branch currently checked out
* Create a new tag for this revision
* Maintain a CHANGELOG of the commits between each version
## Version Format
\<major\>.\<minor\>.\<build\>\[.\<prerelease-tag\>\]
### Examples
* 3.2.15
* 1.0.3.TEST
* 2.1.5.DEVELOP
# Usage
See [action.yml](https://github.com/juliansangillo/tag-version/blob/master/action.yml)
## Pushing new build
Tag-Version will always use the latest commit that was pushed to determine how to version this new release, no matter how many commits were made locally. A standard commit message will increment your version's build number.
### Commit
```
git commit -m "Add file foo.txt"
```
### Example
1.0.7 -> 1.0.8
## Pushing new minor revision
A commit message with the substring '#minor' will increment your version's minor revision. This string could exist anywhere in your message and it will still be read.
### Commit
```
git commit -m "Update dependencies #minor"
```
### Example
2.3.5 -> 2.4.0
## Pushing new major revision
A commit message with the substring '#major' will increment your version's major revision. This string could exist anywhere in your message and it will still be read.
### Commit
```
git commit -m "Add fancy new UI #major"
```
### Example
1.5.10 -> 2.0.0
## Prerelease
The prerelease tag is a string of capitalized ASCII characters marking the version as a non-production branch (example: 1.0.0.DEVELOP). Running this action on your dev or test branches will append the name of the branch in all caps to the end of the version to identify those releases as unstable. Your stable, production versions won't have a prerelease appended at the end.
### What about pull requests?
When you merge a pull request (or push into test or production branches), the version is not incremented as you are not introducing a new instance of your project. Instead, you are promoting an already existing version to a higher branch. The only thing that changes in this case is the prerelease tag.
### local -> develop
2.1.1.DEVELOP
### develop -> test
2.1.1.TEST
### test -> master
2.1.1
## Maintaining a CHANGELOG
On top of the annotated tags that Tag-Version creates, it also creates and updates a lightweight tag "latest" which bookmarks the latest commit to get tagged by this action. There are two purposes to this. First, querying the latest tag is how Tag-Version gets the last known version of the project. Second, Tag-Version uses "latest" to get all commits greater than "latest" up until now. These commits then get filtered based on the commit syntax and added as entries to a CHANGELOG.md file. This allows you to keep track of the changes with each revision.
### Commit syntax
For commits to be picked up for the CHANGELOG, they must adhere to one of the following patterns:
* Add *
* Update *
* Change *
* Remove *
* Replace *
* Revert *
* Fix *
### 
Capitalization is irrelevant here ("Add", "add", and "ADD" are all interpreted the same). This also does not count Jira keys, #minor, or #major flags. These are ignored, so having a Jira key or one of the flags at the beginning of the message won't interfere with the CHANGELOG. The following examples are all valid commits for the CHANGELOG.
### Examples
* Fix null pointer exception
* Add shopping page #minor
* JIRA-1234 Update drop-down menu
* JIRA-5872 Fix security vulnerability #major
### !Impotant Note!
The checkout action must be set to fetch the whole git history in order for a proper CHANGELOG to be generated. Set "fetch-depth: 0" in checkout action.
## Inputs
* **production-branch**: The branch to use for stable releases in production. Default is master
* **test-branch**: The branch to use for test deployments. Default is test
* **dev-branch**: The branch to use for dev deployments. Default is develop
## Ouputs
* **revision**: The new version that was created and tagged in the format of \<major\>.\<minor\>.\<build\>\[.\<pre-release-tag\>\]
* **is-prerelease**: Is true if this is a release into a non-production environment and indicates the build may be unstable. Returns false otherwise.
## Error Codes
* **32**: A 'latest' tag exists without a corresponding annotated tag marking the last known version on the same commit.
* **64**: A 'latest' tag doesn't exist when pulling commits into test or production.
* **128**: Tag version is being attempted on neither the production, test, or dev branches. Branch is unknown.
## Setup
```yml
- name: Checkout  
  uses: actions/checkout@v2  
  with:  
      fetch-depth: 0  
      
- name: Version  
  id: version  
  uses: juliansangillo/tag-version@v1  
  with:  
      production-branch: master  
      test-branch: test  
      dev-branch: develop  
```
