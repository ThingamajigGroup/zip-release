#! /bin/bash
# Create archive or exit if command fails
set -eu

# install required tools to work with json files
#sudo apt  install jq -y

printf "\n📦 Creating %s archive...\n" "$INPUT_TYPE"

if [ "$INPUT_DIRECTORY" != "." ] 
then
  cd $INPUT_DIRECTORY
fi

if [ "$INPUT_TYPE" = "zip" ] 
then
  if [ "$RUNNER_OS" = "Windows" ]
  then
    if [ -z "$INPUT_EXCLUSIONS" ] 
    then
      7z a -tzip $INPUT_FILENAME $INPUT_PATH || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
    else
      EXCLUSIONS=''

      for EXCLUSION in $INPUT_EXCLUSIONS
      do
        EXCLUSIONS+=" -x!"
        EXCLUSIONS+=$EXCLUSION
      done

      for EXCLUSION in $INPUT_RECURSIVE_EXCLUSIONS
      do
        EXCLUSIONS+=" -xr!"
        EXCLUSIONS+=$EXCLUSION
      done

      7z a -tzip $INPUT_FILENAME $INPUT_PATH $EXCLUSIONS || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
    fi
  else
    if [ -z "$INPUT_EXCLUSIONS" ] 
    then
      zip -r $INPUT_FILENAME $INPUT_PATH || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
    else
      zip -r $INPUT_FILENAME_DEPLOY $INPUT_PATH -x $INPUT_EXCLUSIONS || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
      # make RELEASE.yml context file
      echo $INPUT_GITHUB_CONTEXT >> INPUT_GITHUB_CONTEXT.json
      echo "GIT_RELEASE:" >> RELEASE.yml
      echo "  ref_name: $(jq -M -r '.ref_name' INPUT_GITHUB_CONTEXT.json)" >> RELEASE.yml
      echo "  prerelease: $(jq -M -r '.event.release.prerelease' INPUT_GITHUB_CONTEXT.json)" >> RELEASE.yml
      echo "  published_at: $(jq -M -r '.event.release.published_at' INPUT_GITHUB_CONTEXT.json)" >> RELEASE.yml
      echo "  target_commitish: $(jq -M -r '.event.release.target_commitish' INPUT_GITHUB_CONTEXT.json)" >> RELEASE.yml
      echo "  triggering_actor: $(jq -M -r '.triggering_actor' INPUT_GITHUB_CONTEXT.json)" >> RELEASE.yml
      echo "  title: $(jq -M -r '.event.release.name' INPUT_GITHUB_CONTEXT.json)" >> RELEASE.yml
      echo "  description: $(jq -M -r '.event.release.body' INPUT_GITHUB_CONTEXT.json)" >> RELEASE.yml
      echo "  url: $(jq -M -r '.event.release.html_url' INPUT_GITHUB_CONTEXT.json)" >> RELEASE.yml
      # grab the deploy.zip file and compress again into release.zip file containing deploy.zip, install.sh, README*
      zip -r $INPUT_FILENAME $INPUT_PATH --include $INPUT_INCLUSIONS || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }


    fi
  fi
elif [ "$INPUT_TYPE" = "tar" ] 
then
  if [ -z "$INPUT_EXCLUSIONS" ] 
  then
    tar -zcvf $INPUT_FILENAME $INPUT_PATH || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
  else
    tar -zcvf $INPUT_FILENAME --exclude=$INPUT_EXCLUSIONS $INPUT_PATH || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
  fi
else
  printf "\n⛔ Invalid archiving tool.\n"; exit 1;
fi

printf "\n✔ Successfully created %s archive.\n" "$INPUT_TYPE"
