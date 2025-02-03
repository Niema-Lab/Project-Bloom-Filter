# Run this file with
# python accuracyBiobloom.py merged_R1.fq merged_R2.fq nonhost_reads.fq
import sys

# Count total number of human and virus reads based on IDs
# (a) List of FASTQ files
def countReads(input_fastq_list):
    virusCount = 0
    humanCount = 0
    for input_fastq in input_fastq_list:
        with open(input_fastq, "r") as f:
            while True:
                try:
                    readID = next(f) # ID
                    next(f) # Sequence
                    next(f) # Plus sign
                    next(f) # Quality scores
                    if (readID.startswith("@NC_045512.2")):
                        virusCount += 1
                    else:
                        humanCount += 1
                except StopIteration: # Throw when EOF
                    break
                except FileNotFoundError:
                    print(f"File {input_fastq} not found")
    return (virusCount, humanCount)

# Find TP, FP, TN, FN given
# a. Total number of virus reads
# b. Total number of human reads
# c. Biobloom output file (FASTQ)
def findAccuracy(virusCount, humanCount, output_fastq):
    TN = 0
    FN = 0
    with open(output_fastq, "r") as f:
        while True:
                try:
                    readID = next(f) # ID
                    next(f) # Sequence
                    next(f) # Plus sign
                    next(f) # Quality scores
                    if (readID.startswith("@NC_045512.2")):
                        TN += 1
                    else:
                        FN += 1
                except StopIteration: # Throw when EOF
                    break
                except FileNotFoundError:
                    print(f"File {output_fastq} not found")
    TP = humanCount - FN
    FP = virusCount - TN
    print(f"Total reads: {virusCount+humanCount}\nTotal human reads: {humanCount}\nTotal virus reads: {virusCount}\n")
    print(f"TP: {TP}\nFP: {FP}\nTN: {TN}\nFN: {FN}\n")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python accuracyBiobloom.py <filename> <filename> <filename>")
    else:
        fileList = [sys.argv[1], sys.argv[2]]
        virusCount, humanCount = countReads(fileList)
        findAccuracy(virusCount, humanCount, sys.argv[3])
