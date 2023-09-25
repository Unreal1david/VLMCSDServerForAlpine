#!/bin/ash

# Create directories
mkdir -p /etc/systemd/system /root/vlmcsd 

# Install if not present
if [ ! -f /vlmcsd ]; then

  # Install dependencies
  apk add --no-cache git make build-base

  # Clone repo
  git clone https://github.com/Wind4/vlmcsd.git

  # Build
  cd vlmcsd
  make

  # Copy binaries
  cp bin/vlmcsd /vlmcsd
  cp etc/vlmcsd.kmd /vlmcsd.kmd

  # Clean up
  cd ..
  rm -rf vlmcsd

fi

# Update
cd /root
git clone https://github.com/Wind4/vlmcsd.git
cd vlmcsd
make
cp bin/vlmcsd /vlmcsd
cp etc/vlmcsd.kmd /vlmcsd.kmd
cd ..
rm -rf vlmcsd

# Add openRC init script
cat <<EOF > /etc/init.d/vlmcsd  
#!/sbin/openrc-run

command="/vlmcsd"
command_args="-D -d -t 3 -e -v"

name="vlmcsd"
description="vlmcsd KMS server"

start() {
  echo "Starting \$name"
  \$command \$command_args &
}

stop() {
  echo "Stopping \$name"
  killall vlmcsd  
}
EOF

chmod +x /etc/init.d/vlmcsd

# Add systemd unit
cat <<EOF > /etc/systemd/system/vlmcsd.service
[Unit]
Description=vlmcsd KMS server

[Service]
ExecStart=/vlmcsd -D -d -t 3 -e -v

[Install]
WantedBy=multi-user.target
EOF

# Enable service 
if [ -x "$(command -v systemctl)" ]; then
  systemctl enable vlmcsd
else
  rc-update add vlmcsd default  
fi

# Start service
if [ -x "$(command -v systemctl)" ]; then
  systemctl start vlmcsd 
else
  /etc/init.d/vlmcsd start
fi
