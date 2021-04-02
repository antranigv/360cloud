#!/bin/sh

STARTTIME=$(date +%s)
[ "${1}" == "" ] && CONFIG="360cloud.conf" || CONFIG="${1}"

echo -e "\e[44mUsing the config file: ${CONFIG}\e[0m"

. ${CONFIG}

echo -e "\e[34mDownloading required packages\e[0m"
pkg install -y acme.sh bind916 bind-tools grub2-bhyve isc-dhcp44-server tmux vm-bhyve subcalc
echo -e "\e[42mAll packages have been installed\e[0m"

echo -e "\e[34mSetting up network interfaces\e[0m"

sysrc cloned_interfaces="bridge0"

sysrc ifconfig_bridge0="inet ${lan} descr cloud360"

service netif start bridge0

echo -e "\e[42mbridge0 is done\e[0m"

echo -e "\e[34mSetting up network firewall\e[0m"

sysrc pf_enable="YES"

cat << EOF > /etc/pf.conf
ext_if="${ext_if}"

lan="${lan}"

nat on \$ext_if inet from \$lan to any -> \$ext_if:0

pass inet proto icmp
pass out all keep state

pass on lo0 all no state
pass on tun0 all no state
pass on epair all no state
pass on vm-public all no state
EOF

echo -e "\e[34mChecking firewall settings\e[0m"
pfctl -nvf /etc/pf.conf
echo -e "\e[42mpf is done\e[0m"

echo -e "\e[34mSetting up DNS server\e[0m"

mkdir -p /usr/local/etc/namedb/pri/${domain}/

rndc-confgen -a -c /usr/local/etc/namedb/dhcp-360.key

cat << EOF > /usr/local/etc/namedb/named.conf
options {
        directory       "/usr/local/etc/namedb/working";
        pid-file        "/var/run/named/pid";
        dump-file       "/var/dump/named_dump.db";
        statistics-file "/var/stats/named.stats";

        listen-on       { 127.0.0.1; $(echo ${lan} | cut -d '/' -f 1); };
};

include "/usr/local/etc/namedb/dhcp-360.key";
zone "loc.${domain}." {
        type master;
        allow-query { 127.0.0.1; $(subcalc inet ${lan} | grep range: | cut -d ' ' -f 8)/$(echo ${lan} | cut -d '/' -f 2); };
        allow-transfer { none; };
        allow-update { key dhcp-360; };
        file "/usr/local/etc/namedb/pri/${domain}/${domain}.zone";
};
EOF

named-checkconf /usr/local/etc/namedb/named.conf

cat << EOF > /usr/local/etc/namedb/pri/${domain}/${domain}.zone
\$ORIGIN .
\$TTL 800        ; 13 minutes 20 seconds
loc.${domain} IN SOA ns0.loc.${domain}. root.${domain}. (
                                $(date +%Y%m%d)00       ; serial
                                600                     ; refresh
                                600                     ; retry
                                600                     ; expire 
                                600                     ; minimum
                                )
                        NS      ns0.loc.${domain}.
                        A       $(echo ${lan} | cut -d '/' -f 1)

\$ORIGIN loc.${domain}.
ns0                     A       $(echo ${lan} | cut -d '/' -f 1)
EOF

named-checkzone loc.${domain} /usr/local/etc/namedb/pri/${domain}/${domain}.zone

sysrc named_enable="YES"
service named start
echo '127.0.0.1' > /etc/resolv.conf

echo -e "\e[42mBIND is installed and configured\e[0m"

echo -e "\e[34mSetting up DHCP server\e[0m"
cat << EOF

EOF

## END
ENDTIME=$(date +%s)
TIMSPENT=$(expr ${ENDTIME} - ${STARTTIME})

echo -e "\e[42mInstallation done, it took \e[45m${TIMSPENT} seconds\e[0m"
exit 0
