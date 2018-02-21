#!/bin/bash
# source ../.parse_yaml.sh
#
# passing bash array into awk ... 
# awk -v par="$(IFS=:;echo "${arr[*]}")" 
# https://stackoverflow.com/a/43873811
#
# This prints out a list of key value pairs that bash interperts to be variable names
# 
# so the command 'echo $(parse_packages_yaml packages.yml "config_" "Linux Trusty")'
# would print out the following
# config_test="test-4" config_test="test-2" config_git="git-core2" config_git="git-core" config_vim="vim" config_vim="vim" config_tmux="tmux" config_ssh="ssh" config_pylint="pylint" config_pyflakes="python-flake8" config_pip="python-pip" config_htop="htop" config_iftop="iftop" config_ctags="exuberant-ctags"
#
# use by running with eval $(parse_packages_yaml packages.yml "config_" "Linux Trusty")
parse_packages_yaml() {
   local prefix=$2
   local platform=$3
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs -v pform="$(IFS=:;echo "${platform[*]}")" '{
      indent = length($1)/2;
      vname[indent] = $2;
      split(pform, pformsAsValues, " ");
      # valuesAsValues = {0: "value1", 1: "value2"}
      for (i in pformsAsValues) pformsAsKeys[pformsAsValues[i]] = ""
      # valuesAsKeys = {"value1": "", "value2": ""}
      # Now you can use `in`... ($1 in valuesAsKeys) {print}
      
      #for (key in vname) { print key ": " vname[key] };
      for (i in vname) {
        if (i > indent) {
          delete vname[i]
        }
      }
      if($2 in pformsAsKeys){
         printf("%s%s=\"%s\"\n", "'$prefix'", vname[0], $3);
       }
       #Todo - dont print yet, store in dictionary first so that earlier values can be overwritten
       # by newer more specific versions?
       # Actually that wont work becuase we only get one line at a time... what about naming the variables
       # less specific so that we overwrite the same variable?
   }'
}

detect_platform() {
    #TODO: Scrape package file and look for platforms defined
}

port_installed() {
    # This will print out something like [[ 0 -ge 1 ]]... where the first number indicates how many
    # installed packages match the passed in name. 
    # It is intended to be used in a config file like " $(port_installed htop) || port install htop
    echo "[[ `port installed active | cut -d @ -f 1 | grep -c $1` -ge 1 ]]"
}

#eval $(parse_packages_yaml packages2.yml "config_" "Linux Trusty")
eval $(parse_packages_yaml packages2.yml "config_" "Darwin")
for var in ${!config_@}; do
    #printf "%s%q\n" "$var=" "${!var}"
    #printf "%q\n" "${!var}"
    echo ${!var}
    eval ${!var}
done
echo "==============="
# echo $config_pyflakes
# eval $config_pyflakes
# eval $config_pyflakes
# eval $(parse_packages_yaml package_manager.yml "configmanagers_" "Darwin")
# for var in ${!configmanagers_@}; do
#     #printf "%s%q\n" "$var=" "${!var}"
#     printf "%q\n" "${!var}"
# done
# eval "$configmanagers_default $config_tmux"

# echo $(filter_yaml packages.yml "config_" "Trusty")

# $(filter_yaml packages.yml "config_" "Linux Trusty")
#   Accept "Linux" if no "Trusty"
#   Accept the deepest name defined for a package



# TODO: in addition to packages.yml also define 
# package-names: what package names to use for different platforms
#     git:
#       Linux: git-core
#         Trust: git
#       Darwin: git
# package-managers: What package managers to use for different packages on different platforms
#     git:
#       Linux: sudo apt-get install
#         Trusty: sudo pip install
#       Darwin: sudo port install
# TODO: Present platform options
