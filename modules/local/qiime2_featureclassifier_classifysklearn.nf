// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options    = initOptions(params.options)

process QIIME2_FEATURECLASSIFIER_CLASSIFYSKLEARN {
    tag "$rep_seqs,$trained_classifier"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? { exit 1 "QIIME2 has no conda package" } : null)
    container "quay.io/qiime2/core:2021.2"

    input:
    path trained_classifier
    path rep_seqs

    output:
    path "taxonomy.qza"          , emit: qza
    path "feature-classifier.log", emit: log
    path "*.version.txt"         , emit: version

    script:
    def software      = getSoftwareName(task.process)
    // export XDG_CONFIG_HOME="\${PWD}/HOME"  #dso this user-specific config file?? why including this...
    """
    qiime feature-classifier classify-sklearn \\
        --i-classifier ${trained_classifier} \\
        $options.args \\
        --p-n-jobs ${task.cpus} \\
        --i-reads ${rep_seqs} \\
        --o-classification taxonomy.qza \\
        > feature-classifier.log

    echo \$(qiime --version | sed -e "s/q2cli version //g" | tr -d '`' | sed -e "s/Run qiime info for more version details.//g") > ${software}.version.txt
    """
}