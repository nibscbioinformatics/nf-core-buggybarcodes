// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options    = initOptions(params.options)

process QIIME2_VSEARCH_JOINPAIRS {
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? { exit 1 "QIIME2 has no conda package" } : null)
    container "quay.io/qiime2/core:2021.2"

    input:
    path trim_qza // just need to provide folder paths
    // think of way to allow primers sequences input in command line and used here

    output:
    path "*.qza"    , emit: qza
    path "*.version.txt"        , emit: version

    script:
    def software      = getSoftwareName(task.process)
    """

    qiime vsearch join-pairs \\
        --i-demultiplexed-seqs $trim_qza \\
        --o-joined-sequences demux_joined.qza \\
        --p-threads $task.cpus \\
        $options.args
    echo \$(qiime --version | sed -e "s/q2cli version //g" | tr -d '`' | sed -e "s/Run qiime info for more version details.//g") > ${software}.version.txt
    """
}