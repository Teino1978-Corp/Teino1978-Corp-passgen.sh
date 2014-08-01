#!/bin/bash

#simple password geenrator based on sha1 hashing and base64 encoding.
#needs grep,read and sha1sum, base64
#written in bash 4.3.18
#
#added case-insensitivity in "INDEX"
#added master password hash generation
#added timing - clear screen after a time
#added hash based pasword checking (prompting for master password)
#added base64 encode for more variation >> more entropy
#added variable length passwords, can specify length in saltarray
#
#USAGE:
#set hash of masterpassword, define index and salt in $saltarray, pass index as argument, and get returned password. (use either hash or encoded)
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

#separator character for separating salt and password length in saltarray
separator="//";

#salts for passwords using named indexes...use moderately secure ones, but this is almost useless without the master password
#put the servicename as <index> and the salt ( any string actually, e.g username or description) as the <value>//<number of characters in password> #maintain spacings
declare -A saltarray=(
#example
	#["<index>"]="<value>//<length>"
#	["SERVICE"]="add some salt//length of generated password"
#	["GMAIL"]="the big old gmail salt is to be put here//16"
	#[""]="//"
);

#shows all indexes (default false)
showall=false;

#generate master password hash on first run,or if hash not set then prompt
if [ "$masterpassword" != "" ] || [ "$masterpasswordhash" == "" ];
then
	#check and make hash,set by user
	if  [ "$masterpassword" != "" ];
	then
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
		#read salt and length from saltarray, split them by $separator
		#bash array returns array[0] when called without an index #epichack
		pwdlength="${saltarray[$opt]##*$separator}";
		salt="${saltarray[$opt]%$separator*}";
		#no salt then prompt and exit
		if [ "$salt" == "" ]; then echo "No value in salt, exiting..."; exit; fi;
		#if no length field then pwdlength==salt, change it to maxpasswordlength
		if [ "$pwdlength" == "$salt" ]; then let pwdlength=$maxpasswordlength; fi;	
		echo "Generating password for index: [\"$opt\"]";
		#make hash and take first $passwordlength (32 default) values
		hash=($(echo "$testpassword$salt" | $hashcommand ))
		#encode base64 for more variation
		basencode=($(echo $hash | $encodecommand ));
		#display passwords
		echo "Hashes for consistency, encodes for more entropy..."
		echo "$hashcommand:" ${hash:0:$pwdlength};
		echo "$encodecommand: " ${basencode:0:$pwdlength};
		#sleep & clear
		echo "Clearing screen in $timeleft seconds...";
		sleep $timeleft;
		clear;
		exit;
	else
		#show message and exit
		echo "Password mismatch.";
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
if [ "${1^^}" == "SHOW" ] || [ $showall == true ] ;
then
	#show available indexes
	echo "Password options:";
	for index in "${!saltarray[@]}"; do echo "$index"; done;
	#show usage
	echo "Usage:";
	echo "\$ $0       - first run -> set master password ang generate hash";
	echo "  after that..."
	echo "\$ $0       - show this help menu";
	echo "\$ $0 index - to get password for that index (needs master password)";
	echo "\$ $0 show  - to see available indexes";
	exit;
fi;