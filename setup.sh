snapclient_version="0.34.0"

apt update
apt upgrade -y
apt install pulseaudio pulseaudio-utils git wget pigpio -y
apt install --no-install-recommends libopenblas-dev -y

cp config.txt /boot/firmware/config.txt

# pulseaudio
systemctl --global disable pulseaudio.service pulseaudio.socket
echo "autospawn = no" >> /etc/pulse/client.conf
sed -i '/^pulse-access:/ s/$/root,pi,snapclient/' /etc/group

# wyoming-satellite
( cd ~
git clone https://github.com/rhasspy/wyoming-satellite.git
cd wyoming-satellite
script/setup
)



# snapclient 31
(
cd ~
git clone https://github.com/FutureProofHomes/wyoming-enhancements.git
)
wget "https://github.com/badaix/snapcast/releases/download/v$snapclient_version/snapclient_$snapclient_version-1_armhf_trixie_with-pulse.deb"
apt install ./snapclient_$snapclient_version-1_armhf_trixie_with-pulse.deb -y
cp snapclient /etc/default/snapclient

# openwakeword
( cd ~
git clone https://github.com/rhasspy/wyoming-openwakeword.git
cd wyoming-openwakeword
script/setup
)

# amp-control
cp amp-control.sh /usr/local/bin/amp-control.sh
chmod +x /usr/local/bin/amp-control.sh

# Activate all services
cp *.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now *.service pigpiod.service

reboot
