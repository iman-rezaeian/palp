#!/bin/bash

make_target="@@MAKE_TARGET@@"
extra_args="@@EXTRA_ARGS@@"
git_args="@@GIT_ARGS@@"



run_in_venv(){
  pip install pipenv
  pipenv --python 3.11
  pipenv run ./deploy.sh
}

validate_command_status(){
  if [[ $1 -ne 0 ]];then
   echo "deployment failed"
   exit 1
  fi
};



INVENV=$(python --version | grep -E "3.11|3.10|3.9")

if [[ -z "${INVENV}" ]]; then
  run_in_venv $?
else
  echo "installing deployment requirements"
  pip install -r deploy_requirements.txt --index-url https://artifactory.foc.zone/artifactory/api/pypi/rdf-pypi-private/simple --extra-index-url https://artifactory.foc.zone/artifactory/api/pypi/pypi-remote/simple
  pip freeze
  env
  python --version
  pwd
  ls
  unzip -o deployment.zip  # Updated to -o for overwrite
  #circleci-aws-mlops --pipeline  rcd-GeneralizationDemo deploy_pipeline --base-dir . -project-uri ${VCS_SSH_URL}
  echo "---- deploying update ----"
  echo "make $make_target $extra_args $git_args"
  make $make_target $extra_args $git_args
  validate_command_status $?

  echo "---- deployment finished ----"
fi
