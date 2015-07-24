#!/bin/bash

# This file is part of Moodle - http://moodle.org/
#
# Moodle is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Moodle is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Moodle.  If not, see <http://www.gnu.org/licenses/>.
#
#
# CLI user registration script from a comma separated file.
#
# @package    tool_uploadusercli
# @copyright  2015 Alexandru Elisei
# @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later


test_file='tests.csv'
options="${1}"

create_text() {
	name=${1}
	expected=${2}
	columns=${3}
	values=${4}

	echo -e "\n-------------------------------------------------------------------"
	echo -e "\t\t${name} (expecting ${expected})"
	echo "${columns}" | tee "$test_file"
	echo "${values}" | tee -a "$test_file"
	echo "-------------------------------------------------------------------"
	echo -e "\n"
}

create_aux() {
	columns=${1}
	values=${2}
	sed -i 's/$processor->execute()/$processor->execute(new tool_uploaduser_tracker(tool_uploaduser_tracker::NO_OUTPUT))/' uploaduser.php
	sed -i 's/print "Done.\\n";/\/\/replace_me_with_print/' uploaduser.php
	echo "${columns}" > "$test_file"
	echo "${values}" >> "$test_file"
}

make_pristine() {
	sed -i 's/$processor->execute(new tool_uploaduser_tracker(tool_uploaduser_tracker::NO_OUTPUT))/$processor->execute()/' uploaduser.php
	sed -i 's/\/\/replace_me_with_print/print "Done.\\n";/' uploaduser.php
}

#new=`date|cut -d' ' -f1-4|sed 's/ //g'|sed 's/://g'`;
new=`date +%s`
make_pristine


# Creation (success)
no="1"
create_text "${no}. Creating" "success"\
	"username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createnew --file=${test_file} ${options}


# Deletion (success)
((no++))
create_text "${no}. Deleting" "success" \
	"username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} ${options} --allowdeletes


# Deletion (failure - deletes not allowed)
((no++))
create_aux "username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createnew --file=${test_file}
make_pristine

create_text "${no}. Deleting" "failure, deletes not allowed"\
	"username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} ${options}


# Deletion (failure - user does not exist)
((no++))
create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Deleting" "failure - user does not exist"\
	"username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} ${options} --allowdeletes


# Deletion (failure - user admin)
((no++))
create_text "${no}. Deleting" "failure - user admin"\
	"username,firstname,lastname,email,deleted" \
       	"admin,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} ${options} --allowdeletes


# Deletion (failure - user guest)
((no++))
create_text "${no}. Deleting" "failure - user guest"\
	"username,firstname,lastname,email,deleted" \
       	"guest,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} ${options} --allowdeletes


# Creation (failure - mnethostid invalid)
((no++))
create_text "${no}. Creation" "failure - mnethostid invalid"\
	"username,mnethostid" \
       	"$new,a"
php uploaduser.php --mode=createnew --file=${test_file} ${options}


# Creation (failure - invalid id)
((no++))
create_text "${no}. Creating" "failure - invalid id"\
	"username,firstname,lastname,email,id" \
       	"guest,$new,$new,$new@mail.com,a"
php uploaduser.php --mode=createnew --file=${test_file} ${options} --allowdeletes


# Creation (failure - missing fields)
((no++))
create_text "${no}. Creating" "failure - missing fields"\
	"username,firstname,lastname" \
       	"guest,$new,$new"
php uploaduser.php --mode=createnew --file=${test_file} ${options} --allowdeletes


# Creation (failure - user exists)
((no++))
create_aux "username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createnew --file=${test_file}
make_pristine

create_text "${no}. Creation" "failure - user exists"\
	"username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createnew --file=${test_file} ${options}

create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine


# Updating (failure - user does not exist)
((no++))
create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Updating" "failure - user does not exist"\
	"username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=update --file=${test_file} ${options}


# Renaming (failure - renaming not allowed)
create_aux "username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Renaming" "failure - renaming not allowed"\
	"username,firstname,lastname,email,oldusername" \
       	"newusername,$new,$new,$new@mail.com,$new"
php uploaduser.php --mode=update --updatemode=dataonly --file=${test_file} ${options}

create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine


# Renaming (failure - new user exists)
((no++))
create_aux "username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Renaming" "failure - new username exists"\
	"username,firstname,lastname,email,oldusername" \
       	"$new,$new,$new,$new@mail.com,$new"
php uploaduser.php --mode=update --file=${test_file} ${options} --allowrenames

create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine


# Renaming (failure - can not update)
((no++))
create_aux "username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Renaming" "failure - can not uptdate"\
	"username,firstname,lastname,email,oldusername" \
       	"newusername,$new,$new,$new@mail.com,$new"
php uploaduser.php --mode=update --updatemode=nothing --file=${test_file} ${options} --allowrenames

create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine


# Renaming (failure - oldusername does not exist)
((no++))
create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Renaming" "failure - oldusername does not exist"\
	"username,firstname,lastname,email,oldusername" \
       	"newusername,$new,$new,$new@mail.com,$new"
php uploaduser.php --mode=update --updatemode=dataonly --file=${test_file} ${options} --allowrenames


# Renaming (failure - can not rename, part 2)
((no++))
create_aux "username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Renaming" "failure - can not rename, part 2"\
	"username,firstname,lastname,email,oldusername" \
       	"newusername,$new,$new,$new@mail.com,$new"
php uploaduser.php --mode=createorupdate --updatemode=dataonly --file=${test_file} ${options}

create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine


# Renaming (success)
((no++))
create_aux "username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Renaming" "success"\
	"username,firstname,lastname,email,oldusername" \
       	"newusername,$new,$new,$new@mail.com,$new"
php uploaduser.php --mode=createorupdate --updatemode=dataonly --file=${test_file} ${options} --allowrenames

create_aux "username,firstname,lastname,email,deleted" \
       	"newusername,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine



# Renaming (failure - renaming admin)
((no++))
create_text "${no}. Renaming" "failure - renaming admin"\
	"username,firstname,lastname,email,oldusername" \
       	"newusername,$new,$new,$new@mail.com,admin"
php uploaduser.php --mode=createorupdate --updatemode=dataonly --file=${test_file} ${options} --allowrenames


# Renaming (failure - renaming guest)
((no++))
create_text "${no}. Renaming" "failure - renaming guest"\
	"username,firstname,lastname,email,oldusername" \
       	"newusername,$new,$new,$new@mail.com,guest"
php uploaduser.php --mode=createorupdate --updatemode=dataonly --file=${test_file} ${options} --allowrenames


# Creating (error - unknown auth)
((no++))
create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Creating" "error - unknown auth"\
	"username,firstname,lastname,email,auth" \
       	"$new,$new,$new,$new@mail.com,as"
php uploaduser.php --mode=createorupdate --updatemode=dataonly --file=${test_file} ${options} --allowrenames

create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine


# Creating (error - email duplicate)
((no++))
create_aux "username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Creating" "error - email duplicate"\
	"username,firstname,lastname,email" \
       	"newusername,$new,$new,$new@mail.com"
php uploaduser.php --mode=createorupdate --updatemode=dataonly --file=${test_file} ${options} --allowrenames

create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine


# Creating (warning - invalid email)
((no++))
create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Creating" "warning - invalid email"\
	"username,firstname,lastname,email" \
       	"$new,$new,$new,$new"
php uploaduser.php --mode=createorupdate --updatemode=dataonly --file=${test_file} ${options} --allowrenames

create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine


# Creating (warning - invalid lang)
((no++))
create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Creating" "warning - invalid lang"\
	"username,firstname,lastname,email,lang" \
       	"$new,$new,$new,$new@mail.com,asdf"
php uploaduser.php --mode=createorupdate --updatemode=dataonly --file=${test_file} ${options} --allowrenames

create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine


# Creating (error - password field missing)
((no++))
create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Creating" "error - password field missing"\
	"username,firstname,lastname,email" \
       	"$new,$new,$new,$new@mail.com"
php uploaduser.php --mode=createorupdate --updatemode=dataonly --file=${test_file} ${options} --allowrenames --passwordmode=field


# Creating (success - password auto-generated)
((no++))
create_aux "username,firstname,lastname,email,deleted" \
       	"$new,$new,$new,$new@mail.com,1"
php uploaduser.php --mode=createnew --file=${test_file} --allowdeletes
make_pristine

create_text "${no}. Creating" "success - password auto-generated"\
	"username,firstname,lastname,email,password" \
       	"$new,$new,$new,$new@mail.com,a"
php uploaduser.php --mode=createorupdate --updatemode=dataonly --file=${test_file} ${options} --allowrenames --passwordmode=field --forcepasswordchange=weak
