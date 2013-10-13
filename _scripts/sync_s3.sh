#!/usr/bin/bash
s3cmd sync --rr -P --delete-removed ../_site/ s3://www.klausbadelt.com