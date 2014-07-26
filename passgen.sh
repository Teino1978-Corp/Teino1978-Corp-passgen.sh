#!/bin/bash

#simple password generator based on sha1 hashing and base64 encoding.
#needs grep,read and sha1sum, base64
#written in bash 4.3.18
#
#added case-insensitivity in "INDEX"
#added master password hash generation
#added timing - clear screen after a time
#added hash based pasword checking (prompting for master password)
#added base64 encode for more variation >> more entropy
#
#USAGE:
#set hash of masterpassword, define index and salt in $saltarray, pass index as argument, and get returned password (use either hash or encoded).
#remember only masterpassword, as it is almost truly irrecoverable, so if forgotten, chaos ensues.
# $ sh passgen.sh       - first run - generate master password
# $ sh passgen.sh INDEX - to get password for that index
# $ sh passgen.sh show  - to see available INDEXes

#hash/encode methods used
hashcommand="sha1sum"
encodecommand="base64"

#set masterpassword on first run, and remove after generating and setting $masterpasswordhash
masterpassword="";
#master password hash = sha1 hash of actual password
masterpasswordhash="";

#maximum number of characters in generated password
maxpasswordlength=32;

#time before clearing screen
timeleft=7;

#salts for passwords using named indexes
#put the servicename as <index> and the salt ( any string actually, e.g username or description) as the <value> #maintain spacings
declare -A saltarray=(
	#["<index>"]="<value>" #example
	["GMAIL"]="the big old gmail salt is to be put here"
	["FACEBOOK"]="any ascii characters are allowed, special characters escaped"
	#[""]=""
);

#shows all indexes (default false)
showall=false;

#generate master password hash on first run,or if hash not set then prompt
if [ "$masterpassword" != "" ] || [ "$masterpasswordhash" == "" ];
then
	#check and make hash,set by user
	if  [ "$masterpassword" != "" ];
	then
	    #master password shown THIS TIME ONLY
		echo "The master password is: $masterpassword" 
		mphash=($(echo "$masterpassword" | $hashcommand ));
		echo "The master password hash is"
		#set the hash value as $masterpasswordhash, ignore " - " if it is at the end
		echo $mphash;
		echo "Set this value as masterpasswordhash and set masterpassword to "" to continue.";
	#master password hash is "", prompt and exit
	elif [ "$masterpasswordhash" == "" ];
	then
		echo "Please set masterpassword to continue.";
	fi;
	exit;
fi;

#try to find ${1^^} (case insensitive) in options and only allow whole-word matches then move on to check master passwords
opt=` echo "${!saltarray[@]}" | grep -iwso "${1^^}";`
if [ "$opt" != "" ];
then
	#echo "Entry exists.";
	#prompts for password # -r allows backslash
	read -p "Enter master password: " -r -s testpassword;
	echo;
	#hashing user-input password to compare with master
	testpasswordhash=($(echo $testpassword | $hashcommand ));
	if [ "$testpasswordhash" == "$masterpasswordhash" ];
	then
		echo "Generating password for [\"$opt\"]";
		#make hash and take first $maxpasswordlength (32 default) values
		#bash array returns array[0] when called without an index #epichack
		hash=($(echo "$testpassword${saltarray[$opt]}" | $hashcommand ))
		#encode base64 for more variation
		basencode=($(echo $hash | $encodecommand ));
		#display passwords
		echo "$hashcommand:" ${hash:0:$maxpasswordlength};
		echo "$encodecommand: " ${basencode:0:$maxpasswordlength};
		#sleep & clear
		echo "Clearing screen in $timeleft seconds...";
		sleep $timeleft;
		clear;
		exit;
	else
		#show message and exit
		echo "Password mismatch.";
		echo "Just fuck off..";
		exit;
	fi;

#else if no arguments or cannot get option
elif [ "$1" == "" ] || [ "$opt" == "" ];
then
	#echo nothing and set showall=true to display options
	showall=true;

else
	#show message and set showall=true to display options
	echo "Cannot find \"$1\".";
	showall=true;
fi;

#${1^^} = SHOW then print indexes from saltarray that can generate password and show usage
if [ "$1^^" == "SHOW" ] || [ $showall == true ] ;
then
	#show available indexes
	echo "Password options:";
	for index in "${!saltarray[@]}"; do echo "$index"; done;
	echo;
	#show usage
	echo "Usage:";
	echo "\$ $0       - first run -> set master password ang generate hash";
	echo "  after that..."
	echo "\$ $0       - show this help menu";
	echo "\$ $0 index - to get password for that index (needs master password)";
	echo "\$ $0 show  - to see available INDEXes";
fi;
exit;
