#!/bin/bash

# QuickDelete (not sure if this name will stick)
# Original authorship: Keith Russell, 2016
# 
# Instantly "deletes" targets.
# Really, it moves them to a hidden dir on the same filesystem,
#  and then starts a background rm.
# The rm operation is nohup'ed, so exiting the parent shell will not
#  abort it. (This is not true if you terminate the whole
#  *system*, such as closing a Cygwin window.)
# The installer and/or user of this script should customize the
#  std_shred_locations array (also, this probably ought to be read
#  from an environment variable instead of hard-coded).
#  This std_shred_locations array is the set of whitelisted locations
#  for stashing stuff that is being deleted.  If you run this script
#  upon a file/dir on a filesystem that doesn't have a member dir in
#  this array, this script will fall back to the parent dir of the target.

usageStr="usage: $(basename $0) TARGETS..."

if [ "$#" -lt 1 ]; then
  echo $usageStr
  exit 1;
fi

#Using an array helps with spaces, and expansion of things like "~", which is required by the [-e] test below.
declare -a std_shred_locations
std_shred_locations=(~ /tmp)
unset my_shred_locations
declare -a my_shred_locations

count=0
while [ "x${std_shred_locations[count]}" != "x" ]; do
  p="${std_shred_locations[count]}"
  [ -e "$p" ] && my_shred_locations+=("$(readlink -f "$p")")
   count=$(( $count + 1 ))
done

has_uuidgen=$([ $(command -v uuidgen) ] && echo true)

while (( "$#" )); do

  target="$1"

  if [ -e "$target" ]; then
	
    if [ true = "$has_uuidgen" ]; then
      uuid=$(uuidgen)
      if [ $? -ne 0 ]; then
        echo "uuidgen returned error"
        exit 1
      fi
    else
      uuid=$RANDOM
    fi

    found_convenient_shredDir=false
    count=0
    while [ "x${my_shred_locations[count]}" != "x" ]; do
      p="${my_shred_locations[count]}"
      if [[ "$p" != "$(readlink -f "$target")" && (( $(stat -c "%d" "$target") == $(stat -c "%d" "$p") )) ]]; then
        shredDir="$p"
        found_convenient_shredDir=true
        break
      fi
	  count=$(( $count + 1 ))
    done

    if [ "$found_convenient_shredDir" != "true" ]; then
      shredDir="$(dirname "$target")"

      if [[ "$(readlink -f "$target")" = "/" || (( $(stat -c "%d" "$target") != $(stat -c "%d" "$shredDir") )) ]]; then
        echo "Error: target '$target' is the root of its own FS - no obvious location for shredDir exists."
        exit 1
      fi

      if [ "$already_warned_about_fs" != "true" ]; then
        echo -e "Warning: target '$target' is not on a filesystem for which we know a proper shredding location.\n  Using fallback location in parent dir of target -- beware ops on parent until shred finishes.\n  Suppressing further warnings of this type."
        already_warned_about_fs=true
      fi
    fi

    shredfn=$shredDir/.shredding-"$(basename "$target")"-$uuid"..."

    mv $target $shredfn
    if [ $? -ne 0 ]; then
      echo "failed to move '$target' to '$shredfn'"
      exit 1
    fi

    nohup nice rm -rf $shredfn &>/dev/null &
    echo "fed $target into shredder..."

  else

    echo "warning: target '$target' does not exist"

  fi

  shift

done

exit 0
