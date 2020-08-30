# from https://www.fosslinux.com/7631/how-to-install-and-configure-dns-on-ubuntu.htm and https://www.linuxbabe.com/ubuntu/set-up-local-dns-resolver-ubuntu-20-04-bind9
sudo apt-get install dnsutils
sudo apt install bind9 bind9utils bind9-doc bind9-host
sudo tee /etc/bind/named.conf.options<<'EOF'
options {
        directory "/var/cache/bind";
        forwarders {
                8.8.8.8;
        };
        dnssec-validation auto;
        listen-on-v6 { any; };
};
EOF
sudo systemctl restart bind9
sudo tee /etc/bind/named.conf.local<<'EOF'
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
EOF
sudo tee /etc/bind/db.krisc.dev<<'EOF'
;
; BIND data file for local loopback interface
;
$TTL    604800
@       IN      SOA     krisc. root.krisc.dev. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
        IN      A       192.168.1.196
;
@       IN      NS      ns.krisc.dev.
@       IN      A       192.168.1.196
@       IN      AAAA    ::1
ns      IN      A       192.168.1.196
EOF
sudo systemctl restart bind9
sudo tee /etc/bind/named.conf.local<<'EOF'
zone "krisc.dev" {
        type master;
        file "/etc/bind/db.krisc.dev";
};
zone "192.168.0.in-addr.arpa" {
        type master;
        file "/etc/bind/db.192";
};
EOF
sudo tee /etc/bind/db.192<<'EOF'
;
; BIND reverse data file for local 192.168.1.X net 
;
$TTL    604800
@       IN      SOA     ns.krisc.dev.  root.krisc.dev. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.
1.0.0   IN      PTR     ns.krisc.dev.
EOF
sudo systemctl restart bind9
named-checkzone krisc.dev /etc/bind/db.krisc.dev
named-checkzone 192.168.0.0/32 /etc/bind/db.192
named-checkconf /etc/bind/named.conf.local
named-checkconf /etc/bind/named.conf
sudo systemctl enable --now named
sudo netstat -lnptu | grep named




