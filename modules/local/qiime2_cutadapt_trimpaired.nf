// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options    = initOptions(params.options)

process QIIME2_CUTADAPT_TRIMPAIRED {
    //tag "$demux"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? { exit 1 "QIIME2 has no conda package" } : null)
    container "quay.io/qiime2/core:2021.2"

    input:
    path demux

    output:
    path "*.qza"                , emit: qza
    path "*.log"                , emit: log
    path "*.version.txt"        , emit: version

    script:
    def software      = getSoftwareName(task.process)
    """

    qiime cutadapt trim-paired \\
        --i-demultiplexed-sequences $demux \\
        --o-trimmed-sequences demux_trimmed.qza \\
        --p-cores $task.cpus \\
        $options.args \\
        > cutadapt_trimpairs.log
    echo \$(qiime --version | sed -e "s/q2cli version //g" | tr -d '`' | sed -e "s/Run qiime info for more version details.//g") > ${software}.version.txt
    """
}

