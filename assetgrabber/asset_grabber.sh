#!/bin/bash

url=$1
if [[ ! -d "$url/recon/asset_grabber" ]];then
    mkdir -p $url/recon/asset_grabber
fi

assetfinder $url | grep "$url" | httprobe | sort -u | tee -a $url/recon/asset_grabber/subs_alive.txt
cat $url/recon/asset_grabber/subs_alive.txt | rev | cut -d "/" -f 1 | rev | sort -u | tee -a $url/recon/asset_grabber/refined_live_subs.txt
python3 EyeWitness/EyeWitness.py --web -f $url/recon/asset_grabber/refined_live_subs.txt -d $url/recon/asset_grabber/eyewitness --resolve
