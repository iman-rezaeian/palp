#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_NAME = 221507-palp
PYTHON_VERSION = 3.10
PYTHON_INTERPRETER = python
DEPLOYMENT_TARGET = build
#Taken from PROPEL .rkt.yml
APP_ID = 221507
APP_NAME = 221507-palp
MODULE_NAME = 
HAL_APP_ID = 19904
HAL_ORG_ID = 472
CIRCLE_BUILD_URL = N/A
CIRCLE_REPOSITORY_URL = git@git.rockfin.com:RKT-DI/221507-palp.git


################################################################################
# COMMANDS                                                                      #
#################################################################################


## Install Python Dependencies
.PHONY: requirements
requirements:




## Delete all compiled Python files
.PHONY: clean
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete

## Lint using flake8 and black (use `make format` to do formatting)
.PHONY: lint
lint:
	flake8 mlops_propel_sample
	black --check --config pyproject.toml mlops_propel_sample


## Format source code with black
.PHONY: format
format:
	black --config pyproject.toml mlops_propel_sample


## Set up python interpreter environment
.PHONY: create_environment
create_environment:
	@bash -c "if [ ! -z `which virtualenvwrapper.sh` ]; then source `which virtualenvwrapper.sh`; mkvirtualenv $(PROJECT_NAME) --python=$(PYTHON_INTERPRETER); else mkvirtualenv.bat $(PROJECT_NAME) --python=$(PYTHON_INTERPRETER); fi"
	@echo ">>> New virtualenv created. Activate with:\nworkon $(PROJECT_NAME)"
	pipenv --python $(PYTHON_VERSION)
	@echo ">>> New pipenv created. Activate with:\npipenv shell"


#################################################################################
# PROJECT RULES                                                                 #
#################################################################################


## Make Dataset
.PHONY: data
data: requirements
	$(PYTHON_INTERPRETER) mlops_propel_sample/data/make_dataset.py

#################################################################################
# DEPLOYMENT RULES                                                              #
#################################################################################

## publish pipeline artifacts
.PHONY: publish_pipeline_artifacts
publish_pipeline_artifacts:
	mlops_deploy copy-artifacts --base-dir . --project-uri ${CIRCLE_REPOSITORY_URL} --pipeline ${PIPELINE_NAME} --target ${DEPLOYMENT_TARGET} --module ${MODULE_NAME} 2>&1

.PHONY: publish_pipeline
publish_pipeline:
	mlops_deploy deploy-pipeline --base-dir ./deployment --project-uri ${CIRCLE_REPOSITORY_URL} --region us-east-2 --builder-module ${BUILDER} --hal-id ${HAL_APP_ID} --app-id ${APP_ID} --circleci-url ${CIRCLE_BUILD_URL} 2>&1

.PHONY: publish_run_pipeline
publish_run_pipeline:
	mlops_deploy deploy-pipeline --base-dir ./deployment --project-uri ${CIRCLE_REPOSITORY_URL} --region us-east-2 --builder-module ${BUILDER} --hal-id ${HAL_APP_ID} --app-id ${APP_ID} --circleci-url ${CIRCLE_BUILD_URL} --run 2>&1


.PHONY: publish_new_pipeline
publish_new_pipeline:
	mlops_deploy deploy-pipeline --base-dir ./deployment --project-uri ${CIRCLE_REPOSITORY_URL} --region us-east-2 --builder-module ${BUILDER} --builder-requirements ${DEPENDENCIES} --hal-id ${HAL_APP_ID} --app-id ${APP_ID} --circleci-url ${CIRCLE_BUILD_URL} 2>&1

.PHONY: publish_pipeline_schedule
publish_pipeline_schedule:

	@echo "extra_arg: ${SCHEDULE_EXPRESSION}"
	$(eval processed_se := $(subst ^, ,${SCHEDULE_EXPRESSION}))
	@echo "Processed SCHEDULE_EXPRESSION: ${processed_se}"
	
	mlops_deploy deploy-pipeline-schedule --base-dir ./deployment --project-uri ${CIRCLE_REPOSITORY_URL} --region us-east-2 --pipeline-name ${PIPELINE_NAME} --pipeline-parameters ${PIPELINE_PARAMETERS} --schedule-name ${SCHEDULE_NAME} --schedule-group ${SCHEDULE_GROUP} --state ${STATE} --schedule-expression "${processed_se}" --hal-id ${HAL_APP_ID} --app-id ${APP_ID} --circleci-url ${CIRCLE_BUILD_URL} 2>&1

.PHONY: publish_pipeline_orchestration
publish_pipeline_orchestration:
	mlops_deploy deploy-orchestration --base-dir ./deployment --project-uri ${CIRCLE_REPOSITORY_URL} --region us-east-2 --action-name ${ACTION_NAME} --action-path ${ACTION_PATH} --event-path ${EVENT_PATH} --code-path ${CODE_PATH} --initial-state-path  ${STATE_PATH}  --hal-id ${HAL_APP_ID} --app-id ${APP_ID} --circleci-url ${CIRCLE_BUILD_URL} 2>&1

.PHONY: promote_model_version
promote_model_version:
	mlops_deploy promote-model-version --base-dir ./deployment --project-uri ${CIRCLE_REPOSITORY_URL} --region us-east-2 --model-spec ${MODEL_SPEC} --to-env ${MODEL_ENV} --hal-id ${HAL_APP_ID} --app-id ${APP_ID} --circleci-url ${CIRCLE_BUILD_URL} 2>&1

.PHONY: promote_model_version_no_specs
promote_model_version_no_specs:
	mlops_deploy promote-model-version --base-dir ./deployment --project-uri ${CIRCLE_REPOSITORY_URL} --region us-east-2 --to-env ${MODEL_ENV} --hal-id ${HAL_APP_ID} --app-id ${APP_ID} --circleci-url ${CIRCLE_BUILD_URL} 2>&1


.PHONY: create_ecr_repository
create_ecr_repository:
	mlops_deploy create-ecr-repository --image-spec mlops-test --base-dir ./deployment --project-uri ${CIRCLE_REPOSITORY_URL} --hal-id ${HAL_APP_ID} --app-id ${APP_ID} --circleci-url ${CIRCLE_BUILD_URL} 2>&1

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys; \
lines = '\n'.join([line for line in sys.stdin]); \
matches = re.findall(r'\n## (.*)\n[\s\S]+?\n([a-zA-Z_-]+):', lines); \
print('Available rules:\n'); \
print('\n'.join(['{:25}{}'.format(*reversed(match)) for match in matches]))
endef
export PRINT_HELP_PYSCRIPT

help:
	@python -c "${PRINT_HELP_PYSCRIPT}" < $(MAKEFILE_LIST)