#!/bin/bash
for f in modules/*; do
	if [[ -f "$f/init.lua" ]]; then
		echo "Siging $f."
		openssl dgst -sha256 -sign ../zbsign.pem "$f/init.lua" > "$f/.sig"
	fi
done