#!/bin/bash

test_file='test.csv'
debuglevel="${1}"

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
	echo "${columns}" > "$test_file"
	echo "${values}" >> "$test_file"
}

make_pristine() {
	sed -i 's/$processor->execute(new tool_uploaduser_tracker(tool_uploaduser_tracker::NO_OUTPUT))/$processor->execute()/' uploaduser.php
}

#new=`date|cut -d' ' -f1-4|sed 's/ //g'|sed 's/://g'`;
new=`date +%s`


no="1"
create_text "${no}. Creating" "success"\
	"username,firstname,lastname,email" \
       	"${new},${new},${new},${new}@mail.com"
php uploaduser.php --mode=createnew --file=test.csv ${debuglevel}


((no++))
create_text "${no}. Deleting" "success" \
	"username,firstname,lastname,email,deleted" \
       	"${new},${new},${new},${new}@mail.com,1"
php uploaduser.php --mode=createnew --file=test.csv ${debuglevel} --allowdeletes


((no++))
create_aux "username,firstname,lastname,email" \
       	"${new},${new},${new},${new}@mail.com"
php uploaduser.php --mode=createnew --file=test.csv
make_pristine

create_text "${no}. Deleting" "failure, deletes not allowed"\
	"username,firstname,lastname,email,deleted" \
       	"${new},${new},${new},${new}@mail.com,1"
php uploaduser.php --mode=createnew --file=test.csv ${debuglevel}

create_aux "username,firstname,lastname,email,deleted" \
       	"${new},${new},${new},${new}@mail.com,1"
php uploaduser.php --mode=createnew --file=test.csv --allowdeletes
make_pristine


# TEST 4
