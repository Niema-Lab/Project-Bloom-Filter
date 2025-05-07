FROM ubuntu:24.04

# Add maintainer information
LABEL maintainer="Katelyn Nguyen <kan028@ucsd.edu>"

# Install dependencies and tools
RUN apt-get update && apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y \
    autoconf automake bzip2 cmake g++ libboost-all-dev libbz2-dev \
    libcurl4-openssl-dev liblzma-dev make python3 wget zlib1g-dev curl && \
    
    # Install Google Sparsehash 
    wget -qO- "https://github.com/sparsehash/sparsehash/archive/refs/tags/sparsehash-2.0.4.tar.gz" | tar -zx && \
    cd sparsehash-* && ./configure && make && make install && cd .. && rm -rf sparsehash-* && \
    
    # Install sdsl-lite
    wget -qO- "https://github.com/simongog/sdsl-lite/releases/download/v2.1.1/sdsl-lite-2.1.1.tar.gz.offline.install.gz" | tar -zx && \
    cd sdsl-lite-* && ./install.sh /usr/local/ && cd .. && rm -rf sdsl-lite-* && \
    
    # Install BioBloom
    wget -qO- "https://github.com/bcgsc/biobloom/releases/download/2.3.5/biobloomtools-2.3.5.tar.gz" | tar -zx && \
    cd biobloomtools-* && sed -i 's/c++11/c++14/g' configure.ac && ./configure && make && make install && cd .. && rm -rf biobloomtools-* && \
    
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy scripts
COPY bbt_pangenome.sh /usr/local/bin/bbt_pangenome.sh
RUN chmod +x /usr/local/bin/bbt_pangenome.sh
COPY download_references.sh /usr/local/bin/download_references.sh
RUN chmod +x /usr/local/bin/download_references.sh
COPY ref/ /usr/local/ref/
RUN chmod -R +x /usr/local/ref/
COPY accuracyBiobloom.py /usr/local/bin/
RUN chmod -R +x /usr/local/bin/accuracyBiobloom.py

# Add /usr/local/bin to PATH
ENV PATH="/usr/local/bin:${PATH}"

# Set working directory
WORKDIR /root

ENTRYPOINT ["/usr/local/bin/bbt_pangenome.sh"]
