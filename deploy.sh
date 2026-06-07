#!/bin/bash

# Configuration
PATH_REMOTE="lanzamientos.eventosbniperu.com/scan"
KEY="~/.ssh/gcp_globals1_rsa"
USER="globalso"
SERVER="ftp.globals.one"
PORT="22"

echo "🚀 Starting deployment..."

# 1. Bump patch version (writes package.json; no git tag/commit yet)
echo "🔢 Bumping version..."
npm version patch --no-git-tag-version > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ Failed to bump version. Aborting deployment."
    exit 1
fi
NEW_VERSION=$(node -p "require('./package.json').version")
echo "✅ New version: $NEW_VERSION"

# 2. Sync version into the PWA manifest and bump the service-worker cache name.
#    Changing CACHE_NAME is what forces installed PWAs to fetch the new files
#    instead of serving the old cached version.
echo "🔄 Syncing version into manifest.json and service-worker.js..."
node -e "const fs=require('fs');const m=JSON.parse(fs.readFileSync('manifest.json'));m.version='$NEW_VERSION';fs.writeFileSync('manifest.json',JSON.stringify(m,null,2)+'\n');"
if [ $? -ne 0 ]; then
    echo "❌ Failed to update manifest.json. Aborting deployment."
    exit 1
fi
sed -i "s/const CACHE_NAME = 'qr-scanner-v[^']*';/const CACHE_NAME = 'qr-scanner-v$NEW_VERSION';/" service-worker.js

# 3. Commit the version bump (only the version-related files; ignores other WIP changes)
echo "📝 Committing version bump..."
git commit -o package.json manifest.json service-worker.js -m "chore(release): v$NEW_VERSION"
if [ $? -ne 0 ]; then
    echo "❌ Failed to commit version bump. Aborting deployment."
    exit 1
fi

# 4. No build step — this is a static PWA. Deploy the files as-is via rsync.
echo "📤 Deploying to $SERVER..."

rsync -avz --delete \
    --exclude '.git/' \
    --exclude '.gitignore' \
    --exclude 'deploy.sh' \
    --exclude 'package.json' \
    --exclude 'package-lock.json' \
    --exclude 'node_modules/' \
    --exclude 'README.md' \
    --exclude '*.bak' \
    --exclude 'server.log' \
    --exclude '.DS_Store' \
    -e "ssh -p $PORT -i $KEY -o StrictHostKeyChecking=no" \
    ./ \
    $USER@$SERVER:$PATH_REMOTE

if [ $? -eq 0 ]; then
    echo "✨ Deployment completed successfully!"
    echo "🌍 Visit: https://lanzamientos.eventosbniperu.com/scan/"
else
    echo "❌ Deployment failed."
    exit 1
fi
