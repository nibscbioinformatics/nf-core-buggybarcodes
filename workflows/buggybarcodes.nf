////////////////////////////////////////////////////
/* --         LOCAL PARAMETER VALUES           -- */
////////////////////////////////////////////////////

params.summary_params = [:]

////////////////////////////////////////////////////
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.metadata, params.classifier ] //add back  params.multiqc_config,
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input_dir) { ch_input_dir         = Channel.fromPath("${params.input_dir}", type:'dir', checkIfExists:true ) } else { exit 1, 'Input samplesheet not specified!' }
if (params.input) { ch_input                 = Channel.fromPath("${params.input}", checkIfExists:true ) } else { exit 1, 'Input samplesheet not specified!' }
if (params.metadata) { ch_metadata           = Channel.fromPath("${params.metadata}", checkIfExists: true) } else { exit 1, 'metadata not specified' }
if (params.classifier) { ch_qiime_classifier = Channel.fromPath("${params.classifier}", checkIfExists: true) } else { exit 1, 'Classifier not specified' }

// make user aware that enabling conda will cause pipeline to fail
if (params.enable_conda) { log.warn "WARNING: QIIME 2 unavailable as Conda is enabled (--enable_conda). Use a container engine instead of conda to enable all software." }

// TODO
// Validate input parameters
// Workflow.validateWorkflowParams(params, log)

////////////////////////////////////////////////////
/* --          CONFIG FILES                    -- */
////////////////////////////////////////////////////

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

////////////////////////////////////////////////////
/* -- IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS-- *///
////////////////////////////////////////////////////

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

def multiqc_options   = modules['multiqc']
multiqc_options.args += params.multiqc_title ? Utils.joinModuleArgs(["--title \"$params.multiqc_title\""]) : ''

def qiime2_cutadapt_trimpaired_options = modules['qiime2_cutadapt_trimpaired']
//qiime2_cutadapt_trimpaired_options.args += params.discard_untrimmed ? " --p-discard-untrimmed" : " --p-no-discard-untrimmed"  // retain untrimmed reads
qiime2_cutadapt_trimpaired_options.args += params.discard_untrimmed ? Utils.joinModuleArgs([" --p-discard-untrimmed"]) : ""
// cutadapt_trimpaired_options.args += params.forward_primer ? if conf file doesnt work try this

// Modules: local
include { GET_SOFTWARE_VERSIONS                      } from '../modules/local/get_software_versions'        addParams( options: [publish_files : ['csv':'']]       )
include { QIIME2_IMPORT                              } from '../modules/local/qiime2_import'                addParams( options: modules['qiime2_import']           )
include { QIIME2_CUTADAPT_TRIMPAIRED                 } from '../modules/local/qiime2_cutadapt_trimpaired'   addParams( options: qiime2_cutadapt_trimpaired_options        )
include { QIIME2_VSEARCH_JOINPAIRS                   } from '../modules/local/qiime2_vsearch_joinpairs'     addParams( options: modules['qiime2_vsearch_joinpairs']        )
include { QIIME2_QUALITYFILTER_QSCORE                } from '../modules/local/qiime2_qualityfilter_qscore'  addParams( options: modules['qiime2_qualityfilter_qscore']        )
include { QIIME2_DEBLUR_DENOISE16S                   } from '../modules/local/qiime2_deblur_denoise16S'     addParams( options: modules['qiime2_deblur_denoise16S']        )
include { QIIME2_FEATURECLASSIFIER_CLASSIFYSKLEARN   } from '../modules/local/qiime2_featureclassifier_classifysklearn'     addParams( options: modules['qiime2_featureclassifier_classifysklearn']    )

// Modules: nf-core/modules
include { FASTQC as FASTQC_RAW                       } from '../modules/nf-core/software/fastqc/main'       addParams( options: modules['fastqc_raw']            )
include { FASTQC as FASTQC_TRIMMED                   } from '../modules/nf-core/software/fastqc/main'       addParams( options: modules['fastqc_trimmed']        )
include { MULTIQC                                    } from '../modules/nf-core/software/multiqc/main'      addParams( options: multiqc_options                  )
include { CAT_FASTQ                                  } from '../modules/nf-core/software/cat/fastq/main'    addParams( options: modules['cat_fastq']             )
include { CUTADAPT                                   } from '../modules/nf-core/software/cutadapt/main'     addParams( options: modules['cutadapt']              )

// Subworkflows: local
include { INPUT_CHECK                                } from '../subworkflows/input_check'                   addParams( options: [:]                              )

////////////////////////////////////////////////////
/* --           RUN MAIN WORKFLOW              -- */
////////////////////////////////////////////////////

// Info required for completion email and summary
def multiqc_report    = []

workflow BUGGYBARCODES {
    ch_software_versions = Channel.empty()

/*
=====================================================
        Sample Check & Input Staging
=====================================================
*/

// Parse the input csv file and stage channels

    INPUT_CHECK (
        ch_input
    )
    .map {
        meta, fastq ->
            meta.id = meta.id.split('_')[0..-2].join('_')
            [ meta, fastq ] }
    .groupTuple(by: [0])
    .branch {
        meta, fastq ->
            single  : fastq.size() == 1
                return [ meta, fastq.flatten() ]
            multiple: fastq.size() > 1
                return [ meta, fastq.flatten() ]
    }
    .set { ch_fastq_cat }

    //
    // MODULE: Concatenate FastQ files from same sample if required
    //

    CAT_FASTQ (
        ch_fastq_cat.multiple
    )
    .mix(ch_fastq_cat.single)
    .set { ch_fastq }

/*
=====================================================
        Preprocessing and QC for short reads
=====================================================
*/

    FASTQC_RAW (
       ch_fastq
    )
    ch_software_versions = ch_software_versions.mix(FASTQC_RAW.out.version.first().ifEmpty(null))

    CUTADAPT (
        ch_fastq
    )
    ch_trimmed_reads = CUTADAPT.out.reads
    //ch_qiime2_reads = CUTADAPT.out.reads.collect{it[1]} doesnt work.. need to provide directory as input, unless I can combine
    ch_software_versions = ch_software_versions.mix(CUTADAPT.out.version.first().ifEmpty(null))

    FASTQC_TRIMMED (
        ch_trimmed_reads
    )

/*
===================================================
        QIIME 2: Import Artifact Object
===================================================
*/

    QIIME2_IMPORT (
        ch_input_dir
    )
    ch_qiime2_artifact = QIIME2_IMPORT.out.qza

    QIIME2_CUTADAPT_TRIMPAIRED (
        ch_qiime2_artifact
    )
    ch_trimmed_artifact = QIIME2_CUTADAPT_TRIMPAIRED.out.qza

    QIIME2_VSEARCH_JOINPAIRS (
        ch_trimmed_artifact
    )
    ch_joined_artifact = QIIME2_VSEARCH_JOINPAIRS.out.qza

    QIIME2_QUALITYFILTER_QSCORE (
        ch_joined_artifact
    )
    ch_filtered_artifact = QIIME2_QUALITYFILTER_QSCORE.out.qza


    QIIME2_DEBLUR_DENOISE16S (
        ch_filtered_artifact
    )
    ch_rep_seqs = QIIME2_DEBLUR_DENOISE16S.out.rep_seqs

    QIIME2_FEATURECLASSIFIER_CLASSIFYSKLEARN (
        ch_qiime_classifier,
        ch_rep_seqs
    )


/*
==========================================
        Get Software Versions
==========================================
*/

    GET_SOFTWARE_VERSIONS (
        ch_software_versions.map { it }.collect()
    )

/*
=============================
        MultiQC
=============================
*/
if (!params.skip_multiqc) {
    workflow_summary    = Workflow.paramsSummaryMultiqc(workflow, params.summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(GET_SOFTWARE_VERSIONS.out.yaml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_RAW.out.zip.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_TRIMMED.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
            ch_multiqc_files.collect()
    )

    multiqc_report = MULTIQC.out.report.toList()
    ch_software_versions = ch_software_versions.mix(MULTIQC.out.version.ifEmpty(null))

    }
}

////////////////////////////////////////////////////
/* --              COMPLETION EMAIL            -- */
////////////////////////////////////////////////////

workflow.onComplete {
    Completion.email(workflow, params, params.summary_params, projectDir, log, multiqc_report)
    Completion.summary(workflow, params, log)
}

////////////////////////////////////////////////////
/* --                  THE END                 -- */
////////////////////////////////////////////////////