export APEX_TEST_NAME_MATCH_CUMULUSCI=`grep 'cumulusci.test.namematch *=' cumulusci.properties | sed -e 's/cumulusci.test.namematch *= *//g'`
export APEX_TEST_NAME_EXCLUDE_CUMULUSCI=`grep 'cumulusci.test.nameexclude *=' cumulusci.properties | sed -e 's/cumulusci.test.nameexclude *= *//g'`

# Get the PACKAGE_AVAILABILE_RETRY_COUNT from env or use default
if [ "$PACKAGE_AVAILABLE_RETRY_COUNT" == "" ]; then
    export PACKAGE_AVAILABLE_RETRY_COUNT=5
fi

# The python scripts expect BUILD_COMMIT
export BUILD_COMMIT=$CI_COMMIT_ID

# Cache the main build directory
export BUILD_WORKSPACE=`pwd`

# Function to filter out unneeded ant output from builds
function runAntTarget {
    target=$1
    ant $target  | stdbuf -oL \
        stdbuf -o L grep -v '^  *\[copy\]' | \
        stdbuf -o L grep -v '^  *\[delete\]' | \
        stdbuf -o L grep -v '^  *\[loadfile\]' | \
        stdbuf -o L grep -v '^  *\[mkdir\]' | \
        stdbuf -o L grep -v '^  *\[move\]' | \
        stdbuf -o L grep -v '^  *\[xslt\]'

    exit_status=${PIPESTATUS[0]}
    
    if [ "$exit_status" != "0" ]; then
        echo "BUILD FAILED on target $target"
    fi
    return $exit_status
}

function runAntTargetBackground {
    ant $1 > "$1.cumulusci.log" 2>& 1 &
}

# Function to wait on all background jobs to complete and return exit status
function waitOnBackgroundJobs {
    FAIL=0
    for job in `jobs -p`
    do
    echo $job
        wait $job || let "FAIL+=1"
    done
    
    echo
    echo "-----------------------------------------------------------------"
    if [ $FAIL -gt 0 ]; then
        echo "BUILD FAILED: Showing logs from parallel jobs below"
    else
        echo "BUILD PASSED: Showing logs from parallel jobs below"
    fi
    echo "-----------------------------------------------------------------"
    echo
    for file in *.cumulusci.log; do
        echo
        echo "-----------------------------------------------------------------"
        echo "BUILD LOG: $file"
        echo "-----------------------------------------------------------------"
        echo
        cat $file
    done
    if [ $FAIL -gt 0 ]; then
        exit 1
    fi
}

#-----------------------------------
# Set up dependencies for async test
#-----------------------------------
if [ "$TEST_MODE" == 'parallel' ]; then
    pip install --upgrade simple-salesforce
fi


    # Set the APEX_TEST_NAME_* environment variables for the build type
    if [ "$APEX_TEST_NAME_MATCH_PACKAGING" != "" ]; then
        export APEX_TEST_NAME_MATCH=$APEX_TEST_NAME_MATCH_PACKAGING
    elif [ "$APEX_TEST_NAME_MATCH_GLOBAL" != "" ]; then
        export APEX_TEST_NAME_MATCH=$APEX_TEST_NAME_MATCH_GLOBAL
    else
        export APEX_TEST_NAME_MATCH=$APEX_TEST_NAME_MATCH_CUMULUSCI
    fi
    if [ "$APEX_TEST_NAME_EXCLUDE_PACKAGING" != "" ]; then
        export APEX_TEST_NAME_EXCLUDE=$APEX_TEST_NAME_EXCLUDE_PACKAGING
    elif [ "$APEX_TEST_NAME_EXCLUDE_GLOBAL" != "" ]; then
        export APEX_TEST_NAME_EXCLUDE=$APEX_TEST_NAME_EXCLUDE_GLOBAL
    else
        export APEX_TEST_NAME_EXCLUDE=$APEX_TEST_NAME_EXCLUDE_CUMULUSCI
    fi

    # Get org credentials from env
    export SF_USERNAME=$SF_USERNAME_PACKAGING
    export SF_PASSWORD=$SF_PASSWORD_PACKAGING
    export SF_SERVERURL=$SF_SERVERURL_PACKAGING
    echo "Got org credentials for packaging org from env"

    # # Deploy to packaging org
    # echo
    # echo "-----------------------------------------------------------------"
    # echo "ant deployCIPackageOrg - Deploy to packaging org"
    # echo "-----------------------------------------------------------------"
    # echo

    # #echo "Running deployCIPackageOrg from /home/rof/clone"
    # #cd /home/rof/clone
    # runAntTarget deployCIPackageOrg
    # if [[ $? != 0 ]]; then exit 1; fi

    
    #echo
    #echo "-----------------------------------------------------------------"
    #echo "Waiting on background jobs to complete"
    #echo "-----------------------------------------------------------------"
    #echo
    #waitOnBackgroundJobs
    #if [ $? != 0 ]; then exit 1; fi
    
    Upload beta package
    echo
    echo "-----------------------------------------------------------------"
    echo "Uploading beta managed package via Selenium"
    echo "-----------------------------------------------------------------"
    echo

    echo "Installing python dependencies"
    export PACKAGE=`grep 'cumulusci.package.name.managed=' cumulusci.properties | sed -e 's/cumulusci.package.name.managed *= *//g'`
    # Default to cumulusci.package.name if cumulusci.package.name.managed is not defined
    if [ "$PACKAGE" == "" ]; then
        export PACKAGE=`grep 'cumulusci.package.name=' cumulusci.properties | sed -e 's/cumulusci.package.name *= *//g'`
    fi
    echo "Using package $PACKAGE"
    export BUILD_NAME="$PACKAGE Build $CI_BUILD_NUMBER"
    export BUILD_WORKSPACE=`pwd`
    export BUILD_COMMIT="$CI_COMMIT_ID"
    pip install --upgrade selenium
    pip install --upgrade requests

    echo 
    echo
    echo "Running package_upload.py"
    echo
    python $CUMULUSCI_PATH/ci/package_upload.py
    if [[ $? -ne 0 ]]; then exit 1; fi
 
    # Test beta
    echo
    echo "-----------------------------------------------------------------"
    echo "ant deployManagedBeta - Install beta and test in beta org"
    echo "-----------------------------------------------------------------"
    echo

    # Set the APEX_TEST_NAME_* environment variables for the build type
    if [ "$APEX_TEST_NAME_MATCH_PACKAGING" != "" ]; then
        export APEX_TEST_NAME_MATCH=$APEX_TEST_NAME_MATCH_PACKAGING
    elif [ "$APEX_TEST_NAME_MATCH_GLOBAL" != "" ]; then
        export APEX_TEST_NAME_MATCH=$APEX_TEST_NAME_MATCH_GLOBAL
    else
        export APEX_TEST_NAME_MATCH=$APEX_TEST_NAME_MATCH_CUMULUSCI
    fi
    if [ "$APEX_TEST_NAME_EXCLUDE_PACKAGING" != "" ]; then
        export APEX_TEST_NAME_EXCLUDE=$APEX_TEST_NAME_EXCLUDE_PACKAGING
    elif [ "$APEX_TEST_NAME_EXCLUDE_GLOBAL" != "" ]; then
        export APEX_TEST_NAME_EXCLUDE=$APEX_TEST_NAME_EXCLUDE_GLOBAL
    else
        export APEX_TEST_NAME_EXCLUDE=$APEX_TEST_NAME_EXCLUDE_CUMULUSCI
    fi

    export SF_USERNAME=$SF_USERNAME_BETA
    export SF_PASSWORD=$SF_PASSWORD_BETA
    export SF_SERVERURL=$SF_SERVERURL_BETA
    echo "Got org credentials for beta org from env"
    export PACKAGE_VERSION=`grep PACKAGE_VERSION package.properties | sed -e 's/PACKAGE_VERSION=//g'`
    echo "Attempting install of $PACKAGE_VERSION"

    tries=0
    while [ $tries -lt $PACKAGE_AVAILABLE_RETRY_COUNT ]; do
        tries=$[tries + 1]
        echo
        echo "-----------------------------------------------------------------"
        echo "ant deployManagedBeta - Attempt $tries of $PACKAGE_AVAILABLE_RETRY_COUNT"
        echo "-----------------------------------------------------------------"
        echo
        runAntTarget deployManagedBeta
        if [[ $? -eq 0 ]]; then break; fi
    done
    if [[ $? -ne 0 ]]; then exit 1; fi

    if [ "$RUNALLTESTS_BETA" == "true" ]; then   
        echo
        echo "-----------------------------------------------------------------"
        echo "ant runAllTests: Testing $PACKAGE_VERSION in beta org"
        echo "-----------------------------------------------------------------"
        echo
        runAntTarget runAllTestsManaged
        if [[ $? -ne 0 ]]; then exit 1; fi
    fi
    
    if [ "$GITHUB_USERNAME" != "" ]; then   
        # Create GitHub Release
        echo
        echo "-----------------------------------------------------------------"
        echo "Creating GitHub Release $PACKAGE_VERSION"
        echo "-----------------------------------------------------------------"
        echo
        python $CUMULUSCI_PATH/ci/github/create_release.py

        # Add release notes
        echo
        echo "-----------------------------------------------------------------"
        echo "Generating Release Notes for $PACKAGE_VERSION"
        echo "-----------------------------------------------------------------"
        echo
        pip install --upgrade PyGithub==1.25.1
        export CURRENT_REL_TAG=`grep CURRENT_REL_TAG release.properties | sed -e 's/CURRENT_REL_TAG=//g'`
        echo "Generating release notes for tag $CURRENT_REL_TAG"
        python $CUMULUSCI_PATH/ci/github/release_notes.py
    
        if [ "$GITHUB_MERGE_COMMITS" == "true" ]; then       
            # Merge master commit to all open feature branches
            echo
            echo "-----------------------------------------------------------------"
            echo "Merge commit to all open feature branches"
            echo "-----------------------------------------------------------------"
            echo
            python $CUMULUSCI_PATH/ci/github/merge_master_to_feature.py
        fi
    else
        echo
        echo "-----------------------------------------------------------------"
        echo "Skipping GitHub Releaseand master to feature merge because the"
        echo "environment variable GITHUB_USERNAME is not configured."
        echo "-----------------------------------------------------------------"
        echo
    fi

    # If environment variables are configured for mrbelvedere, publish the beta
    if [ "$MRBELVEDERE_BASE_URL" != "" ]; then
        echo
        echo "-----------------------------------------------------------------"
        echo "Publishing $PACKAGE_VERSION to mrbelvedere installer"
        echo "-----------------------------------------------------------------"
        echo
        export NAMESPACE=`grep 'cumulusci.package.namespace *=' cumulusci.properties | sed -e 's/cumulusci\.package\.namespace *= *//g'`
        export PROPERTIES_PATH='version.properties'
        export BETA='true'
        echo "Checking out $CURRENT_REL_TAG"
        git fetch --tags origin
        git checkout $CURRENT_REL_TAG
        python $CUMULUSCI_PATH/ci/mrbelvedere_update_dependencies.py
    fi