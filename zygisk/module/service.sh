# Extract the Directory Path and Change Directory 
MODDIR="${0%/*}"
cd "$MODDIR" || exit 1

# Start the Daemon Directly in the Background within a Private Mount Namespace
unshare --propagation slave -m "$MODDIR/daemon" --system-server-max-retry=3 "$@" &
