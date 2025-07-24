#!/bin/bash
# set -eo pipefail

if [[ $# -lt 2 ]];then
   echo "This script takes exactly 2 arguments, the environment and the code module name!!!"
   exit 1
fi

deployment_env=$1
module_name=$2
accepted_arg_list=("dev beta prod beta_prod")

if [[ " ${accepted_arg_list[@]} " =~ " ${deployment_env} " ]];then
  echo "argument validated"
else
  echo "only accepted values are dev beta, and prod"
  exit 1
fi

#function to module code
package_pipeline(){
  echo "Copying project code ..."
  cp -R src .bin/
  cp -R models .bin/
  cp -R notebooks .bin/
  cp -R deployment .bin/
  echo "Copying project git info ..."
  cp -R .git/. .bin/.git
  cp Makefile .bin/
  cp *.txt .bin/
  cd .bin
  zip -r ../publish/deployment.zip .
  cd ..
};


mkdir -p publish
mkdir -p .bin
pipeline_updates="False"

if [[ "$deployment_env" == "beta" || "$deployment_env" == "prod" ]];then
  echo "Testing diffs"
  pipeline_updates="True"
  source ./git_get_last_commits.sh
  for record in $(echo "$git_diff_result" | awk '{print $1}')
  do
    echo "$record"
    if [[  "$record" == "deployment"*  || "$record" == "$module_name" ]];then
      echo "pipeline updates"
      pipeline_updates="True"
    fi
 done
 if [[ $pipeline_updates == "True" ]];then
    package_pipeline
 fi
fi