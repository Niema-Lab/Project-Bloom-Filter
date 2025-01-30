# Run this file with
# python accuracyBiobloom.py mergedSC2.fq mergedhg38.fq nonhost_reads.fq
import sys

# Make set of sequences in given FASTQ file
def makeSet(input_fastq):
    seqSet = set()
    with open(input_fastq, "r") as f:
        while True:
            try:
                next(f) # Header
                seq = next(f).strip()
                next(f) # Plus sign
                next(f) # Quality scores
                seqSet.add(seq)
            except StopIteration: # Throw when EOF
                break
            except FileNotFoundError:
                print(f"File {input_fastq} not found")
    return seqSet

# Find TP, FP, TN, FN given
# a. Set of sequences that should be in file, and
# b. Count of (a)
# c. Set of sequences that SHOULDNT be in file, and
# d. Count of (c)
# e. Input file (FASTQ)
def findAccuracy(negSet, posSet, input_fastq):
    negCount = len(negSet)
    posCount = len(posSet)
    TN = 0 # non-human reads in input_fastq
    FN = 0 # human reads in input_fastq
    with open(input_fastq, "r") as f:
        while True:
            try:
                next(f).strip() # Header
                seq = next(f).strip()
                next(f) # Plus sign
                next(f) # Quality scores
                if seq in negSet:
                    TN += 1
                elif seq in posSet:
                    FN += 1
                else:
                    print(f"Error: Sequence in {input_fastq} that is not in either of the first 2 input files.")
                    break
            except StopIteration: # Throw when EOF
                break
            except FileNotFoundError:
                print(f"File {input_fastq} not found")
    TP = posCount - FN
    FP = negCount - TN
    print(f"Total reads: {len(posSet) + len(negSet)} \nTP: {TP}\nFP: {FP}\nTN: {TN}\nFN: {FN}\n")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python script.py <filename> <filename> <filename>")
    else:
        negSet = makeSet(sys.argv[1])
        posSet = makeSet(sys.argv[2])
        findAccuracy(negSet, posSet, sys.argv[3])
