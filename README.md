# Saka
Simple Privlage Escalation

forcing binaries not not be writable is hard beacuse symlinks on nixos are
writable which means i must resolve the symlinks. Doing so causes coreutils to
stop working

soultion is to have different cmd and argv[0]. cmd should be the path to utis
and argv[0] should be what the user passed on the command line
