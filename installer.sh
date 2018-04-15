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

# port_installed()
# Macports can be very slow if you accidentally try to reinstall a list of already installed packages.
# This is a small function that lets us test to see if something is already installed and skip it.
# It will print out something like [[ 0 -ge 1 ]]... where the first number indicates how many
# installed packages match the passed in name. 
# It is intended to be used in a config file like " $(port_installed htop) || port install htop
port_installed() {
    echo "[[ `port installed active | cut -d @ -f 1 | grep -c $1` -ge 1 ]]"
}



# detect_platforms()
# This is passed in the location of the yaml file
# This will print out a list of the platforms defined inside the package file
detect_platforms() { 
    yamlpath=$1
    parse_platforms_yaml() {
       local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
       sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
       awk -F$fs  '{
          indent = length($1)/2;
          vname[indent] = $2;
          
          for (i in vname) {
            if (i > indent) {
              delete vname[i]
            }
          }
          # we want to make sure we are not picking up the names of packages, only platforms
          if( vname[0] != $2){
    #           printf("(%s,%s) ", vname[0], $2);
                printf("%s ", $2);
            }
       }'
    }

echo "$(parse_platforms_yaml $yamlpath)" | xargs -n1 | sort -u | xargs
}





confirm_user() {
    echo -n "Proceed? [yes or no] "
    read yno
    case $yno in
            [yY] | [yY][Ee][Ss] )
                    echo ""
                    ;;
    
            [nN] | [n|N][O|o] )
                    echo "Exiting now"
                    exit 1
                    ;;
            *) echo "Invalid input"
                exit 1
                ;;
    esac
}

############ INSTALLER ################
run_installer() {
        if [ $# -lt 3 ]
        then
            echo "Usage : sudo ./installer.sh <packages.yaml> install <MainPlatform> [SpecificPlatform ...]"
            echo "Specify platform names in order of most generic to specific."
            echo "Examples:"
            echo "  'installer.sh packages.yml Darwin'"
            echo "  Install pacages which are defined for Darwin."
            echo "  'installer.sh packages.yml Linux Trusty'"
            echo "  Install packages which are defined for linux, unless Trusty version has also been defined."
        fi


        if [ $# -lt 3 ]; then
            echo ""
            echo "Please specify platforms. Available Platforms:  $detected_platforms"
            exit
        fi



        # TODO: Verify that input packages match names found in file
        platforms="${*:2}"  # https://stackoverflow.com/a/9057392
        echo "Install packages for $platforms"


        # Check that the user is root (because we usually want that for installing)
        if [ "$(whoami)" != "root" ]; then
            echo "You are not ROOT, which is usually required to install packages."
            confirm_user
        fi



        # Run the parser
        eval $(parse_packages_yaml $yaml_path "config_" "$platforms")



        # show list of packages to be installed
        echo ""
        echo "=== Commands to be run ==="
        for var in ${!config_@}; do
            echo ${!var}
        done
        echo "=========================="
        confirm_user


        # Install Software
        echo "=== Installing Software ==="
        for var in ${!config_@}; do
            echo "=====> ${!var}"
            eval ${!var}
        done
}



######################## MAIN ##########################

if [ $# -lt 2 ]
then
    echo "Usage : sudo ./installer.sh <packages.yaml> <command>"
    echo "     commands: list, install"
    exit
fi


# if [ $# -lt 2 ]
# then
#     echo ""
#     echo "Running [ installer.sh packages.yml ] will print out a list of defined platforms"
#     exit
# fi

# Verify yaml file exists
yaml_path=$1
if [ ! -f $yaml_path ]; then
    echo ""
    echo "Error: File \"$yaml_path\" not found!"
    exit
fi

command=$2
case $command in
    "list" )
        # Display list of platforms available
        detected_platforms=$(detect_platforms "$yaml_path")
        echo $detected_platforms
        exit 0
        ;;
    "install" )
        run_installer $yaml_path ${*:2}
        exit 0
        ;;
    * ) 
        echo "Bad command"
        exit 1
        ;;
esac

echo "never get here"
exit


#############################################################
# Old code from testing purposes....
case "$1" in

    test) 
        #eval $(parse_packages_yaml packages2.yml "config_" "Linux Trusty")
        eval $(parse_packages_yaml packages2.yml "config_" "Darwin")
        for var in ${!config_@}; do
            #printf "%s%q\n" "$var=" "${!var}"
            #printf "%q\n" "${!var}"
            echo ${!var}
            eval ${!var}
        done
        echo "==============="
        ;;

esac

