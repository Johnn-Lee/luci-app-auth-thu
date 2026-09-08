#!/bin/sh

# luci-app-auth-thu's feed

# check env
if [ ! -x "/bin/opkg" ] && [ ! -x "/usr/bin/apk" ]; then
	echo "only supports OpenWrt or ImmortalWrt with opkg or apk!"
	exit 1
fi

# feed url
repository_url="https://johnn-lee.github.io/luci-app-auth-thu"

if [ -x "/bin/opkg" ]; then
	# add key
	echo "add key"
	key_build_pub_file="key-build.pub"
	wget -O "$key_build_pub_file" "$repository_url/opkg/key-build.pub"
	opkg-key add "$key_build_pub_file"
	rm -f "$key_build_pub_file"
	# add feed
	echo "add feed"
	if grep -q auth-thu /etc/opkg/customfeeds.conf; then
		sed -i '/auth-thu/d' /etc/opkg/customfeeds.conf
	fi
	echo "src/gz auth-thu $repository_url/opkg" >> /etc/opkg/customfeeds.conf
	# update feeds
	echo "update feeds"
	opkg update
elif [ -x "/usr/bin/apk" ]; then
	# add key
	echo "add key"
	wget -O "/etc/apk/keys/auth-thu.pem" "$repository_url/apk/public-key.pem"
	# add feed
	echo "add feed"
	if grep -q auth-thu /etc/apk/repositories.d/customfeeds.list; then
		sed -i '/auth-thu/d' /etc/apk/repositories.d/customfeeds.list
	fi
	echo "$repository_url/apk/packages.adb" >> /etc/apk/repositories.d/customfeeds.list
	# update feeds
	echo "update feeds"
	apk update
fi

echo "success"
