aws cloudformation deploy \
  --template-file template-frontend.yaml \
  --stack-name patch-pilot-frontend-stack \
  --capabilities CAPABILITY_IAM
