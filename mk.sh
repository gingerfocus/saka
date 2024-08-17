USER=root
GROUP=root

zig build

sudo chown ${USER}:${GROUP} ./zig-out/bin/saka
sudo chmod 4111 ./zig-out/bin/saka
