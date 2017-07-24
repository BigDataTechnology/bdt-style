#!/usr/bin/env bash

print_help(){
  echo "Usage: create_changelog [-sh] TYPE
  OPTIONS:
    -h    print this help
    TYPE is 'major' -> X+1.0.0 or
            'minor' -> X.Y+1.0 or
            'patch' -> X.Y.Z+1 or
            'hotfix' -> X.Y.Z+1
    "
}

update_bowerjson(){
  echo "Preparing bower.json"
  local type="$1"

  sed "s/\"version\".*/\"version\": \"$new_tag\",/g" bower.json > bower.json.tmp
  mv -f bower.json.tmp bower.json

  printf "bower.json updated\n"
}

update_changelog(){
  echo "Preparing CHANGELOG.md"

  printf "Commit list from tag ${green}%s${reset}:\n" "$old_tag"
  # scrivo commit su file temporaneo
  git log "${old_tag}.." --no-merges --format=%B --oneline --decorate |
    grep '\[R\]' |
    sed "s/.*\[R\] - *\(.*\)/\1/" | sed "s/^/* /" >> tmp.md
  printf "\n" >> tmp.md

  # aggiungo changelog a quello esistente
  cat tmp.md CHANGELOG.md > CHANGELOG.tmp
  mv -f CHANGELOG.tmp CHANGELOG.md
  rm tmp.md

  printf "CHANGELOG.md updated\n"
}

committing(){
  # commit modifiche al changelog
  git commit -a -m "Updated changelog"
  printf "Committed\n"
}

start_release(){
  git flow release start "$new_tag"
  printf "Release started\n"
}

finish_release(){
  git flow release finish "$new_tag"
  printf "Release finished\n"
}

start_hotfix(){
  git flow hotfix start "$new_tag"
  printf "Hotfix started\n"
}

finish_hotfix(){
  git flow hotfix finish "$new_tag"
  printf "Hotfix finished\n"
}

pushing_branch(){
  # pushing
  git push
  printf "Branch pushed\n"
}

pushing_tags(){
  # creazione tag
  git push --tags
  printf "Tag pushed\n"
}

finishing(){
  local type="$1"

  if [ "$type" == "with-finish-release" ]; then
    committing
    finish_release
  fi

  if [ "$type" == "with-finish-hotfix" ]; then
    committing
    finish_hotfix
  fi
}

starting(){
  local type="$1"

  if [ "$type" == "major" ]; then
    major=$((major+1))
    minor=0
    patch=0

    new_tag="${major}.${minor}.${patch}"
    start_release

    echo "${yellow}++++++++++++++++++++ ${red}Major ${yellow}release ${new_tag} ++++++++++++++++++++${reset}"
    printf '## %s (%s) *** Major release ***\n\n' "$new_tag" "$(date +'%Y%m%d')" > tmp.md

  elif [ "$type" == "minor" ]; then
    major=$((major))
    minor=$((minor+1))
    patch=0

    new_tag="${major}.${minor}.${patch}"
    start_release

    echo "${yellow}-------------------- ${blue}Minor ${yellow}release ${new_tag} --------------------${reset}"
    printf '## %s (%s) *** Minor release ***\n\n' "$new_tag" "$(date +'%Y%m%d')" > tmp.md

  elif [ "$type" == "patch" ]; then
    major=$((major))
    minor=$((minor))
    patch=$((patch+1))

    new_tag="${major}.${minor}.${patch}"
    start_release

    echo "${yellow}-------------------- ${blue}Patch ${yellow}release ${new_tag} --------------------${reset}"
    printf '## %s (%s) *** Patch release ***\n\n' "$new_tag" "$(date +'%Y%m%d')" > tmp.md

  else
    major=$((major))
    minor=$((minor))
    patch=$((patch+1))

    new_tag="${major}.${minor}.${patch}"
    start_hotfix

    echo "${yellow}-------------------- ${blue}Hotfix ${new_tag} --------------------${reset}"
    printf '## %s (%s)*** Hotfix ***\n\n' "$new_tag" "$(date +'%Y%m%d')" > tmp.md
  fi

  update_changelog "$type"
  update_bowerjson "$type"

}

# colors
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
blue="$(tput setaf 4)"
reset="$(tput sgr0)"

old_tag="$(git describe --abbrev=0 --tags 2>/dev/null || echo -n '')"
new_tag=$old_tag

major="$(echo $old_tag | cut -d '.' -f 1)"
minor="$(echo $old_tag | cut -d '.' -f 2)"
patch="$(echo $old_tag | cut -d '.' -f 3)"

while getopts ":sh" opt; do
  case $opt in
    h)
      print_help
      exit 0
      ;;
    \?)
      echo "Option not recognized" >&2
      print_help >&2
      exit 22
      ;;
  esac
done

type="$1"
# exit script if no target specified
case "$type" in
  "major")
    printf "Preparing a major version (major-level)\n"
    ;;
  "minor")
    printf "Preparing a minor version (minor-level)\n"
    ;;
  "patch")
    printf "Preparing a patch version (patch level)\n"
    ;;
  "hotfix")
    printf "Preparing a hotfix version\n"
    ;;
  *)
    echo "Unknown type. Aborted" >&2
    print_help >&2
    exit 1
    ;;
esac

starting "$type"

type_finish="$2"
case "$type_finish" in
  "with-finish-release")
    printf "Closing release branch\n"
    ;;
  "with-finish-hotfix")
    printf "Closing hotfix branch\n"
    ;;
  *)
    ;;
esac

finishing "$type_finish"