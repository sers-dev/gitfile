# Gitfile

Gitfile is a MIT-Licensed Bash-script written in less than 100 lines to manage git repositores. 

Originally written as a replacement for terraform module managers like https://github.com/coretech/terrafile and https://github.com/devopsmakers/xterrafile 

Main reasons for the rewrite were:
 - both written in Go with dependencies for a job that can be done in bash in less than 100 lines
 - both always delete and re-clone the repository on execution
 - both always delete the path recursively (they seriously delete your working directory if it's part of the path) which makes it impossible for directory structures like:
   ```shell script
   workspace
   ├── moduleA
   │   ├── main.tf
   ├── moduleB
   │   ├── main.tf
   |   ├── moduleA.tf
   ├── moduleC
   │   ├── main.tf
   │   ├── moduleA.tf
   │   ├── moduleB.tf
   ```

`Gitfile` ended up beeing a more general approach that enables git management in general

 
## Features
 - doesn't delete your existing directories
 - clones repository only if it hasn't been cloned already
   - incremental changes are retrieved with fetch/checkout/pull
 - fetch/checkout/pull are only executed if there are no changes in the local repository
 - updates remote ULR if it changes (i.e. repo moved from github to self hosted domain)
 
## Usage in automation

In most cases you should be able to use the gitfile locally and in automation in exactly the same way.
Nonetheless there are some use cases where you might prefer to Download your repository in automation using HTTPS instead of SSH or vice versa. 
Simply re-configure git in your pipeline to switch from http cloning to ssh cloning:
```shell script
git config --global url.ssh://git@github.com/.insteadOf https://github.com/
```

## Install

```shell script
git clone https://github.com/sers-dev/gitfile.git
cd gitfile
make install
```

in docker:
```shell script
# https://quay.io/repository/sers.dev/gitfile
docker run quay.io/sers.dev/gitfile:latest
```

or alternatively:
```shell script
curl -L https://raw.githubusercontent.com/sers-dev/gitfile/main/gitfile.sh > /usr/local/bin/gitfile
```

#### dependencies:
 - git
 - openssh-client 
 - make (for test/install)
  

## Use

#### Command overview

```shell script
#quick-start
cd ~/workspace/github/sers-dev/gitfile/
gitfile
```

```shell script
#print help text
gitfile -h #--help
#path/filename to parse as gitfile (default: ./.gitfile)
gitfile -f /path/to/gitfile #--gitfile ->
#path to store repos without explicit `path` (default: ./)
gitfile -p /default/clone/path #--default-clone-path  
```

#### .gitfile format

This is only a YAML-like format! gitfile does not use a full blown yaml parser, but instead only implemented the minimal requirements through some shell commands. 
Feel free to create an Issue/Pull request if you find a problem with the parsing (or anything else of course).

```yaml
#required: repo will be cloned into dir with this name
gitfile:
    #required: clone URL (can be either http(s) or ssh)
    source: "https://github.com/sers-dev/gitfile.git"
    #optional: path to clone the repository into (default taken from gitfile command)
    #relative path values are always relative to the path of the .gitfile
    path: ~/workspace/github/sers-dev/
    #optional: version to checkout (defaults to main)
    #tags, branch names and commit hashes are all valid values
    #if you can run `git checkout $VERSION` it's valid
    version: main
```

#### Release Cycle:
`gitfile.sh` content changes on main will always trigger a new release; if it's good enough to be merged, it's good enough to be released.
