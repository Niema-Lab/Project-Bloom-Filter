# 64-bit Docker Ubuntu environment
## Setup: 
apt update && apt upgrade -y
apt install -y wget
apt-get update && apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y autoconf automake bzip2 cmake g++ libboost-all-dev libbz2-dev libcurl4-openssl-dev liblzma-dev make python3 wget zlib1g-dev && \
wget -qO- "https://github.com/sparsehash/sparsehash/archive/refs/tags/sparsehash-2.0.4.tar.gz" | tar -zx && \
cd sparsehash-* && ./configure && make && make install && cd .. && rm -rf sparsehash-* && \
wget -qO- "https://github.com/simongog/sdsl-lite/releases/download/v2.1.1/sdsl-lite-2.1.1.tar.gz.offline.install.gz" | tar -zx && \
    cd sdsl-lite-* && ./install.sh /usr/local/ && cd .. && rm -rf sdsl-lite-* && \
wget -qO- "https://github.com/bcgsc/biobloom/releases/download/2.3.5/biobloomtools-2.3.5.tar.gz" | tar -zx && \
    cd biobloomtools-* && sed -i 's/c++11/c++14/g' configure.ac && ./configure && make && make install && cd .. && rm -rf biobloomtools-*
make
./configure


# To copy a local file into Docker:
## Outside Docker in separate terminal
docker cp /PATH CONTAINERID:data
docker ps	# If you need to find the container ID / name
cd data

Benchmark hg38 Bloom Filter Creation
apt-get update && apt-get install -y time
/usr/bin/time -v biobloommaker -t 8 -p hg38 GCA_000001405.29_GRCh38.p14_genomic.fna

## Downloaded 64-bit Linux art_illumina
Simulate 900k SARS-CoV-2 reads
./art_bin_MountRainier2/art_illumina -ss HS25 -i NC_045512.fas -p -l 150 -c 450000 -m 200 -s 10 --noALN -o SC2_R
Simulate 100k hg38 reads
./art_bin_MountRainier2/art_illumina -ss HS25 -i GCF_000001405.40 -p -l 150 -c 50000 -m 200 -s 10 --noALN -o hg38_R
## Note: To count # of reads in file by counting # of plusses:
grep -o "+" hg38_R1.fq | wc -l

## Merge the forward reads
cat SARS-CoV-2_1.fq hg38_1.fq > mixed_forward_reads.fq
## Merge the reverse reads
cat SARS-CoV-2_2.fq hg38_2.fq > mixed_reverse_reads.fq
## Run BioBloom
/usr/bin/time -v ./biobloomcategorizer -e -p /biobloomResults -f "hg38.bf" mixed_forward_reads.fq mixed_reverse_reads.fq
