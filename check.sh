#!/bin/sh
set -e
set -u

exec << EOF
192.0.2.0
192.0.2.1
192.0.2.10
192.0.2.100
192.0.2.255
192.0.0.2
192.0.1.2
192.0.10.2
192.0.100.2
192.0.255.2
192.0.0.2
192.1.0.2
192.10.0.2
192.100.0.2
192.255.0.2
0.192.0.2
1.192.0.2
10.192.0.2
100.192.0.2
255.192.0.2
2001:DB8::
2001:db8::
2001:Db8::
2001:dB8::
2001:dB8::
2001:db8::2160:b110:927e:911a
2001:db8::ffff:b110:927e:911a
2001:db8::0000:b110:927e:911a
2001:db8::0:b110:927e:911a
2001:db8:47fe:1:0:b110:927e:911a
2001:db8:47fe:1::b110:927e:911a
2001:db8:47fe:1::b110:927e:911a
::
0:0:0:0:0:0:0:0
0000:0000:0000:0000:0000:0000:0000:0000
ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
::1
1::
f:f:f:f:f:f:f:f
F:F:F:F:F:F:F:F
f::f:f:f:f:f:f
F::F:F:F:F:F:F
::f:f:f:f:f:f:f
::F:F:F:F:F:F:F
f:f::f:f:f:f:f
F:F::F:F:F:F:F
f:f:f::f:f:f:f
F:F:F::F:F:F:F
f:f:f:f::f:f:f
F:F:F:F::F:F:F
f:f:f:f:f::f:f
F:F:F:F:F::F:F
f:f:f:f:f:f::f
F:F:F:F:F:F::F
f:f:f:f:f:f:f::
F:F:F:F:F:F:F::
-6 2001:db8::
-4 192.0.2.0
-n6 2001:db8::/32
-p6 2001:db8::/32
-n4 192.0.2.0/24
-p4 192.0.2.0/24
-nb6 [2001:db8::/32]
-pb6 [2001:db8::/32]
-pb [2001:db8::/32]
EOF

while read l; do
    if ! ./isip -v $l; then
        echo "$l" >&2
        exit 1
    fi
done

exec << EOF
.0.2.0
0.2.1
192.0.2.
192.0.2
192.0.
192.0
.1.2
10.2
100.
.100
100
a.b.c.d
a
g
1
2001:GB8::
2001:gb8::
1::2::
-6 192.0.2.1
-4 2001:db8::
[2001:db8::]
[2001:db8::/32]
EOF

while read l; do
    if ./isip -v $l; then
        echo "$l" >&2
        exit 1
    fi
done
