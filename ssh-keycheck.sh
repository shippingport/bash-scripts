#!/bin/bash

# DESCRIPTION
# A simple bash script for verifying keyscanned keys with a known-good key
# Can be useful for automated deployments.

# Set MD5 to the RSA key fingerprint shared on GitHub's website:
# https://help.github.com/en/github/authenticating-to-github/testing-your-ssh-connection
# This way we can verify the key when adding SSH hosts later on.
MD5="16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48"

# Add GitHub to known_hosts
# Import the keys to a temp file
ssh-keyscan -t rsa -H github.com >> /tmp/github_ssh
KEY=$(ssh-keygen -l -E md5 -f /tmp/github_ssh | awk '{print $2}' | cut -d":" -f 2- | awk '{print $1}')
if diff <(echo "$KEY") <(echo "$MD5"); then
    # Imported key matches with known-good key, so add the keys to known_hosts
    printf "SSH keys match!"
    cat /tmp/github_ssh >> /root/.ssh/known_hosts
    chmod 0600 /root/.ssh/known_hosts
else
    # Imported key did not match, give user 30 seconds to import the keys anyway
    # This section is optional
    read -t 30 -p "SSH keys did not match. Import anyway? (NOT RECOMMENDED) [y/N]" -n 1 -r
    if [[ $REPLY =~ ^(yes|y|Y)$ ]]; then
    # Import the key
        printf "\nAdding key anyway..."
        cat /tmp/github_ssh >> /root/.ssh/known_hosts
        chmod 0600 /root/.ssh/id_rsa /root/.ssh/known_hosts
        printf " Key added.\n"
    else
    # Exit script
    # Maybe do some rescue work here...
    printf "\nERROR: key mismatch! Aborting..."
    printf "\nDeployment failed.\n"
    fi
fi
