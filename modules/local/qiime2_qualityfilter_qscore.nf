// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options    = initOptions(params.options)

process QIIME2_QUALITYFILTER_QSCORE {
    tag "$demux_qza"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? { exit 1 "QIIME2 has no conda package" } : null)
    container "quay.io/qiime2/core:2021.2"

    input:
    path demux_qza

    output:
    path "*filtered.qza"     , emit: qza
    path "*stats.qza"        , emit: stats
    path "*.version.txt"     , emit: version

    script:
    def software      = getSoftwareName(task.process)
    """
    qiime quality-filter q-score \\
        --i-demux  ${demux_qza} \\
        $options.args \\
        --o-filtered-sequences demux_filtered.qza \\
        --o-filter-stats demux_filtered_stats.qza
    echo \$(qiime --version | sed -e "s/q2cli version //g" | tr -d '`' | sed -e "s/Run qiime info for more version details.//g") > ${software}.version.txt
    """
}