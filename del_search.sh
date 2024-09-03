#!/bin/bash

INPUT_DIR="$(basename "$1")"
FILE_LIST="${INPUT_DIR}_file_list.txt"

declare -A size_arr
expr_arr=()

tmp_dir="${INPUT_DIR}_$(date +%F)"
tmp_dir_path="$(pwd)/$tmp_dir"

mkdir -p "$tmp_dir"

move_to_tmp() {
	local path exp_sum file_name size
	while read -r path; do 
		file_name="$(basename "$path")"
		size="$(stat -c "%s" "$path")"
		exp_sum=${size_arr["${size}"]} > /dev/null 2>&1 || return
		# sum="$(md5sum "$path" | awk '{ print $1 }')"
		sum="$(md5sum "$path")"
		sum="${sum%% *}"

		echo "Found file $path, actual size: $size, expected md5: $exp_sum, actual md5: $sum"
		for curr_sum in $exp_sum; do
			if [[ "$sum" == "$curr_sum" ]]; then
				echo "Moving file $path"
				mv "$path" "$tmp_dir_path/$(mktemp -u "$file_name.XXXXXX")"
			fi
		done
	done
}

if [ ! -f "$FILE_LIST" ]; then
	find "$1" -type f -exec sh -c 'echo "$(stat -c "%s" "$1")|$(md5sum "$1")"' _ "{}" \; | awk '{ print $1 }' >> "$FILE_LIST"
fi


while IFS='|' read -r size sum; do
    echo "$size $sum"
    size_arr["$size"]+=" $sum"
done < <(cat "$FILE_LIST")

for i in "${!size_arr[@]}"; do 
    [ ${#expr_arr[@]} -ne 0 ] && expr_arr+=(-o)
	expr_arr+=(-size "${i}c")
done

echo "${expr_arr[@]}"

find / -type f \( "${expr_arr[@]}" \) | move_to_tmp
