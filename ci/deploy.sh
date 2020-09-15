#! /bin/sh -e
#
# deploy.sh
#
# Distributed under terms of the MIT license.
#

branchName=${BRANCH_NAME}

if [ "$branchName" != "develop" ]; then

  echo "Cannot proceed in this step because you are currently not in develop branch........switch to develop and try again"
  exit 1

fi

echo " POM VERSION is $VERSION"
echo " ARTIFACT_NAME is $ARTIFACT_NAME"

getAccessToken() {
  accessTokenResponse=$(curl -v -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -X POST -d '{"username":"sachitti","password":"Sachitti@123"}' https://anypoint.mulesoft.com/accounts/login)

  if [ "$accessTokenResponse" != "200" ]; then
    echo "access token not found......something is wrong with the url.......please try again later"
    exit 1
  else
    accessToken=$(curl -v -H "Content-Type: application/json" -X POST -d '{"username":"sachitti","password":"Sachitti@123"}' https://anypoint.mulesoft.com/accounts/login | jq .access_token)
    accessToken=$(echo "$accessToken" | tr -d '"' | tr -d ' ')
  fi
}

getOriginId() {
  orgIdResponse=$(curl -v -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $1" https://anypoint.mulesoft.com/accounts/api/me)
  if [ "$orgIdResponse" != "200" ]; then
    echo "organization id not found......something is wrong with the url.......please try again later"
    exit 1
  else
    orgId=$(curl -v -H "Authorization: Bearer $1" https://anypoint.mulesoft.com/accounts/api/me | jq .user.organizationId)
    orgId=$(echo "$orgId" | tr -d '"' | tr -d ' ')
  fi
}

getEnvId() {
  envIdResponse=$(
    curl -v -s -o /dev/null -w "%{http_code}" --location --request GET "https://anypoint.mulesoft.com/accounts/api/organizations/$1/environments" \
    --header "Authorization: Bearer $2"
  )

  if [ "$envIdResponse" != "200" ]; then
    echo "environment id not found......something is wrong with the url.......please try again later"
    exit 1
  else
    envId=$(
      curl -v --location --request GET "https://anypoint.mulesoft.com/accounts/api/organizations/$1/environments" \
      --header "Authorization: Bearer $2" | jq -r '.data[] | select(.type=="sandbox")| .id'
    )
  fi
}

getMuleApplicationInfo() {
  application_json=$(
    curl -v --location --request GET "https://anypoint.mulesoft.com/hybrid/api/v1/applications?targetId=$5" \
    --header "X-ANYPNT-ENV-ID: $1" \
    --header "X-ANYPNT-ORG-ID: $2" \
    --header "Authorization: Bearer $3" | jq --arg inputArtifactName "$4" -r '.data[] | select(.artifact.name == $inputArtifactName) | {applicationid:.id,artifactname:.artifact.name,fileVersion:.artifact.fileName,applicationstatus:.started}'
  )
}
getTargetId() {
  targetId=$(
    curl -v -X GET "https://anypoint.mulesoft.com/hybrid/api/v1/servers" \
    --header "X-ANYPNT-ENV-ID: $1" \
    --header "X-ANYPNT-ORG-ID: $2" \
    --header "authorization: Bearer $3" | jq -r '.data[] | select(.name == "LLA-ESB-DEV") | .id'
  )
  echo "targetId is $targetId"
}

deployTheJarToMule() {
  operation="PATCH"
  if [ "$7" == "true" ]; then
    operation="POST"
  fi

  echo "Operation to be performed = $operation"

  patch_status_json=$(
    curl -v --location --request $operation "https://anypoint.mulesoft.com/hybrid/api/v1/applications/$application_id" \
    --header "x-anypnt-env-id: $1" \
    --header "x-anypnt-org-id: $2" \
    --header 'Content-Type: multipart/form-data' \
    --header "Authorization: Bearer $3" \
    --form "artifactName=$4" \
    --form "targetId=$5" \
	--form "$8" \
    --form "file=@ $6" | jq -r '.data | {desiredStatus:.desiredStatus,lastReportedStatus:.lastReportedStatus,started:.started}'
  )
}

getAccessToken                                                           #getting the access token here

getOriginId "$accessToken"                                               #getting the org id here

getEnvId "$orgId" "$accessToken"                                         #getting the env id here

getTargetId "$envId" "$orgId" "$accessToken"

getMuleApplicationInfo "$envId" "$orgId" "$accessToken" "$ARTIFACT_NAME" "$targetId" #calling the list of application info

getProperty=$(echo "$(curl "http://admin:admin123@54.76.233.166:8082/projects/LLAESB/repos/environment_pipeline/browse/customer-management-biz/customer-management-biz-dev.properties?raw")")

echo "$getProperty"

application_id=$(echo "$application_json" | jq -r '.applicationid')
applicationName=$(echo "$application_json" | jq -r '.artifactname')


createApplication="false"
if [ "$application_id" == "" ]; then
  echo "missing application_id"
  createApplication="true"
else
  echo "application_id is present"
  createApplication="false"
fi

echo "targetId from servers is $targetId"

cd "${WORKSPACE}"/target
jarName+=$ARTIFACT_NAME
jarName+="_"$VERSION
jarName+="_"$PACKAGING
jarName+=".jar"

echo "jarName is $jarName"

mv "$ARTIFACT_NAME"-"$VERSION"-"$PACKAGING".jar $jarName

newJarFile=${WORKSPACE}/target/$jarName
echo "JarFile to Deploy is $newJarFile"

deployTheJarToMule "$envId" "$orgId" "$accessToken" "$ARTIFACT_NAME" "$targetId" "$newJarFile" "$createApplication" "$getProperty"

sleep 30

getMuleApplicationInfo "$envId" "$orgId" "$accessToken" "$ARTIFACT_NAME" "$targetId"#calling the list of application info
