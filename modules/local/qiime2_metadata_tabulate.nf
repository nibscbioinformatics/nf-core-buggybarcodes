// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options    = initOptions(params.options)

process QIIME2_METADATA_TABULATE {
    tag "$artifact"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? { exit 1 "QIIME2 has no conda package" } : null)
    container "quay.io/qiime2/core:2021.2"

    input:
    path artifact

    output:
    path "taxonomy.qzv",  emit: qzv
    path "*.version.txt", emit: version

    script:
    def software      = getSoftwareName(task.process)
    // export XDG_CONFIG_HOME="\${PWD}/HOME"  #dso this user-specific config file?? why including this...
    """
    qiime metadata tabulate \\
        --m-input-file $artifact \\
        --o-visualization taxonomy.qzv
    echo \$(qiime --version | sed -e "s/q2cli version //g" | tr -d '`' | sed -e "s/Run qiime info for more version details.//g") > ${software}.version.txt
    """
}

