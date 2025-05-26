read_set=$1
reference=$2
results_dir="results_$(date +'%Y-%m-%d_%H-%M-%S')"
mkdir -p "$results_dir"
mkdir -p "$results_dir/fastqc"

fastqc -t 6 -o "$results_dir/fastqc/" $1

minimap2 -a "$reference" "$read_set" > "$results_dir/mapping.sam"
samtools view -b "$results_dir/mapping.sam" > "$results_dir/mapping.bam"
samtools flagstat "$results_dir/mapping.bam" > "$results_dir/mapping-report"

get_mapping_percent() {
    percent=$(grep "mapped" $1 | grep -oP '\d+\.\d+(?=%)')
    echo $percent
}

mapping_percent=$(get_mapping_percent "$results_dir/mapping-report")
echo "Mapping percentage: $mapping_percent%"

if (( $(echo "$mapping_percent > 90" | bc -l) )); then
    echo "mapping is OK"
else
    echo "mapping is NOT OK, finishing"
    exit 1
fi

echo "Sorting and calling freebayes"

samtools sort "$results_dir/mapping.bam" > "$results_dir/mapping.sorted.bam"
freebayes -f "$reference" -b "$results_dir/mapping.sorted.bam" > "$results_dir/mapping.vcf"

echo "Successfully finished. You can see results in $results_dir/mapping.vcf"

