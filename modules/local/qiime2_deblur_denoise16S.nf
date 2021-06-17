// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options    = initOptions(params.options)

process QIIME2_DEBLUR_DENOISE16S {
    tag "$demux"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? { exit 1 "QIIME2 has no conda package" } : null)
    container "quay.io/qiime2/core:2021.2"

    input:
    path demux

    output:
    path "table-deblur.qza"                , emit: table
    path "*-seqs-deblur.qza"               , emit: rep_seqs
    path "stats-deblur.qza"                , emit: stats
    path "*.version.txt"                   , emit: version

    script:
    def software      = getSoftwareName(task.process)
    """
    qiime deblur denoise-16S \\
        --i-demultiplexed-seqs $demux \\
        $options.args \\
        --p-jobs-to-start $task.cpus \\
        --o-representative-sequences reps-seqs-deblur.qza \\
        --o-table table-deblur.qza \\
        --o-stats stats-deblur.qza
    echo \$(qiime --version | sed -e "s/q2cli version //g" | tr -d '`' | sed -e "s/Run qiime info for more version details.//g") > ${software}.version.txt
    """
}

