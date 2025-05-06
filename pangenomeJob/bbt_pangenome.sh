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
apt install -y unzip
unzip awscliv2.zip
./aws/install
mkdir ~/.aws
echo "[prp]
aws_access_key_id = INSERTKEY
aws_secret_access_key = INSERTKEY" >> ~/.aws/credentials 
echo "[prp]
s3api = endpoint_url = https://s3-west.nrp-nautilus.io
s3 = endpoint_url = https://s3-west.nrp-nautilus.io
[plugins]
endpoint = awscli_plugin_endpoint" >> ~/.aws/config 

echo "Downloading read data"
aws s3 cp s3://biobloomBucket/h100000-m100000 . --recursive --profile prp --endpoint-url https://s3-west.nrp-nautilus.io

echo "Merging forward and reverse reads"
cat *R1.fastq > mixed_forward_reads.fq
cat *R2.fastq > mixed_reverse_reads.fq

echo "Creating output folder"
mkdir biobloomResults

echo "Running BioBloomCategorizer"
/usr/bin/time -v biobloomcategorizer -d -n -e -p biobloomResults -f "human.bf" mixed_forward_reads.fq mixed_reverse_reads.fq > nonhost_reads.fq

echo "Running Python script for accuracy analysis"
python3 accuracyBiobloom.py mixed_forward_reads.fq mixed_reverse_reads.fq nonhost_reads.fq

echo "Benchmarking complete!"
