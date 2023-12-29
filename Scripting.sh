#!/bin/bash

set -euo pipefail # used to ensure that the script exits immediately if any command fails or if any variables are unset

#Function to display the menu
display_menu() {
echo " "
echo "Menu: "
echo " "
echo "1. List all"
echo "2. Display Info"
echo "3. Count Students"
echo "4. Delete Student"
echo "5. Backup"
echo "6. Exit"
echo "7. Help" # I added the helper option to promote better user experience  by providing quick reference to understand what each menu option does
echo "------------------"
}

# Function to list all the students' information (Name Last-Name ID)
list_all() {
    echo " "
    # Find all .txt files in the CurrentStudents folder, sort by surname, convert to Unix format and display the first line

     find CurrentStudents -name '*.txt' -exec sh -c "head -n 1 {} | awk -F ', ' '{print \$2, \$1, \$3}'" \; | sort
    # you may encounter problems with the way the line breaks are represented
    # This is particularly useful when working with files that have been created or modified on different platforms that use different line endings
    # Both standard output and standard error are redirected to /dev/null to ensure that all output generated by dos2unix is suppressed
}

# Function to display all students' ID, major, and GPA
display_info() {
    echo " "

    # Loop through all .txt files in the CurrentStudents folder
    for file in CurrentStudents/*.txt; do
        # Extract ID from first line of the file
        id=$(head -n 1 "$file" | awk '{print $NF}')

        # Extract gpa from second line of the file
        gpa=$(awk '/GPA/ {printf $2}' $file)

        # Extract major from third line of the file
        major=$(grep "Major" "$file" | awk -F ': ' '{print $NF}')

        all="$id $gpa $major"

        # Creates student_info.txt and ppend the extracted info to it on the same line
        echo "$all"  | tee -a student_info.txt
    done
    
    # Display message when completed
    echo "Student info has been extracted and saved to student_info.txt."
}

#Function to count the number of students per major
count_students() {
  # Find all .txt files in the CurrentStudents folder, extract the major and count the occurrences of each major
  find CurrentStudents -name '*.txt' -exec sh -c "awk -F ': ' '/Major/ { print \$2 }' {}" \; | sort | uniq -c | sort -nr
}

 
# Function to delete a student's file
delete_student() {
    echo " "
    # Loop until a valid 9-digit ID is entered
    while true; do
        # Prompt the user for the student ID
        read -p "Enter the ID of the student you wish to delete: " student_id
        # Check if the student ID is valid (9 digits long)
        if [[ $student_id =~ ^[0-9]{9}$ ]]; then
            break # Exit the loop if the ID is valid
        fi
        # Display an error message and continue the loop
        echo "Invalid student ID. Please enter a 9-digit ID."
    done
    # Check if the file exists
    if [[ ! -f CurrentStudents/$student_id.txt ]]; then
        echo "Student with ID $student_id does not exist."
        return
    fi
    # Prompt the user for confirmation
    read -p "Are you sure you want to delete the file for student with ID $student_id? [y/N] " confirm 
    lowercase_confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    # add confirmation prompts to prevent accidental data loss
    if [[ $lowercase_confirm != [yY] ]]; then
        echo "Aborted."
        return
    fi
    # Delete the file
    rm CurrentStudents/$student_id.txt
    echo "Student with ID $student_id has been deleted."
}

# Function to create a backup folder for the students’ database
backup() {
    # check if CurrentStudents directory exists
    if [ ! -d "CurrentStudents" ]; then
        echo "Error: CurrentStudents directory does not exist."
        return 1
    fi
    # create the backup folder with the current date in the format day_FullMonthName_Last2DigitsYear
    backup_folder="CurrentStudents.$(date +%d_%B_%y)"
    if [ -d "$backup_folder" ]; then
  	# If it exists, remove the existing directory
  	# Prompt the user for input
	read -p "File already exists, do you want to replace it? [y/n]: " choice
	
	#make the choice lowercase to prevent errors if choice was Uppercase
	lowercase_choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
	# Check the user's choice
	if [[ "$lowercase_choice" == "yes" || "$lowercase_choice" == "y" ]]; then
	#if choice was yes, remove old folder and create a new one
	  rm -r "$backup_folder"
  	  echo "Replacing the file..."
  	  mkdir "$backup_folder"
  	  echo "Backup of CurrentStudents folder has been created in $backup_folder"
  	# Add your code here for replacing the file
	elif [[ "$lowercase_choice" == "no" || "$lowercase_choice" == "n" ]]; then
  	  echo "File not replaced."
  	#if choice was not yes neither no
	else
  	  echo "Invalid choice. Exiting..."
	fi  
    else	
        echo "Backup of CurrentStudents folder has been created in $backup_folder"
    fi
    
    # copy all files from the CurrentStudents folder to the backup folder and show progress
    rsync -a --info=progress2 CurrentStudents/ "$backup_folder"  #rsync allows us to create a full backup of the "CurrentStudents" folder easily
    # --info=progress2 is useful when errors may arise during the backup process since it can help users identify the specific files that are causing errors and take appropriate action to resolve the issue
}

# Function to display help information
# It provides clear and concise explanations for each of the menu options and what they do
show_help() {
    echo " "
    echo "Below you may find the use of each function : "
    echo " "
    echo "1) list_all: The information found on the first line of each file will be displayed for all the students, one student per line, sorted in alphabetical order according to student surname "
    echo "2) display_info: Display Info: A file containing all Students ID, Major and GPA is created and displayed (one student per line) "
    echo "3) count_students: The number of students per major is displayed in a reverse numerical number"
    echo "4) delete_student: Enter the ID of the student to delete its file from the database"
    echo "5) backup: A backup folder for the students’ database is created with the date, at the time of the operation, added to the name of the folder (CurrentStudents.Date)"
    echo " "
}

# Display an interactive welcome message using whiptail
# The user is presented with a dialog box explaining the purpose of the program and is prompted to click the "Next" button to proceed
# The dialog box has a title, a message, and an "OK" button labeled "Next"
# The dialog box size is set to 10 lines by 60 columns
whiptail --title "Welcome!" --msgbox "Welcome to the Academic Assistant Program!\n\nThis program will assist you in managing the students who are currently enrolled in the different majors offered by the Department of Computer Science and Mathematics.\n\nClick Next to continue." 15 65 --ok-button "Next"


# Loop until the user chooses to exit
while true
 do
 #display the menu
 display_menu
 #prompt the user for their choice
 read -p "Enter your choice: " choice2
 #check if the choice is valid (between 1 and 6)
 if [[ ! $choice2 =~ ^[1-7]$ ]]; then
  echo "Invalid choice. Please enter a number between 1 and 7."
  continue
 fi
 #execute the corresponding function based on the user's choice
 case $choice2 in
  1) list_all ;; 
  2) display_info ;;
  3) count_students ;;
  4) delete_student ;;
  5) backup ;;
  6) echo "Goodbye!" ; exit ;;
  7) show_help;; # provides the user with quick reference information
 esac
done
