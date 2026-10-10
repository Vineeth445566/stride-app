#!/bin/bash
# Push the Stride app to GitHub (one-time setup for Codemagic cloud builds).
#
# Prerequisites:
#   1. Create an empty repo on https://github.com/new (name it "stride-app",
#      private is fine, do NOT initialize with README).
#   2. Authenticate: run `gh auth login` and follow the prompts.
#
# Then run this script:
#   bash ~/workspace/stride-app/PUSH-TO-GITHUB.sh <your-github-username>
#
# Example:
#   bash ~/workspace/stride-app/PUSH-TO-GITHUB.sh vineethk

set -e
USER_NAME="${1:?Usage: PUSH-TO-GITHUB.sh <your-github-username>}"
cd ~/workspace/stride-app

# Init repo if needed
if [ ! -d .git ]; then
  git init -b main
  git add -A
  git commit -m "Stride step-counter app v1.0.0 (ads disabled)"
fi

# Add remote and push
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/${USER_NAME}/stride-app.git"
git push -u origin main

echo ""
echo "Pushed! Now:"
echo "  1. Go to https://codemagic.io and sign up (free)."
echo "  2. Add application → connect your stride-app GitHub repo."
echo "  3. Start the 'Android Debug APK' workflow."
echo "  4. Download app-debug.apk from the build artifacts."
