#!/bin/bash

INPUT_DIR="$(basename "$1")"
FILE_LIST="${INPUT_DIR}_file_list.txt"

declare -A size_arr
expr_arr=()

tmp_dir="${INPUT_DIR}_$(date +%F)"
tmp_dir_path="$(pwd)/$tmp_dir"

mkdir -p "$tmp_dir"

move_to_tmp() {
	local path exp_size file_name size
	while read -r path; do 
		file_name="$(basename "$path")"
		exp_size=${size_arr["${file_name}"]}
		size="$(stat -c %s "$path")"
		echo "Found file $path, expected sizes: $exp_size, actual size: $size"
		for curr_size in $exp_size; do
			if [ "$size" -eq "$curr_size" ]; then
				echo "Moving file $path"
				mv "$path" "$tmp_dir_path/$(mktemp -u "$file_name.XXXXXX")"
			fi
		done
	done
}

if [ ! -f "$FILE_LIST" ]; then
	find "$1" -type f -exec stat -c "%n|%s" "{}" \; | rev | cut -d '/' -f1 | rev >> "$FILE_LIST"
fi


while IFS='|' read -r name size; do
    echo "$name $size"
    size_arr["$name"]+=" $size"
done < <(cat "$FILE_LIST")

for i in "${!size_arr[@]}"; do 
    [ ${#expr_arr[@]} -ne 0 ] && expr_arr+=(-o)
	expr_arr+=(-name "$i")
done

echo "${expr_arr[@]}"

find / -type f \( "${expr_arr[@]}" \) | move_to_tmp
