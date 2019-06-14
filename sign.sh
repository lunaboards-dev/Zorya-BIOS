#!/bin/bash
for f in modules/*; do
	if [[ -f "$f/init.lua" ]]; then
		echo "Siging $f."
		openssl dgst -sha256 -sign ../zbsign.pem "$f/init.lua" > "$f/.sig"
	fi
done
echo "Signing BIOS..."
openssl dgst -sha256 -sign ../zbsign.pem bios.lua > signatures/BIOS_SIGN_FULL.bin
echo "Signing minified BIOS..."
openssl dgst -sha256 -sign ../zbsign.pem bios.min.lua > signatures/BIOS_SIGN_MIN.bin