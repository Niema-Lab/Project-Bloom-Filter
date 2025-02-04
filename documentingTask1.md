# Team Bloom Filter Task 1

Documenting the process to running BBT on hg38 and SARS-CoV-2.


### Step 1: Setup Dockerfile

```
	# Use Ubuntu as the base image

	FROM  ubuntu:24.04

	  

	# Add maintainer information

	LABEL  maintainer="Cole  Carter  <colescarter@gmail.com>"

	  

	# Install dependencies and tools

	RUN  apt-get  update  &&  apt-get  -y  upgrade  &&  \

	DEBIAN_FRONTEND=noninteractive  TZ=Etc/UTC  apt-get  install  -y  \

	autoconf  automake  bzip2  cmake  g++  libboost-all-dev  libbz2-dev  \

	libcurl4-openssl-dev  liblzma-dev  make  python3  wget  zlib1g-dev  \

	libgsl0-dev  &&  \

	# Install Google Sparsehash (needed for BioBloom)

	wget  -qO-  "https://github.com/sparsehash/sparsehash/archive/refs/tags/sparsehash-2.0.4.tar.gz"  |  tar  -zx  &&  \

	cd  sparsehash-*  &&  ./configure  &&  make  &&  make  install  &&  cd  ..  &&  rm  -rf  sparsehash-*  &&  \

	# Install sdsl-lite (needed for BioBloom)

	wget  -qO-  "https://github.com/simongog/sdsl-lite/releases/download/v2.1.1/sdsl-lite-2.1.1.tar.gz.offline.install.gz"  |  tar  -zx  &&  \

	cd  sdsl-lite-*  &&  ./install.sh  /usr/local/  &&  cd  ..  &&  rm  -rf  sdsl-lite-*  &&  \

	# Install BioBloom

	wget  -qO-  "https://github.com/bcgsc/biobloom/releases/download/2.3.5/biobloomtools-2.3.5.tar.gz"  |  tar  -zx  &&  \

	cd  biobloomtools-*  &&  sed  -i  's/c++11/c++14/g'  configure.ac  &&  ./configure  &&  make  &&  make  install  &&  cd  ..  &&  rm  -rf  biobloomtools-*  &&  \

	# Clean up

	apt-get  clean  &&  rm  -rf  /var/lib/apt/lists/*  /tmp/*  /var/tmp/*

	  

	# Copy the 'art_src_MountRainier_Linux' folder from the build context into the container

	COPY  art_bin_MountRainier  /art_bin_MountRainier

	  

	# Add /usr/local/bin to PATH

	ENV  PATH="/usr/local/bin:${PATH}"

	  

	# Set the working directory

	WORKDIR  /root

	  

	# Default command to keep container running

	CMD  ["/bin/bash"]
```


For this Dockerfile you must ensure that the linux based binary version of [ART](https://www.niehs.nih.gov/research/resources/software/biostatistics/art) is installed and in the same directory as your Dockerfile.

### Step 2: Create Docker Image and Run Docker

Run this in the directory with both your Dockerfile (Ensure it is called "Dockerfile") and the linux unzipped ART download. Also ensure that you have Docker Desktop installed and open.

`docker build -t biobloom-image .`

Then once that finished successfully, you can run:

`docker run -it biobloom-image`

Alternatively, if you want to put files such as the [hg38](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.26/) and SARS-CoV-2 files into a directory you can mount that directory onto the image using this command:

`docker run -it -v /absolute/path/to/folder/folderName:/inputs biobloom-image`

### Step 3: Create reads

Now that we are going to create the reads, for now we will make 100,000 paired-end reads of hg38 on docker:

`cd art_bin_MountRainer`
`./art_illumina -ss HS25 -i ../inputs/GCF_000001405.26_GRCh38_genomic.fna -p -l 150 -c 112 -m 200 -s 10 --noALN -o hg38_R`

command to check num reads:
`grep -o "+" hg38_R1.fq | wc -l` multiplied by 2 to get total number of reads
`wc -l hg38_R1.fq hg38_R2.fq` then divide output for each by 4 to get each file and total read count

and 900,00 of SARS-CoV-2:

`./art_illumina -ss HS25 -i ../inputs/NC_045512.fas -p -l 150 -c 450000 -m 200 -s 10 --noALN -o sars_cov2_R`

command to check num reads:
`grep -o "+" sars_cov2_R1.fq | wc -l` multiplied by 2 to get total number of reads
`wc -l sars_cov2_R1.fq sars_cov2_R2.fq` then divide output for each by 4 to get each file and total read count

### Step 4: Perform Host Filtering (Run Categorizer)

`/usr/bin/time -v biobloomcategorizer -d -n -e -f /inputs/hg381.bf /inputs/merged_reads1.fq /inputs/merged_reads2.fq > nonhost_reads.fq`


### Step 5: Check Accuracy and other metrics

First store ids for each of the read sets:
`grep "^@" /inputs/hg38_R1.fq | cut -d " " -f1 > human_readnames.txt`
`grep "^@" /inputs/sars_cov2_R1.fq | cut -d " " -f1 > viral_readnames.txt`
`grep "^@" nonhost_reads.fq | cut -d " " -f1 > nonhost_readnames.txt`

sort them so that the comm command works:
`sort viral_readnames.txt -o viral_readnames.txt`
`sort human_readnames.txt -o human_readnames.txt`
`sort nonhost_readnames.txt -o nonhost_readnames.txt`

I saved a copy of nonhost_readnames.txt so I renamed the sorted one to be sorted_nonhost_readnames.txt. Make bash script to check for metrics:
```
check_fp_tp.sh <<EOF
#!/bin/bash

# Count TP, FP, FN, TN
tp=\$(comm -12 viral_readnames.txt sorted_nonhost_readnames.txt | wc -l)
fp=\$(comm -12 human_readnames.txt sorted_nonhost_readnames.txt | wc -l)
fn=\$(comm -23 viral_readnames.txt sorted_nonhost_readnames.txt | wc -l)
tn=\$(comm -23 human_readnames.txt sorted_nonhost_readnames.txt | wc -l)

# Print counts
echo "True Positives (TP): \$tp"
echo "False Positives (FP): \$fp"
echo "False Negatives (FN): \$fn"
echo "True Negatives (TN): \$tn"

# Calculate accuracy, precision, recall, specificity
precision=\$(echo "scale=4; \$tp / (\$tp + \$fp)" | bc)
recall=\$(echo "scale=4; \$tp / (\$tp + \$fn)" | bc)
specificity=\$(echo "scale=4; \$tn / (\$tn + \$fp)" | bc)
accuracy=\$(echo "scale=4; (\$tp + \$tn) / (\$tp + \$tn + \$fp + \$fn)" | bc)

# Print metrics
echo "Precision: \$precision"
echo "Recall: \$recall"
echo "Specificity: \$specificity"
echo "Accuracy: \$accuracy"
EOF
```

make it executable:
`chmod +x check_fp_tp.sh `

run the script:
`./check_fp_tp.sh`

## Outputs

### BioBloom Host Filtering

root@4b3448ef94e2:/# /usr/bin/time -v biobloomcategorizer -d -n -e -f /inputs/hg381.bf /inputs/merged_reads1.fq /inputs/merged_reads2.fq > nonhost_reads.fq
Min score threshold: 0.15
Starting to Load Filters.
Loaded Filter: hg381
Filter Loading Complete.
Filtering Start
Total Reads:499841
Writing file: _summary.tsv
        Command being timed: "biobloomcategorizer -d -n -e -f /inputs/hg381.bf /inputs/merged_reads1.fq /inputs/merged_reads2.fq"
        User time (seconds): 35.27
        System time (seconds): 35.42
        Percent of CPU this job got: 82%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 1:25.51
        Average shared text size (kbytes): 0
        Average unshared data size (kbytes): 0
        Average stack size (kbytes): 0
        Average total size (kbytes): 0
        Maximum resident set size (kbytes): 3961256
        Average resident set size (kbytes): 0
        Major (requiring I/O) page faults: 1
        Minor (reclaiming a frame) page faults: 107294
        Voluntary context switches: 16532
        Involuntary context switches: 338
        Swaps: 0
        File system inputs: 400
        File system outputs: 574600
        Socket messages sent: 0
        Socket messages received: 0
        Signals delivered: 0
        Page size (bytes): 4096
        Exit status: 0

### Accuracy Metrics
root@fad5d838bf21:/inputs# ./check_fp_tp.sh 
True Positives (TP): 450000
False Positives (FP): 0
False Negatives (FN): 0
True Negatives (TN): 49841
Precision: 1.0000
Recall: 1.0000
Specificity: 1.0000
Accuracy: 1.0000

Seems suspiciously high.