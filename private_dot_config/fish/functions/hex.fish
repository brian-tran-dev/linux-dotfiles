function hex
	echo "ibase=10;obase=16; $argv[1]" | bc
end
