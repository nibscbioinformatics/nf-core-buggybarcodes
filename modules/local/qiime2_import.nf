// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options    = initOptions(params.options)

process QIIME2_IMPORT {
    tag "$reads_dir"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? { exit 1 "QIIME2 has no conda package" } : null)
    container "quay.io/qiime2/core:2021.2"

    input:
    path reads_dir // just need to provide folder paths
    // nned to look at using manifest file for imput...

    output:
    path "demux.qza"    , emit: qza
    path "*.version.txt", emit: version

    script:
    def software      = getSoftwareName(task.process)
    """
    qiime tools import \\
        --input-path  ${reads_dir} \\
        $options.args \\
        --output-path  demux.qza
    echo \$(qiime --version | sed -e "s/q2cli version //g" | tr -d '`' | sed -e "s/Run qiime info for more version details.//g") > ${software}.version.txt
    """
}

