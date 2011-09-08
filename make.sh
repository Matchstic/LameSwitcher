#!/bin/bash

ARGS=$*

# Initial set up

# Dump Public Frameworks

#for fw in $SDK/System/Library/Frameworks/*/
#do export GO_EASY_ON_ME=1
#    class-dump -H -o ~/Desktop/HeaderDump/Frameworks/$(perl -e "print substr(substr('$fw', 0, -1), rindex(substr('$fw', 0, -1), \"/\") +1, (rindex(substr('$fw', 0, -1), \".\"))-(rindex(substr('$fw', 0, -1), \"/\") +1))";)/ $fw$(perl -e "print substr(substr('$fw', 0, -1), rindex(substr('$fw', 0, -1), \"/\") +1, (rindex(substr('$fw', 0, -1), \".\"))-(rindex(substr('$fw', 0, -1), \"/\") +1))";)
#done


# Build
echo ""
echo "||---- Building..."
echo ""
make $ARGS
echo ""
echo "||---- Built!"
echo ""

exit 0