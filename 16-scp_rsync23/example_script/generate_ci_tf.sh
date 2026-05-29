TF_ROOT="$1"
TAGS=$2
ENV=$3
TIER=$4
PHI_ENV=$5
if [ "$TF_ROOT" == "./" ]
  then TF_CODE_ROOT="in_root"
  else TF_CODE_ROOT=$TF_ROOT
fi
cat <<EOF >> generated-config.yml

tf_init_$TF_CODE_ROOT:
  stage: terraform_init
  image:
    name: us-docker.pkg.dev/<PROJECT>-$PHI_ENV-<REGISTRY>/builder-terraform:stable
    entrypoint:
     - '/usr/bin/env'
     - 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  script:
    - echo $TF_ROOT
    - cd $TF_ROOT
    - git config --global url."https://"\$DEPLOY_TOKEN_NAME":"\$DEPLOY_TOKEN"@gitlab.com".insteadOf https://gitlab.com  #gitleaks:allow
    - terraform init
  tags: $TAGS

tf_validate_$TF_CODE_ROOT:
  stage: terraform_validate
  image:
    name: us-docker.pkg.dev/<PROJECT>-$PHI_ENV-<REGISTRY>/builder-terraform:stable
    entrypoint:
     - '/usr/bin/env'
     - 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  script:
    - echo $TF_ROOT
    - cd $TF_ROOT
    - git config --global url."https://"\$DEPLOY_TOKEN_NAME":"\$DEPLOY_TOKEN"@gitlab.com".insteadOf https://gitlab.com #gitleaks:allow
    - terraform init
    - terraform fmt -check=true
    - terraform validate
  needs:
    - job: tf_init_$TF_CODE_ROOT
  tags: $TAGS

tf_plan_$TF_CODE_ROOT:
  stage: terraform_plan
  image:
    name: us-docker.pkg.dev/<PROJECT>-$PHI_ENV-<REGISTRY>/builder-terraform:stable
    entrypoint:
     - '/usr/bin/env'
     - 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  script:
    - echo $TF_ROOT
    - echo \$CI_JOB_URL >> plan_job_url.txt
    - cd $TF_ROOT
    - git config --global url."https://"\$DEPLOY_TOKEN_NAME":"\$DEPLOY_TOKEN"@gitlab.com".insteadOf https://gitlab.com #gitleaks:allow
    - terraform init
    - touch $(echo $TF_CODE_ROOT | sed 's:[/^]*$::' | sed 's:.*/::')
    - terraform plan -out=$(echo $TF_CODE_ROOT | sed 's:[/^]*$::' | sed 's:.*/::').terraform
  artifacts:
    paths:
      - "${TF_ROOT}$(echo $TF_CODE_ROOT | sed 's:[/^]*$::' | sed 's:.*/::').terraform"
      - plan_job_url.txt
    expire_in: 2 days
  needs:
    - job: tf_validate_$TF_CODE_ROOT
  tags: $TAGS

slack_notification_$TF_CODE_ROOT:
  stage: slack_notification
  image:
    name: us-docker.pkg.dev/<PROJECT>-$PHI_ENV-<REGISTRY>/gcloud:latest
  script:
    - |
      API_URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/protected_environments"
      response=\$(curl --silent --header "PRIVATE-TOKEN: \$BOT_TOKEN" "\${API_URL}")
      is_protected=\$(echo "\$response" | jq --arg env "${ENV%/}" 'map(.name) | index(\$env) != null')
      if [[ "\$is_protected" != "true" ]]; then
        echo "The environment "${ENV%/}" is NOT protected."
        exit 0
      else
        echo "The environment "${ENV%/}" IS protected."
        PLAN_FILE_URL=\$(cat plan_job_url.txt)
        ENV_ID=\$(curl --header "PRIVATE-TOKEN: \$BOT_TOKEN" "https://gitlab.com/api/v4/projects/\$CI_PROJECT_ID/environments?per_page=100" | jq '(.[] | select(.name == "'$ENV'") | .id)' )
        APPROVAL_LINK_URL=($CI_PROJECT_URL/-/environments/\$ENV_ID)
        USER_IDS=\$(curl --header "PRIVATE-TOKEN: \$BOT_TOKEN" "https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/protected_environments/$(echo $ENV | sed 's/\//%2F/g')" | jq --raw-output '.deploy_access_levels[].user_id')
        EMAILS=\$(for i in \$USER_IDS; do curl --header "PRIVATE-TOKEN: \$BOT_TOKEN" "https://gitlab.com/api/v4/users/\$i" | ( jq --raw-output '.name') | tr ' ' '.' | awk '{print \$1"@medecision.com"}'; done)
        USERS=\$(echo \$(for i in \${EMAILS[@]}; do curl -F email=\$i https://slack.com/api/users.lookupByEmail -H "Authorization: Bearer \$SLACK_TOKEN" | jq --raw-output '.user.id'  | sed "s/^/<@/;s/$/>/" ; done))
        SLACK_IDS1=\$(echo \$(for i in \${EMAILS[@]}; do curl -F email=\$i https://slack.com/api/users.lookupByEmail -H "Authorization: Bearer \$SLACK_TOKEN" | jq --raw-output '.user.id'; done) | tr ' ' ',')
        SLACK_IDS=(\$SLACK_IDS1,U02H6PLMXSA)
        CHANNEL_ID=\$(curl -X POST -F users="\$SLACK_IDS" https://slack.com/api/conversations.open -H "Authorization: Bearer \$SLACK_TOKEN" | jq --raw-output '.channel.id')
        sed -i "s/CHANNEL_ID/\$CHANNEL_ID/g" slack.json
        sed -i "s/USERS/\$USERS/g" slack.json
        sed -i "s%PLAN_FILE_URL%\$PLAN_FILE_URL%g" slack.json
        sed -i "s/CI_PROJECT_TITLE/\$CI_PROJECT_TITLE/g" slack.json
        sed -i "s%ENVIRONMENT_NAME%$ENV%g" slack.json
        sed -i "s%APPROVAL_LINK_URL%\$APPROVAL_LINK_URL%g" slack.json
        curl -H "Content-Type: application/json; charset=utf-8" --data  @slack.json -H "Authorization: Bearer \$SLACK_TOKEN" -X POST https://slack.com/api/chat.postMessage
      fi
  needs:
    - job: tf_plan_$TF_CODE_ROOT
  rules:
    - if: '"$CI_COMMIT_BRANCH" == "main" && "$TIER" == "production"'
  tags: $TAGS

tf_apply_$TF_CODE_ROOT:
  stage: terraform_apply
  image:
    name: us-docker.pkg.dev/<PROJECT>-$PHI_ENV-<REGISTRY>/builder-terraform:stable
    entrypoint:
     - '/usr/bin/env'
     - 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  script:
    - echo $TF_ROOT
    - cd $TF_ROOT
    - git config --global url."https://"\$DEPLOY_TOKEN_NAME":"\$DEPLOY_TOKEN"@gitlab.com".insteadOf https://gitlab.com #gitleaks:allow
    - terraform init
    - ls
    - terraform apply $(echo $TF_CODE_ROOT | sed 's:[/^]*$::' | sed 's:.*/::').terraform
  only:
    refs:
      - main
  when: manual
  environment:
    name: $ENV
    deployment_tier: $TIER
  needs:
    - job: tf_plan_$TF_CODE_ROOT
  tags: $TAGS
EOF
