#!/bin/bash

cd function

zip -vr some-lambda-thing.zip . -x "*.DS_Store"

aws lambda update-function-code \
  --function-name  some-lambda-thing \
  --zip-file fileb://some-lambda-thing.zip
