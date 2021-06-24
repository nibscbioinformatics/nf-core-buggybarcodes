# nf-core-buggybarcodes: Usage

## Introduction

Nextflow handles job submissions on SLURM or other environments, and supervises running the jobs. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/buggybarcodes -profile singularity --input_manifest '/FULL/PATH/TO/DATA' --classifier '/FULL/PATH/TO/DOWNLOADED/CLASSIFIER' --metadata '/FULL/PATH/TO/METADATA'
```

This will launch the pipeline with the `singularity` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```
## Sample Input

Currently, `buggybarcodes` can only take paired-end reads as input. A future update will focus on implementing single-end reads functionality
The `buggybarcodes` pipeline can take input in two forms: as a directory containing the paired-end sequencing reads (--input_dir) and a manifest file containing the full paths to the sequencing reads (--input_manifest)
**Please Note** `--input_dir` and `--input_manifest` cannot be provided as input at the same time - please specify one option

### Input Reads (--input_dir)

The input can be a directory containing the paired-end sequencing reads

```bash
--input_dir '[path to samplesheet file]'
```
### Input Manifest FIle (--input_manifest)

You can submit a manifest file as an alternative way to provide input reads. No submission of read files with `--input_dir` is required this way.

sample-id	forward-absolute-filepath	reverse-absolute-filepath

A manifest must be a tab-separated file that *must have the following labels in this exact order*: sample-id, forward-absolute-filepath, reverse-absolute-filepath*. In case of single-end reads, the labels should be: sample-id, absolute-filepath. The sample identifiers must be listed under sample-id. Paths to forward and reverse reads must be reported under forward-absolute-filepath and reverse-absolute-filepath, respectively. Path to single-end must be reported under absolute-filepath.

An example of a `manifest.tsv` is located in the `assets` [folder](https://raw.githubusercontent.com/nibscbioinformatics/nf-core-buggybarcodes/dev/assets/test_manifest.tsv). Further information on the manifest file format can be viewed on the QIIME2 [documentation](https://docs.qiime2.org/2021.4/tutorials/importing)

### Input Metadata

his is optional, but for performing downstream analysis such as barplots, diversity indices or differential abundance testing, a metadata file is essential.

```bash
--metadata "path/to/metadata.tsv"
```

Please note the following requirements:

1. The path must be enclosed in quotes
2. The metadata file has to follow the QIIME2 specifications (https://docs.qiime2.org/2019.10/tutorials/metadata/)

The first column in the metadata file is the identifier (ID) column and defines the sample or feature IDs associated with your study. Metadata files are not required to have additional metadata columns, so a file containing only an ID column is a valid QIIME 2 metadata file. Additional columns defining metadata associated with each sample or feature ID are optional. NB: without additional columns there might be no groupings for the downstream analyses.

### Multi-Run Samples

Unfortunately unlike the shotgun metagenomics bagobugs pipeline, buggybarcodes cannot handle multisample runs. **Please note** Denoisers should not be run on combined samples as they build a per-sampling run error profile.


### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/buggybarcodes
```

### Reproducibility

It's a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/buggybarcodes releases page](https://github.com/nf-core/buggybarcodes/releases) and find the latest version number - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

## Pipeline Parameters

### `--input_dir`

Use this to specify the location of your input FastQ files. For example:

```bash
--input_dir 'path/to/data'
```

Please note the following requirements:

1. The path must be enclosed in quotes
`

### `--input_manifest`

Use this to specify the location of the manifest file containing sample-id info and paths to the FastQ files. For example:

```bash
--input_manifest 'path/to/data/manifest.tsv'
```

Please note the following requirements:

1. The path must be enclosed in quotes
2. The tsv must contain a header
3. The first column of the csv file should be `sample-id`
4. The second column of the csv file should be `forward-absolute-filepath`
5. The third column of the csv file should be `reverse-absolute-filepath`

### `--metadata`

Sample metadata file. The first column in the metadata file is the identifier (ID) column and defines the sample or feature IDs associated with your study

```bash
--metadata 'path/to/metadata.txt'
```

Please note the following requirements:

1. The path must be enclosed in quotes
2. The tsv must contain a header
3. The first column of the csv file should be `sampleid`

### `--classifier`

QIIME2 object containing the naive bayes classifier for taxonomic identification

```bash
--classifier 'path/to/classifier.qza'
```
### `--forward-primer`

Forward primer sequence (must be enclosed in quotes)

### `--reverse-primer`

Reverse primer sequence (must be enclosed in  quotes)
### `--abundance`

Relatvie abundance threshold for a given a taxa to be retained in the sample (0-1)
### `--prevalence`

Proportion of samples a taxon must appear in to be retained (0-1)
### `--discard_untrimmed`

Cutadapt will remove untrimmed reads

## Core Nextflow arguments

> **NB:** These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Conda) - see below.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended.

* `docker`
  * A generic configuration profile to be used with [Docker](https://docker.com/)
  * Pulls software from Docker Hub: [`nfcore/buggybarcodes`](https://hub.docker.com/r/nfcore/buggybarcodes/)
* `singularity`
  * A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
  * Pulls software from Docker Hub: [`nfcore/buggybarcodes`](https://hub.docker.com/r/nfcore/buggybarcodes/)
* `conda`
  * Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter or Charliecloud.
  * A generic configuration profile to be used with [Conda](https://conda.io/docs/)
  * Pulls most software from [Bioconda](https://bioconda.github.io/)
* `test`
  * A profile with a complete configuration for automated testing
  * Includes links to test data so needs no other parameters

If you are running from within a NIBSC cluster, a *nibsc* profile is also available

* `nibsc`
  * uses singularity by default
  * sets the right mounts to run on NIBSC HPC cluster
  * uses *slurm* as tasks scheduler

### `-resume`

Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

#### Custom resource requests

Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

Whilst these default requirements will hopefully work for most people with most data, you may find that you want to customise the compute resources that the pipeline requests. You can do this by creating a custom config file. For example, to give the workflow process `star` 32GB of memory, you could use the following config:

```nextflow
process {
  withName: qiime2_featureclassifier_classifysklearn {
    memory = 32.GB
  }
}
```

To find the exact name of a process you wish to modify the compute resources, check the live-status of a nextflow run displayed on your terminal or check the nextflow error for a line like so: `Error executing process > 'QIIME2_FEATURECLASSIFIER_CLASSIFYSKLEARN'`. In this case the name to specify in the custom config file is `QIIME2_FEATURECLASSIFIER_CLASSIFYSKLEARN`.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information.

### Tool-specific options

For the ultimate flexibility, we have implemented and are using Nextflow DSL2 modules in a way where it is possible to change tool-specific command-line arguments (e.g. providing an additional command-line argument to the `CUTADAPT` process) as well as publishing options (e.g. saving files produced by the `CUTADAPT` process that aren't saved by default by the pipeline). As this pipeline has been tailored to specific end-user requirements, it may be necessary to alter certain tools parameters to meet your requirements. In the majority of instances, as a user you won't have to change the default options set by the pipeline, however, there may be edge cases where creating a simple custom config file can improve the behaviour of the pipeline if for example it is failing due to a weird error that requires setting a tool-specific parameter to deal with smaller / larger genomes.

The command-line arguments passed to Cutadapt in the `CUTADAPT` module are a combination of:

* Mandatory arguments or those that need to be evaluated within the scope of the module, as supplied in the [`script`](https://github.com/nibscbioinformatics/nf-core-buggybarcodes/blob/main/modules/nf-core/software/cutadapt/main.nf) section of the module file.

* An [`options.args`](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/main/conf/modules.config) string of non-mandatory parameters that is set to default values for the module. These can be altered in the `conf/modules.config` file and used by the module in the sub-workflow / workflow context via the Nextflow `include` keyword and `addParams` Nextflow option [`see here`](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/main/workflows/bagobugs.nf).

As mentioned at the beginning of this section it may also be necessary for users to overwrite the options passed to modules to be able to customise specific aspects of the way in which a particular tool is executed by the pipeline. Given that all of the default module options are stored in the pipeline's `modules.config` as a [`params` variable](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/main/conf/modules.config) it is also possible to overwrite any of these options via a custom config file.

Say for example we want to append an additional, non-mandatory parameter (i.e. `--p-trim-length 250`) to the arguments passed to the `QIIME2_DEBLUR_DENOISE16S` module. Firstly, we need to access the default `args` specified in the [`modules.config`](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/main/conf/modules.config) and edit the config file and add additional options you would like to provide.

As you will see in the example below, we have:

* changed the default `publish_dir` value to where the files will eventually be published in the main results directory.
* changed the read length size to 250bp

```nextflow
params {
    modules {
       'qiime2_deblur_denoise16S' {
            args           = "--p-trim-length 250"
            publish_dir    = "new_results"

       }
    }
}

### Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

#### Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
