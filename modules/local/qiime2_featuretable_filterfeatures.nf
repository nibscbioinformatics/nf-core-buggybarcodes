// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options    = initOptions(params.options)

process QIIME2_FEATURETABLE_FILTERFEATURES {
    tag "$deblur_table"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? { exit 1 "QIIME2 has no conda package" } : null)
    container "quay.io/qiime2/core:2021.2"

    input:
    path deblur_table

    output:
    path 'table-deblur-filtered.qza' , emit: qza
    path '*.version.txt'             , emit: version

    script:
    def software     = getSoftwareName(task.process)
    """
    qiime feature-table filter-features \\
        --i-table $deblur_table \\
        $options.args \\
        --o-filtered-table table-deblur-filtered.qza \\
        > filter-features_sample.log
    echo \$(qiime --version | sed -e "s/q2cli version //g" | tr -d '`' | sed -e "s/Run qiime info for more version details.//g") > ${software}.version.txt
    """
}