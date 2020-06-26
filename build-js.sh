#!/bin/bash

hash node 2>/dev/null || { 
    echo >&2 "I require node but it's not installed.  Aborting."; 
    exit 1;
}

hash yarn 2>/dev/null || {
    USE_NPM="true"
}

if [ "$USE_NPM" = "true" ]; then
    hash npm 2>/dev/null || { 
        echo >&2 "I require npm but it's not installed.  Aborting."; 
        exit 1;
    }    
    npm install
    npm run build
else
    yarn
    yarn build
fi

