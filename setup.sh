snapclient_version="0.35.0"

apt update
apt upgrade -y
apt install git wget pigpio-tools netcat-openbsd libspa-0.2-bluetooth bluez-tools -y
apt install --no-install-recommends libopenblas-dev python3-setuptools -y

#cp config.txt /boot/firmware/config.txt

(
    wget https://github.com/joan2937/pigpio/archive/master.zip
    unzip master.zip
    cd pigpio-master
    make
    sudo make install
    systemctl enable --now ./pigpiod.service
)

# amp-control
(
    su pi
    cp amp-control.sh /usr/local/bin/amp-control.sh
    chmod +x /usr/local/bin/amp-control.sh
)

# bluethooth speaker
cp ./bluetooth_main.conf /etc/bluetooth/main.conf
echo PRETTY_HOSTNAME=Stereoanlage Sesselzimmer > /etc/machine-info
mkdir -p /wireplumber/wireplumber.conf.d
cp ./bluetooth.conf /etc/wireplumber/wireplumber.conf.d/bluetooth.conf


# Activate all services
#cp *.service /etc/systemd/system/
#systemctl daemon-reload
sudo systemctl enable --now ./pigpiod.service ./bt-agent.service
systemctl enable --now --user ./amp-control.service ./stream-bluetooth.service
find . -name "*.service" -exec basename {} \; | xargs -I{} sudo systemctl enable --now {}

#reboot
