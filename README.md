
# Overview
Files and directories are hided from their original directories. Password can be used optionally for unhiding. 
This was a class project at the University of California, San Diego.
# Synopsis
hide.sh [OPTIONS] PATH [PATH...]
# Description
Performs actions specified (hide or unhide) on files and directories provided.
* -p<br>
  Prompt user for password when hiding. Ignored when unhiding.
* -u<br>
  This option takes exactly 1 argument, which is path to directory containing the hidden files and directories. It then unhides all hidden 
  files under the given directory. Password may be prompted, if one is used when hiding.<br>
  <br>
  When run with this flag, the -p flag will be ignored.
