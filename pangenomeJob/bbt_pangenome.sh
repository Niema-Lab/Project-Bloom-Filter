#!/bin/bash
set -e  # Exit on error

echo "Updating packages"
apt-get update && apt-get install -y time wget tar

echo "Downloading genomes"
/usr/local/bin/download_references.sh
echo "Calculating downloaded genome sizes"
du -h --max-depth=2 .

echo "Benchmarking human genomes Bloom Filter creation"
/usr/bin/time -v biobloommaker -t 8 -p human ref/*.fna ref/pangenomes/*.fa
echo "Calculating file sizes"
du -h --max-depth=2 .

echo "Deleting genomes to save space"
rm -r ref

echo "Connecting to AWS"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt install unzip
unzip awscliv2.zip
./aws/install
echo "[prp]
aws_access_key_id = 34GDFRY3HW90443QI579
aws_secret_access_key = yUgnWULM09iZfQIyf5H2ILsKeJy56EIxDeFGifBm" >> aws/credentials 
echo "[prp]
s3api = endpoint_url = https://s3-west.nrp-nautilus.io
s3 = endpoint_url = https://s3-west.nrp-nautilus.io
[plugins]
endpoint = awscli_plugin_endpoint" >> aws/config 

# echo "Downloading read data"

# echo "Simulating SARS-CoV-2 reads"
# ./art_bin_MountRainier2/art_illumina -ss HS25 -i NC_045512.fas -p -l 150 -c 450000 -m 200 -s 10 --noALN -o SC2_R

# echo "Simulating hg38 reads"
# ./art_bin_MountRainier2/art_illumina -ss HS25 -i GCA_000001405.29_GRCh38.p14_genomic.fna -p -l 150 -c 71 -m 200 -s 10 --noALN -o hg38_R

# echo "Merging forward and reverse reads"
# cat SC2_R1.fq hg38_R1.fq > mixed_forward_reads.fq
# cat SC2_R2.fq hg38_R2.fq > mixed_reverse_reads.fq

# echo "Creating output folder"
# mkdir biobloomResults

# echo "Running BioBloomCategorizer"
# /usr/bin/time -v biobloomcategorizer -d -n -e -p biobloomResults -f "hg38.bf" mixed_forward_reads.fq mixed_reverse_reads.fq > nonhost_reads.fq

# echo "Running Python script for accuracy analysis"
# python3 accuracyBiobloom.py mixed_forward_reads.fq mixed_reverse_reads.fq nonhost_reads.fq

# echo "Benchmarking complete!"
