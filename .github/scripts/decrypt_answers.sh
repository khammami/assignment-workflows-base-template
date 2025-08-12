#!/bin/sh

# --batch to prevent interactive command
# --yes to assume "yes" for questions
gpg --quiet --batch --yes --decrypt --passphrase="$ANSWERS_SECRET_PASSPHRASE" \
    --output .github/assets/answers.txt .github/assets/answers.txt.gpg
