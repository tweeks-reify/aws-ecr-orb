#!/bin/bash
ACCOUNT_URL=$(eval echo "\$$PARAM_ACCOUNT_URL")
TAG=$(eval echo "$PARAM_TAG")
SKIP_WHEN_TAGS_EXIST=$(eval echo "$PARAM_SKIP_WHEN_TAGS_EXIST")
REPO=$(eval echo "$PARAM_REPO")
EXTRA_BUILD_ARGS=$(eval echo "$PARAM_EXTRA_BUILD_ARGS")
FILE_PATH=$(eval echo "$PARAM_PATH")
DOCKERFILE=$(eval echo "$PARAM_DOCKERFILE")
PROFILE_NAME=$(eval echo "$PARAM_PROFILE_NAME")
ACCOUNT_ID=$(eval echo "\$$PARAM_ACCOUNT_ID")
number_of_tags_in_ecr=0
docker_tag_args=""
IFS="," read -ra DOCKER_TAGS <<< "${TAG}"
for tag in "${DOCKER_TAGS[@]}"; do
  if [ "${SKIP_WHEN_TAGS_EXIST}" = "1" ]; then
      docker_tag_exists_in_ecr=$(aws ecr describe-images --profile "${PROFILE_NAME}" --registry-id "${ACCOUNT_ID}" --repository-name "${REPO}" --query "contains(imageDetails[].imageTags[], '${tag}')")
    if [ "${docker_tag_exists_in_ecr}" = "1" ]; then
      docker pull "${ACCOUNT_URL}/${REPO}:${tag}"
      let "number_of_tags_in_ecr+=1"
    fi
  fi
  docker_tag_args="${docker_tag_args} -t ${ACCOUNT_URL}/${REPO}:${tag}"
done
if [ "${SKIP_WHEN_TAGS_EXIST}" = "0" ] || [ "${SKIP_WHEN_TAGS_EXIST}" = "1" -a ${number_of_tags_in_ecr} -lt ${#DOCKER_TAGS[@]} ]; then
    if [ -n "$EXTRA_BUILD_ARGS" ]; then
       set -- "$@" "${EXTRA_BUILD_ARGS}"
     fi
    set -- "$@" -f "${FILE_PATH}"/"${DOCKERFILE}" ${docker_tag_args} "${FILE_PATH}"
    docker build "$@" 
fi
