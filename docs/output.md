# nf-core/buggybarcodes: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.


## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/)
and processes data using the following steps:

* Sequencing Quality Control (`FastQC`)
* Import Sequences into QIIME (`QIIME2_Import`)
* Read Adapter & Trimming (`QIIME2_Cutadapt_TrimPaired`)
* Read Quality Trimming (`QIIME2_QualityFilter_QScore`)
* Join Read Pairs (`QIIME2_VSearch_JoinPairs`)
* Deblur Denoising and Amplicon Sequencing Variant Detection (`QIIME2_Deblur_Denoise16S`)
* Taxonomic Classification Using SILVA 138 Database (`QIIME2_FeatureClassifier_ClassifySklearn`)
* Filtering Taxon Tables (`QIIME2_Featuretable_FilterFeaturesConditionally`)
* Taxa Barplot (`QIIME2_Taxa_Barplot`)
* Export Data (`QIIME2_Tools_Export`)
* Overall pipeline run summaries (`MultiQC`)
## FastQC

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences.

For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

**Output files:**

* `fastqc/`
  * `*_fastqc.html`: FastQC report containing quality metrics for your untrimmed raw fastq files.
* `fastqc/zips/`
  * `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images.

> **NB:** The FastQC plots displayed in the MultiQC report shows _untrimmed_ reads. They may contain adapter sequence and potentially regions with low quality.

## MultiQC

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarizing all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability.

For more information about how to use MultiQC reports, see [https://multiqc.info](https://multiqc.info).

**Output files:**

* `multiqc/`
  * `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  * `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  * `multiqc_plots/`: directory containing static images from the report in various formats.


## QIIME2

Quantitative Insights Into Microbial Ecology 2 (QIIME2) is a next-generation microbiome bioinformatics platform and the successor of the widely used QIIME1. QIIME2 is currently under heavy development and often updated, this version of ampliseq uses QIIME2 2021.10. QIIME2 has a wide variety of analysis tools available and has excellent support in its forum.

All Analysis steps are performed inside the QIIME2 framework

### QIIME2 Import

At this point of the analysis the raw reads are imported into QIIME2 and an interactive quality plot is made.

**Output files:**

* `Analysis/QIIME2/imported_reads/`
  * // TODO generate quality plots?
  * `demux.qza` QIIME2 artefact for imported reads.

### QIIME2 Cutadapt TrimPaired

Cutadapt is a tool used for trimming primer sequences from sequencing reads. Primer sequences are non-biological sequences that often introduce point mutations that do not reflect sample sequences - it is improtant to remove primer sequences prior to denosiing to prevent identification of artificial ASVs

**Output files**

* `Analysis/QIIME2/trimmed_reads/`
  * `cutadapt_trimpaired.log` Log file of trimming statistics
  * `demux_trimmed.qza` QIIME2 artefact for trimmed reads.

### QIIME2 Quality Score Trimming

This QIIME2 plugin filters sequence based on quality scores and the presence of ambiguous base calls.

**Output files**

* `Analysis/QIIME2/filtered_reads/`
  * `demux_filtered_stats` Log file of quality filtering statistics
  * `demux_filtered.qza` QIIME2 artefact for quality filtered reads.

### QIIME2 VSearch JoinPairs

Join paired-end sequence reads using vsearch's merge_pairs function. The qmin, qminout, qmax, and qmaxout parameters should only need to be modified when working with older fastq sequence data. See the vsearch documentation for details on how paired-end joining is performed, and for more information on the parameters to this method.

**Output files**

* `Analysis/QIIME2/joined_reads/`
  * `demux_filtered_stats` Log file
  * `demux_joined.qza` QIIME2 artefact for joined reads.

### QIIME2 Deblur 16S Amplicon Denoising

Perform sequence quality control for Illumina data using the Deblur workflow with a 16S reference as a positive filter. The specific reference used is the 88% OTUs from Greengenes 13_8. This mode of operation should only be used when data were generated from a 16S amplicon protocol on an Illumina platform. The reference is only used to assess whether each sequence is likely to be 16S by a local alignment using SortMeRNA with a permissive e-value; the reference is not used to characterize the sequences.

**Output files**

* `Analysis/QIIME2/deblur/`
  * `reps-seqs-deblur.qza` The resulting feature sequences
  * `table-deblur.qza` The resulting denoised feature table
  * `stats-deblur.qza`Per-sample stats

### QIIME2 Feature Classifier

ASV sequences acquired from the Deblur denosing are classified against the SILVA v138 database to add taxonomic information.

**Output files**

* `Analysis/QIIME2/classified_features/`
  * `taxonomy.qza` QIIME2 artifact of table of taxonomic classifications
  * `taxonomy.qzv` QIIME2 visualisation object of table of taxonomic classifications
  * `feature-classifier.log` Log file

### QIIME2 Filtering Features

Filter taxa from the taxonomic table  using `--prevalence` and `--abundance` thresholds to produce a final output table

**Output files**

* `Analysis/QIIME2/filtered_features/`
  * `table-deblur-filtered.qza` QIIME2 artifact of final taxonomic classification table
  * `filter-features-conditionally.log` Log file

### QIIME2 Barplot

Produces an interactive abundance plot count tables that aids exploratory browsing the discovered taxa and their abundance in samples

**Output files**

* `Analysis/QIIME2/output_plots/`
  * `taxa-barplot.qzv` QIIME2 taxa barplot visualisation object
  * `taxa-barplot.log` Log file

### QIIME2 Export

n order to use QIIME 2, your input data must be stored in QIIME 2 artifacts (i.e. .qza files). Sometimes you’ll want to export data from a QIIME 2 artifact, for example to analyze data with a different microbiome analysis program, or to do statistical analysis in R. This can be achieved using `qiime tools export`.



## Pipeline information

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage. The data in the artifact will exported to one or more files depending on the specific artifact. For `buggybarcode`, both feature tables and barplots are exported.

**Output files**

// TODO tidy this output for final release
* `Analysis/QIIME2/<output_plots/output_tablle>/export`



**Output files:**

* `pipeline_info/`
  * Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  * Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.csv`.
  * Documentation for interpretation of results in HTML format: `results_description.html`.
