aws cloudformation deploy \
  --template-file template-frontend.yaml \
  --stack-name patch-pilot-frontend-stack \
  --capabilities CAPABILITY_IAM


npm install
npm run build
aws s3 sync ./dist/ s3://YOUR_BUCKET_NAME

aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
