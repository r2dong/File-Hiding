#!/bin/bash

ignoreP=false # assume not ignoring P at first
pArgIndex=0 # index to store next arugument after -p

# debug messages
debug () {
	echo "arugment list: $@"
	echo "option is $option"
	echo "OPTARG is $OPTARG"
	echo "OPTIND is $OPTIND"
	echo "exit status was $?"
}

# when attempting to unzip but no secret file is present
# pass in the current directory as an argument
noSecret () {
	echo "No \".secret\" found at $1" # error message 
	exit 1 # exist program with code 1
}

# print usage and exist when input arguments are invalid
usage () {
	echo 'Usage: ./hide.sh [OPTIONS] PATH [PATH...]'
	exit 2
}

# zip files, $1 = P/N, if P then ask for password
zipFile () {

	# determine if password is needed (calling from -p option)
	needPassword=$1
	# left only file names 
	shift 1

	# if password needed
	if [ "$needPassword" == 'P' ]; then
		# handle password
		echo 'Enter password:'
		read -s passwd
	fi
	
	
	# zip all files passed in
	for filePath in $@ # filePath is full path to file
	do
		dir=`dirname "$filePath"` # directory to file
		base=`baseName $filePath` # file name
		destDir="$dir"'/.secret' # destination path
		
		# zipping files
		if [ -f $filePath ]; then  
			
			# make sure that destination directory exist
			mkdir -p "$destDir"
			
			# do the zipping
			if [ "$needPassword" == 'P' ]; then # zip if need password
				zip -quiet -P $passwd "$destDir"'/'"$base"'.zip' "$filePath"
			else # zip if no need for password
				zip -quiet "$destDir"'/'"$base"'.zip' "$filePath"
			fi

			# remove the source file
			rm "$filePath"

		# zipping directories
		elif [ -d $filePath ]; then
			if [ "$needPassword" == 'P' ]; then # zip if need password
				# place zip file in current directory 
				zip -quiet -P $passwd "$base"'.zip' "$filePath"
			else # zip if no password needed 
				zip -quiet "$base"'.zip' "$filePath"
			fi

			# remove the original directory
			echo "removing $dir"
			rm -r "$filePath"
			# create destination directory
			echo "making $destDir"
			mkdir -p "$destDir"
			# move the file to the destination directory
			mv './'"$base"'.zip' "$destDir"'/'"$base"'.zip'

		else # not valid file/directory
			echo "Failed to hide invalid file: $filePath"
			continue
		fi
	done

	# exit the program after finished zipping			
	exit 0;
}

# unzips the given directory, pass in directory containing .secret folder as argument
unZip () {

	secretPath="$1"'/.secret'

	# check if the .secret directory exists
	if [ -d $secretPath ]; then
		noSecret $secretPath 
	# iterate and unzip everything insdie .secret
	else
		# store file names from secret folder 
		fileNames=( $(ls $secretPath) )

		# iterate through all files
		for file in fileNames
		do 
			# unzip to current directory 
			unzip "$secretPath"'/'"$file"

			# remove the zip file if unzip was successfull
			if [ "$?" == '0' ]; then
				rm "$secretPath"'/'"$file"
			fi
		done

		# check if the secret folder is empty
		fileName=( $(ls $secretPath) )
		if [ -z "$fileName" ]; then
			# remove the secret path
			rm -r $secretPath
		fi
		exit 0
	fi
}

# parse command line argument
while getopts ":u:p:" option; do

	# switch case based on option	
	case $option in
		# option ?, when not supported flag recieved
		'?')
			echo 'not supported flag'
			usage;;
		
		# option :, when u or p did not receive argument
		':')
			echo no 'argumet recieved'
			usage;;
		# option u, expect only one 
		'u')
			lastOption=u # store the option last processed
			uArg="$OPTARG" # arguments following u
		
			# check if an valid argument is passed in
			if [ `echo $OPTARG | head -c 1` == - ]
			then
				echo 'u: invalid argumet'
				usage
			fi
			
			# unzip
			unZip $uArg
		# option p, multiple arguments possible	
		'p') 
			pArg[$pArgIndex]="$OPTARG" # store argument
			shift $((OPTIND-1)) # shift so $1 is next argumetn to store

			# keep storing while encoutering another option 
			while [ "`echo $1 | head -c 1`" != '-' ]; do
			
				#  zip files passed in if reached end of arguments
				if [ -z $1 ]
				then
					zipFile 'P' ${pArg[@]}
				fi

				pArgIndex=$((pArgIndex+1)) # increment index
				pArg[$pArgIndex]=$1 # store next argument
				shift 1 # position next argument at $1
				OPTIND=$((OPTIND+1)) # sync OPTIND
			done;;
	esac
done

# if getopts return 1 (false), no flag given, treat all arguments as bases to be hidden
# if no argument at all
if [ -z "$1" ]; then
	usage
# otherwise zip with no password all arguments
else
	zipFile 'N' $@
fi
