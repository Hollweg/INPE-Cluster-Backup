#/bin/bash

echo " "
echo "#######     VMs Backup Script           #######" 
echo "####### Developed by Guilherme Hollweg  #######"
echo "#######    Last Update: 10/2016         #######"
echo " "

echo " "
echo "Acessing server to acquire actual date"

ssh root@virt "date +%e > date.txt ; date +%m >> date.txt ; date +%y >> date.txt"
ssh root@virt 'day=`cat date.txt | head -n1`; month=`cat date.txt | tail -n2 | head -n1`; year=`cat date.txt | tail -n1`; 
echo day: $day month: $month and year: 20$year' > /$pathLocal/date.txt

day=`cat /$pathLocal/date.txt | cut -f2 -d" "` ;
month=`cat /$pathLocal/date.txt | cut -f4 -d" "` ;
year=`cat /$pathLocal/date.txt | cut -f7 -d" "` ;

#Acess cluster and return the name of last backup folder
echo "Starting VMs backup in ($day-$month-$year)"
echo ""

echo "Verifying the existence of folder in backup HDD..."
hddFolder="backup_folder"
cd $pathBackup
if [ -d "$hddFolder" ];
then
	echo "The backup folder exists!"
else
	echo "The backup folder did not exists. Creating it..."
	mkdir backup_folder
	echo "Folder created. Continuing backup!"
fi

echo ""
echo "Changing directory and creating backup folder..."

#Saves day number to verify the cut field
ssh root@virt "date +%d" > /$pathBackup/folderName.txt
day=`cat /$pathBackup/folderName.txt`

if test $day -lt 10
then
	ssh root@virt "cd /$pathVirt/ ; ls -lrt | tail -n1 | cut -f10 -d' ' " > /$pathBackup/folderName.txt
else
	ssh root@virt "cd /$pathVirt/ ; ls -lrt | tail -n1 | cut -f9 -d' ' " > /$pathBackup/folderName.txt
fi

folderName=`cat /$pathBackup/folderName.txt` 
echo "Last backup date on server: $folderName."
echo " "

#Check if the folder did not exists in backup, if exists do not copy it.
cd /$pathBackup/
if [ -d "$folderName" ];
then 
    echo "Folder relative to day $folderName found and backup is not needed."
    echo " "
else
	echo "Acessing virtualize server to copy data..."
	echo "Copying data..."
	scp -r root@virt:/$pathVirt/$folderName /$pathBackup/$folderName/
	echo " "
	#list backup directories to user
	echo "ls /$pathBackup/"
	ls /$pathBackup/
	echo " "

	echo "ls /$pathBackup/$folderName/"
	ls /$pathBackup/$folderName/
	echo " "
	echo "Verifying the backup folder and deleting the old one..."
	echo " "

	#Verify empty folder -- OK
	echo "Testing if backup folder is non empty..."
	empty=`ls /$pathBackup/$folderName/ | wc -l`
	echo "Number of files in backup folder: $empty."
	
	if test $empty -eq 0
	then
		echo "Folder $folderName is empty."
		echo "Removing empty folder..."
		rmdir /$pathBackup/$folderName/
		echo "Done."
		echo " "
	else
		echo "Folder $folderName is not empty."
		echo " "
		
		#Verify folder size > 500GB
		echo "Testing if backup folder have a reasonable size..."
		cd /$pathBackup/ ;
		size=`du -sm * | grep $folderName | cut -f1 -d'	'`		
		echo "New backup folder size: $size."
		
		if test $size -gt 500000
		then
			echo "Backup folder OK!"
			echo "Deleting old backup folder..."
			
		        #Save the folder name to be postpone deleted in the next backup in the file $filename.txt
			numberFolders=`ls | wc -l`
			if test $numberFolders -gt 1
			then
			    oldFolder=`cat /$pathLocal/oldFolder.txt`
			    echo "An old backup folder was found: $oldFolder"
			    echo "Deleting it..."
			    rm -rf /$pathLocal/$oldFolder/
			    echo "Folder deleted."
			    echo "$folderName" > /$pathLocal/oldFolder.txt
			else
		            echo "$folderName" > /$pathLocal/oldFolder.txt
			fi
			
			echo "Done!"
			echo " "

			ssh root@virt "date +%e > date.txt ; date +%m >> date.txt ; date +%y >> date.txt"
			ssh root@virt 'day=`cat date.txt | head -n1`; month=`cat date.txt | tail -n2 | head -n1`; year=`cat date.txt | tail -n1`;echo day: $day month: $month and year: 20$year' > /$pathLocal/date.txt

			day=`cat /$pathLocal/date.txt | cut -f2 -d" "` ;
			month=`cat /$pathLocal/date.txt | cut -f4 -d" "` ;
			year=`cat /$pathLocal/date.txt | cut -f7 -d" "` ;

			echo " "
			echo "Backup done in ($day-$month-$year)!"
			echo " "

		else
			echo "Backup folder not OK..."
			echo "Backup not sucessful!"
			rm -rf /$pathBackup/$folderName/
			echo " "
		fi

	fi

fi

#Deleting additional folders
echo "Deleting additional files..."
rm -f /$pathBackup/folderName.txt
rm -f /$pathLocal/date.txt
ssh root@virt "rm -f ./date.txt"
echo "Done!"

