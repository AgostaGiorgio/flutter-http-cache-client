#!/bin/bash

# Step 1: Update both local versions of develop and master
git checkout develop
git pull origin develop

git checkout master
git pull origin master

# Step 2: Merge develop into master
git merge develop

# Step 3: Parse the version
version=$(grep -E '^version:' "pubspec.yaml" | awk '{print $2}')
echo "Releasing $version"

# Format files
dart format .
git add *
git commit -m "Dart format"
git push origin master

# Step 4: Create a tag x.y.z
git tag $version
git push origin $version

# Step 5: Update version file with "version: x.y+1.z" and push
next_version=$(echo $version | awk -F. '{$2 = $2 + 1; $3 = 0;} 1' | sed 's/ /./g')
sed -i.bak "s/version: $version/version: $next_version/" "pubspec.yaml"
rm pubspec.yaml.bak

# Commit the changes
git add pubspec.yaml
git commit -m "Prepare for next development iteration"
git push origin master

# Step 6: Merge master into develop
git checkout develop
git merge master
git push origin develop

git checkout $version
dart pub publish -f

echo "Package released successfully!"