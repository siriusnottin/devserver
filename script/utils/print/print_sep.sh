#!/bin/bash

# Prints a custom separator with a given message.
# Usage: sep [ [f|--full]|[c|--center]|[l|--left]|[r|--right]|[tb|--top-bottom] [[t|--text-only] <text>] ]
sep() {

	if [ -z "$1" ]; then

		# new empty line instead of separator if no arguments
		printf "\n"

	else
		local separator="="
		local margins=0
		local text_wrap=2 # ex: "text" will be wrapped in 2 spaces

		local marginslr=$((margins / 2))

		local width=$(tput cols)

		local text_length=$(printf "%s" "$2" | wc -c)
		local sep_length=$((($width - $text_length) - ($margins + $text_wrap)))

		local half_separator=""
		for ((i = 0; i < $(($sep_length / 2)); i++)); do
			half_separator+="$separator"
		done

		local full_separator=$(printf "%s%s" "$half_separator$half_separator")

		repeat() {
			local text="$1"
			local repeat_times="$2"
			local repeat_text=""
			for ((i = 0; i < $repeat_times; i++)); do
				repeat_text+="$text"
			done
			printf "%s" "$repeat_text"
		}

		text_wrap() {
			local text_wraplr=$((text_wrap / 2))
			repeat " " $text_wraplr # left margin
			printf "%s" "${1}"
			repeat " " $text_wraplr # right margin
		}

		if [ ! -z "${1// /}" ]; then

			if [ "$#" -eq 1 ]; then
				printf "\n"
			fi
			case "$1" in
			-f | --full)
				printf "%s\n" "$full_separator"
				;;
			-c | --center)
				repeat " " $marginslr
				printf "%s" "$half_separator"
				text_wrap "$2"
				printf "%s\n" "${half_separator}"
				repeat " " $marginslr
				;;
			-l | --left)
				repeat " " $marginslr
				text_wrap "$2"
				printf "%s\n" "${full_separator}"
				repeat " " $marginslr
				;;
			-r | --right)
				repeat " " $marginslr
				printf "%s" "${full_separator}"
				text_wrap "$2"
				repeat " " $marginslr
				;;
			-tb | --top-bottom)
				local full_separator_alt=${full_separator}
				sep
				message -m "# $full_separator_alt"
				text_wrap "$2"
				sep
				message -m "$full_separator_alt #"
				sep
				;;
			-t | --text-only)
				text_wrap "$2"
				printf "\n"
				;;
			*)
				error -e "Unknown option: $1; $usage"
				;;
			esac
			shift $((OPTIND - 1))
		fi

	fi
}

step() {
	sep -tb "$1"
}
