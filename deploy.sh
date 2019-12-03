# !/usr/bin/bash

env="$1"

if [ "$env" != "prd" ] && [ "$env" != "test" ] && [ "$env" != "dev" ] && [ "$env" != "design" ]; then
  echo "Unknown env $env, valid envs are prd or test"
  exit 1
fi

rm -rf stage
mkdir stage

cp -r ./css ./stage
cp -r ./img ./stage
cp -r ./plugins ./stage
cp -r ./index.html ./stage

bucket="s3://abcantuangco-profile-$env";

if [ "$env" == "prd" ]; then
  bucket="s3://abcantuangco-profile"
fi

echo $bucket;

# GZIP encode every css and js files then rename them to remove the .gz ext
# find ./stage/**/*.js -exec gzip -9 {} \; -exec mv {}.gz {} \;
find ./stage/**/*.css -exec gzip -9 {} \; -exec mv {}.gz {} \;

# Add 1yr cache to Assets
aws s3 sync ./stage "$bucket" --include "*" --exclude "*.css" --exclude "*.js" --cache-control "max-age=31536000"
# Add 1 year cache to CSS and JS
aws s3 sync ./stage "$bucket" --exclude "*" --include "*.js" --include "*.css" --content-encoding gzip --cache-control "max-age=31536000"
# Add 2min cache to main html file
aws s3 sync ./stage "$bucket" --exclude "*" --include "*.html" --cache-control "max-age=120"

rm -rf ./stage