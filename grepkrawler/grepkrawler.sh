#!/bin/bash

if [[ "$1" == "-h" ]];then
        echo "[*] Usage: ./grepkrawler.sh <domain>"
        echo "[*] Example: ./grepkrawler google.com"
        exit 1
fi

if [ ! -x "$(command -v assetfinder)" ]; then
        echo "[-] This script requires assetfinder. Exiting."
        exit 1
fi

url=$1

if [[ ! -d "$url/recon/hakrawler" ]];then
        mkdir -p $url/recon/hakrawler
fi

if [[ ! -d "$url/recon/hakrawler/recursive" ]];then
        mkdir $url/recon/hakrawler/recursive
fi

if [[ ! -d "$url/recon/hakrawler/recursive/subs" ]];then
        mkdir $url/recon/hakrawler/recursive/subs
fi

if [[ ! -d "$url/recon/hakrawler/raw" ]];then
        mkdir $url/recon/hakrawler/raw
fi

if [[ ! -d "$url/recon/hakcrawler/refined_output" ]];then
        mkdir $url/recon/hakrawler/refined_output
fi

if [[ ! -d "$url/recon/hakrawler/recursive/raw" ]];then
        mkdir $url/recon/hakrawler/recursive/raw
fi

if [[ ! -d "$url/recon/hakrawler/recursive/refined_output" ]];then
        mkdir $url/recon/hakrawler/recursive/refined_output
fi


echo "[+] Running initial crawl..."
assetfinder $url | grep "$url" | hakrawler | tee -a $url/recon/hakrawler/raw/hakrawler_init.txt
echo "[+] Grepping in progress..."
cat $url/recon/hakrawler/raw/hakrawler_init.txt | grep "subdomains" | sort -u | tee -a $url/recon/hakrawler/refined_output/subs.txt
cat $url/recon/hakrawler/raw/hakrawler_init.txt | grep "form]" | sort -u | tee -a $url/recon/hakrawler/refined_output/forms.txt
cat $url/recon/hakrawler/raw/hakrawler_init.txt | grep "javascript" | sort -u | tee -a $url/recon/hakrawler/refined_output/js.txt
cat $url/recon/hakrawler/raw/hakrawler_init.txt | grep "robots" | sort -u | tee -a $url/recon/hakrawler/refined_output/robots.txt
cat $url/recon/hakrawler/raw/hakrawler_init.txt | grep "sitemap" | sort -u | tee -a $url/recon/hakrawler/refined_output/sitemap.txt
cat $url/recon/hakrawler/raw/hakrawler_init.txt | grep "url]" | sort -u | tee -a $url/recon/hakrawler/refined_output/urls.txt

if [[ ! -s $url/recon/hakrawler/refined_output/subs.txt ]];then
        echo "[-] no subs found..."
        rm $url/recon/hakrawler/refined_output/subs.txt
fi
if [[ ! -s $url/recon/hakrawler/refined_output/forms.txt ]];then
        echo "[-] no forms found..."

        rm $url/recon/hakrawler/refined_output/forms.txt
fi
if [[ ! -s $url/recon/hakrawler/refined_output/js.txt ]];then
        echo  "[-] no javascript files found..."
        rm  $url/recon/hakrawler/refined_output/js.txt
fi
if [[ ! -s $url/recon/hakrawler/refined_output/robots.txt ]];then
        echo "[-] no robots.txt found..."
        rm $url/recon/hakrawler/refined_output/robots.txt
fi
if [[ ! -s $url/recon/hakrawler/refined_output/sitemap.txt ]];then
        echo "[-] no sitemaps found..."
        rm $url/recon/hakrawler/refined_output/sitemap.txt
fi
if [[ ! -s $url/recon/hakrawler/refined_output/urls.txt ]];then
        echo "[-] no urls found..."
        rm $url/recon/hakrawler/refined_output/urls.txt
fi

clear

#recurisve hakcrawler
assetfinder $url | grep "$url" | hakrawler | tee -a $url/recon/hakrawler/recursive/raw/recursive_hakrawler.txt
cat $url/recon/hakrawler/recursive/raw/recursive_hakrawler.txt | grep "subdomain" | rev | cut -d '[' -f 1 | rev | cut -c4- | sort -u >> $url/recon/hakrawler/recursive/raw/hakrawler_subs
#rm $url/recon/hakrawler/recursive/raw/recursive_hakrawler.txt
if [[ -s $url/recon/hakrawler/recursive/raw/hakrawler_subs ]]; then
        echo "[+] Running hakrawler recursively"
        for sub in $(cat $url/recon/hakrawler/recursive/raw/hakrawler_subs);do
                hakrawler -domain $sub | tee -a $url/recon/hakrawler/recursive/subs/$sub.txt
                cat $url/recon/hakrawler/recursive/subs/$sub.txt | grep "subdomains" | sort -u | tee -a $url/recon/hakrawler/recursive/refined_output/subs.txt
                cat $url/recon/hakrawler/recursive/subs/$sub.txt | grep "form]" | sort -u | tee -a $url/recon/hakrawler/recursive/refined_output/forms.txt
                cat $url/recon/hakrawler/recursive/subs/$sub.txt | grep "javascript" | sort -u | tee -a $url/recon/hakrawler/recursive/refined_output/js.txt
                cat $url/recon/hakrawler/recursive/subs/$sub.txt | grep "robots" | sort -u |tee -a $url/recon/hakrawler/recursive/refined_output/robots.txt
                cat $url/recon/hakrawler/recursive/subs/$sub.txt | grep "url]" | sort -u |tee -a $url/recon/hakrawler/recursive/refined_output/urls.txt

                cat $url/recon/hakrawler/recursive/subs/$sub.txt | grep "subdomain" | rev | cut -d "[" -f 1 | rev | cut -c4- | sort -u | tee -a $url/recon/hakrawler/recursive/subs/recursive_$sub.txt
                subdomain=$(cat $url/recon/hakrawler/recursive/subs/recursive_$sub.txt)
                if [[ "$subdomain" == "$url" ]]; then
                        echo "[+] subdomain found! crawling now..."

                        hakrawler -domain $subdomain | tee -a $url/recon/hakrawler/recursive/raw/$subdomain.txt
                        cat $url/recon/hakrawler/recursive/raw/$subdomain.txt | grep "subdomains" |sort -u | tee -a $url/recon/hakrawler/recursive/refined_output/subs.txt
                        cat $url/recon/hakrawler/recursive/raw/$subdomain.txt | grep "form]" | sort -u | tee -a $url/recon/hakrawler/recursive/refined_output/forms.txt
                        cat $url/recon/hakrawler/recursive/raw/$subdomain.txt | grep "javascript" | sort -u | tee -a $url/recon/hakrawler/recursive/refined_output/js.txt
                        cat $url/recon/hakrawler/recursive/raw/$subdomain.txt | grep "robots" | sort -u | tee -a $url/recon/hakrawler/recursive/refined_output/robots.txt
                        cat $url/recon/hakrawler/recursive/raw/$subdomain.txt | grep "url]" | sort -u | tee -a $url/recon/hakrawler/recursive/refined_output/robots.txt


                        if [[ ! -s $url/recon/hakrawler/recursive/refined_output/forms.txt ]];then
                                echo "[-] no subs found..."
                                rm $url/recon/hakrawler/recursive/refined_output/forms.txt
                        fi
                        if [[ ! -s $url/recon/hakrawler/refined_output/forms.txt ]];then
                                echo "[-] no forms found..."
                                rm $url/recon/hakrawler/refined_output/forms.txt
                        fi
                        if [[ ! -s $url/recon/hakrawler/refined_output/js.txt ]];then
                                echo  "[-] no javascript files found..."
                                rm  $url/recon/hakrawler/refined_output/js.txt
                        fi
                        if [[ ! -s $url/recon/hakrawler/refined_output/robots.txt ]];then
                                echo "[-] no robots.txt found..."
                                rm $url/recon/hakrawler/refined_output/robots.txt
                        fi
                        if [[ ! -s $url/recon/hakrawler/refined_output/sitemap.txt ]];then
                                echo "[-] no sitemaps found..."
                                rm $url/recon/hakrawler/refined_output/sitemap.txt
                        fi
                        if [[ ! -s $url/recon/hakrawler/refined_output/urls.txt ]];then
                                echo "[-] no urls found..."
                                rm $url/recon/hakrawler/refined_output/urls.txt
                        fi
                else
                        rm $url/recon/hakrawler/recursive/subs/recursive_$sub.txt
                fi
        done

else
        echo "[-] No subdomains to crawl, exiting..."
    
fi
