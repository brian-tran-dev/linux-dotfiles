function ssh-brian
    set target $argv[1]
    set port $target

    switch $target
        case u
            set port 2222
        case f
            set port 2223
    end

    if contains -- $target u f
        VBoxManage showvminfo "$target" >/dev/null 2>&1
        or begin
            echo "VM '$target' does not exist"
            return 1
        end

        VBoxManage list runningvms | string match -q "\"$target\" *"
		or begin
            echo "Waiting to start VM '$target' ..."
            VBoxManage startvm "$target" --type headless
            or return 1
        end
    end

	echo "SSH into VM '$target' ..."
    ssh brian@127.0.0.1 -p $port
end
