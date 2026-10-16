function unload-kvm
    if lsmod | grep -q "^kvm_intel"
        echo ":: kvm_intel is currently loaded. Unloading KVM modules..."

        # Attempt to remove both modules sequentially
        if sudo modprobe -r kvm_intel; and sudo modprobe -r kvm
            echo "✓ KVM modules successfully unloaded. VirtualBox is ready!"
        else
            echo "✕ Failed to unload modules. A process might still be using KVM."
        end
    else
        echo "✓ kvm_intel is not loaded. You are good to go!"
    end
end
