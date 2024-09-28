# this is the AppleScript that is used to compile the converter
# you must have a Mac to use this

# don't time out
with timeout of 1.0E+300 seconds
	
	# fix to use 32-bit JVM if it exists
	# even if there is another one before it in the PATH
	# if there is an error about "does not support a 32-bit JVM" then install this:
	# https://support.apple.com/kb/dl1572
	set JAVA_PATH_FIX to "export PATH=\"/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home/bin:$PATH\"; "
	
	# get a unique folder name
	set unique to (do shell script "date +%s")
	
	# locations
	set homePath to (do shell script "cd ~/; pwd")
	set tempPath to homePath & "/Desktop/Converter Build " & unique
	set projectorTempPath to tempPath & "/Projector"
	set projectorSwfPath to projectorTempPath & ".swf"
	set converterTempPath to tempPath & "/Converter"
	set converterSwfPath to converterTempPath & ".swf"
	set zipTempPath to tempPath & "/Distribution"
	set zipTempSourcePath to zipTempPath & "/Source Code"
	set zipPath to tempPath & "/Distribution.zip"
	
	# required files
	set scriptPath to POSIX path of (path to me)
	set scratchPath to POSIX path of (choose folder with prompt "Choose the Scratch source code root directory.
This should contain several files and folders, including \"src\".

You can download this from \"https://github.com/LLK/scratch-flash/releases\".")
	set loaderPath to POSIX path of (choose folder with prompt "Choose the Loader folder.
This should contain \"SB2Loader.as\".")
	set converterPath to POSIX path of (choose folder with prompt "Choose the Converter folder.
This should contain \"Converter.as\".")
	set sdkPath to POSIX path of (choose folder with prompt "Choose the Flex SDK root directory.
This should contain many files and folders, including \"bin\".

You can download this from \"https://www.adobe.com/devnet/flex/flex-sdk-download.html\".")
	set htmlPath to POSIX path of (choose file with prompt "Choose the HTML converter wrapper.")
	
	# create temporary folder
	do shell script "mkdir -p " & quoted form of tempPath
	
	# get alias of temporary folder
	set tempAlias to POSIX file tempPath as text
	
	# copy Scratch source code to temporary folder
	do shell script "cp -R " & quoted form of scratchPath & " " & quoted form of projectorTempPath
	
	# copy Loader source code to temporary folder
	do shell script "cp -R " & quoted form of loaderPath & " " & quoted form of (projectorTempPath & "/src/Loader/")
	
	# make folder for the converter
	do shell script "mkdir " & quoted form of converterTempPath
	
	# copy the converter to the temporary folder
	do shell script "cp -R " & quoted form of converterPath & " " & quoted form of converterTempPath
	
	# write the "ThisIsTheSB2File" 80 bytes (must be > 62 for long header) Scratch project
	do shell script "printf ThisIsTheSB2FileThisIsTheSB2FileThisIsTheSB2FileThisIsTheSB2FileThisIsTheSB2File > " & quoted form of (projectorTempPath & "/src/Loader/Project.sb2")
	
	# write the settings string which will later be searched in the SWF
	do shell script "printf ThisIsTheSettingsFile > " & quoted form of (projectorTempPath & "/src/Loader/Settings.txt")
	
	# compile the projector
	do shell script JAVA_PATH_FIX & quoted form of (sdkPath & "bin/mxmlc") & " --compiler.define=SCRATCH::allow3d,false --compiler.define+=SCRATCH::revision,0 " & quoted form of (projectorTempPath & "/src/Loader/SB2Loader.as") & " -default-size=550,400 -use-network=false --compiler.source-path+=" & quoted form of (projectorTempPath & "/src/") & " --compiler.library-path+=" & quoted form of (projectorTempPath & "/libs/") & " --static-link-runtime-shared-libraries=true --compiler.compress=false -output " & quoted form of projectorSwfPath
	
	# get the alias of the SWF
	set projectorSwfAlias to (POSIX file projectorSwfPath) as alias
	
	# read the SWF file
	set projectorSwfData to read projectorSwfAlias
	
	# figure out which converter-added binary file comes first in the projector bytecode
	set sb2Offset to offset of "ThisIsTheSB2File" in projectorSwfData
	set settingsOffset to offset of "ThisIsTheSettingsFile" in projectorSwfData
	if sb2Offset < settingsOffset then
		set smallerOffset to sb2Offset
		set largerOffset to settingsOffset
		set firstBinaryEnd to sb2Offset + 80
		set secondBinaryEnd to settingsOffset + 21
		set orderFile to "1"
	else
		set smallerOffset to settingsOffset
		set largerOffset to sb2Offset
		set firstBinaryEnd to settingsOffset + 21
		set secondBinaryEnd to sb2Offset + 80
		set orderFile to "0"
	end if
	
	# make parts
	set partHeader to read projectorSwfAlias from 1 to 4
	if orderFile = "1" then
		set partChunkBefore to read projectorSwfAlias from 18 to (smallerOffset - 11)
	else
		set partChunkBefore to read projectorSwfAlias from 18 to (smallerOffset - 1)
	end if
	set partSB2Header to read projectorSwfAlias from sb2Offset - 6 to sb2Offset - 1
	if orderFile = "1" then
		set partChunkBetween to read projectorSwfAlias from firstBinaryEnd to largerOffset - 1
	else
		set partChunkBetween to read projectorSwfAlias from firstBinaryEnd to largerOffset - 11
	end if
	set partChunkAfter to read projectorSwfAlias from secondBinaryEnd
	
	# make the data files
	do shell script "touch " & quoted form of (converterTempPath & "/PartHeader.bin")
	do shell script "touch " & quoted form of (converterTempPath & "/PartChunkBefore.bin")
	do shell script "touch " & quoted form of (converterTempPath & "/PartSB2Header.bin")
	do shell script "touch " & quoted form of (converterTempPath & "/PartChunkBetween.bin")
	do shell script "touch " & quoted form of (converterTempPath & "/PartChunkAfter.bin")
	
	# write the data files
	set converterTempAlias to POSIX file converterTempPath as text
	write partHeader to ((converterTempAlias & ":PartHeader.bin") as alias)
	write partChunkBefore to ((converterTempAlias & ":PartChunkBefore.bin") as alias)
	write partSB2Header to ((converterTempAlias & ":PartSB2Header.bin") as alias)
	write partChunkBetween to ((converterTempAlias & ":PartChunkBetween.bin") as alias)
	write partChunkAfter to ((converterTempAlias & ":PartChunkAfter.bin") as alias)
	
	# make order file which communicates the order to the converter
	do shell script "touch " & quoted form of (converterTempPath & "/Order.bin")
	
	# compiling with AIR SDK's mxmlc, it reads the order file as expected
	# it seems that when compiling with Flex SDK's mxmlc, this only works if the file is at least 4 bytes
	# looks like a bug in the compiler to me
	# in any case, this fixes it
	set orderFileFixed to orderFile & "   "
	write orderFileFixed to ((converterTempAlias & ":Order.bin") as alias)
	
	# compile the converter
	do shell script JAVA_PATH_FIX & quoted form of (sdkPath & "bin/mxmlc") & " " & quoted form of (converterTempPath & "/Converter.as") & " --compiler.source-path+=" & quoted form of converterTempPath & " --static-link-runtime-shared-libraries=true -output " & quoted form of converterSwfPath
	
	# make the zip temporary folder
	do shell script "mkdir " & quoted form of zipTempPath
	
	# make the source code folder in the zip temporary folder
	do shell script "mkdir " & quoted form of zipTempSourcePath
	
	# copy Loader folder to zip temporary folder
	do shell script "cp -R " & quoted form of loaderPath & " " & quoted form of (zipTempSourcePath & "/Loader")
	
	# copy converter folder to zip temporary folder
	do shell script "cp -R " & quoted form of converterPath & " " & quoted form of (zipTempSourcePath & "/Converter")
	
	# copy this script to zip temporary folder
	do shell script "cp " & quoted form of scriptPath & " " & quoted form of (zipTempSourcePath & "/Build.applescript")
	
	# copy converter to zip temporary folder
	do shell script "cp " & quoted form of converterSwfPath & " " & quoted form of (zipTempPath & "/Converter.swf")
	
	# copy HTML converter wrapper to zip temporary folder
	do shell script "cp " & quoted form of htmlPath & " " & quoted form of (zipTempPath & "/Converter.html")
	
	# zip the zip temporary folder
	do shell script "cd " & (quoted form of zipTempPath) & "; zip -x \"*.DS_Store\" -r " & quoted form of zipPath & " ."
	
	# reveal the zip file in Finder
	do shell script "open -R " & quoted form of zipPath
	
	# ending dialog
	tell application "Finder" to display dialog "Finished building the converter." buttons "OK" default button 1
end timeout