#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

p_error() { echo -n "$(tput setaf 1)ERROR:$(tput sgr0) $1"; }
p_warning() { echo -n "$(tput setaf 3)WARNING:$(tput sgr0) $1"; }
p_info() { echo -n "$(tput setaf 2)INFO:$(tput sgr0) $1"; }
p_parameter() { echo -n "$(tput setaf 6)$1$(tput sgr0)"; }

update_sha256() {
    [[ $# -ne 3 ]] && echo "$(p_error "update_sha256() requires 3 arguments!")" && return

    local config_yaml_file=$1
    local yq_package_expression=$2
    local sha256=$3

    local modified_config_yaml_file=$(mktemp)
    yq --yaml-output "${yq_package_expression}.sha256 = \"${sha256}\"" "${config_yaml_file}" >> "${modified_config_yaml_file}"
    local diff_out_file=$(mktemp)
    diff --ignore-blank-lines --unified=0 "${config_yaml_file}" "${modified_config_yaml_file}" > "${diff_out_file}" || true
    echo "<DIFF>"
    cat "${diff_out_file}"
    echo "</DIFF>"
    rm --force "${modified_config_yaml_file}"

    local patch_file=$(mktemp)
    head --lines=2 "${diff_out_file}" >> "${patch_file}"
    local include_hunk=0
    local hunk=''
    while IFS=$'\n' read -r line; do
        if [[ ${line} =~ ^'@@' ]]; then
            if [[ ${include_hunk} -eq 1 ]]; then
                break 
            fi
            include_hunk=0
            if [[ ! ${line} =~ ',0 @@'$ ]]; then
                include_hunk=1
                local initial_patch_offset=$(echo "${line}" | grep --only-matching --perl-regexp '^@@ -\K[0-9]+')
                local patch_offset="${initial_patch_offset}"
                local patch_length=$(echo "${line}" | grep --only-matching --perl-regexp '^@@ -[0-9]+,\K[0-9]+')
                patch_length=${patch_length:-1}
            fi
        elif [[ ${include_hunk} -eq 1 ]]; then
            local stripped_line=$(echo "${line}" | tr --delete '[:blank:]')
            if [[ ${stripped_line} != '-' ]] && [[ ! ${stripped_line} =~ ^'-#' ]]; then
                hunk="${hunk}${line}"$'\n'
            else
                patch_offset=$((initial_patch_offset - 1))
                patch_length=$((patch_length - 1))
            fi
        fi
    done < <(tail --lines=+3 "${diff_out_file}")
    rm --force "${diff_out_file}"
    hunk=${hunk::-1}
    
    hunk_header="@@ -${patch_offset}"
    if [[ patch_length -ne 1 ]]; then
        hunk_header="${hunk_header},${patch_length}" 
    fi
    hunk_header="${hunk_header} +0 @@"
    echo "${hunk_header}" >> "${patch_file}"
    echo "${hunk}" >> "${patch_file}"
    echo "<PATCH>"
    cat "${patch_file}"
    echo "</PATCH>"
    patch --quiet --no-backup-if-mismatch --input "${patch_file}" "${config_yaml_file}"
    rm --force "${patch_file}"
}

fetch_package() {
    [[ $# -ne 2 ]] && echo "$(p_error "fetch_package() requires 2 arguments!")" && return

    local config_yaml_file=$1
    local yq_package_expression=$2

    local package_yaml=$(yq --yaml-output "${yq_package_expression}" "${config_yaml_file}")
    local package_url=$(echo "${package_yaml}" | yq --raw-output '.url')
    local curl_options=$(echo "${package_yaml}" | yq --raw-output '.["curl-options"] // ""')
    local allow_insecure=$(echo "${package_yaml}" | yq --raw-output '.["allow-insecure"] // "false"' | tr '[:upper:]' '[:lower:]')
    local allow_redirect=$(echo "${package_yaml}" | yq --raw-output '.["allow-redirect"] // "false"' | tr '[:upper:]' '[:lower:]')
    local additional_curl_options=$(echo "${package_yaml}" | yq --raw-output '.["additional-curl-options"] // ""')

    if ! echo 'true yes' | grep --quiet --word-regexp --ignore-case "${allow_insecure}" \
        && [[ ! $(echo "${package_url}" | tr '[:upper:]' '[lower:]') =~ ^'https:' ]]; then
        echo "$(p_warning "$(p_parameter "\"${package_url}\"") is an insecure URL; Skipped package.")"
        return 
    fi

    local default_curl_options='--remote-name'
    curl_options=${curl_options:-${default_curl_options}}
    if echo 'true yes' | grep --quiet --word-regexp --ignore-case "${allow_redirect}"; then
        curl_options="--location ${curl_options}"
    fi
    curl_options="--compressed ${curl_options}"
    if echo 'true yes' | grep --quiet --word-regexp --ignore-case "${allow_insecure}"; then
        curl_options="--insecure ${curl_options}"
    fi
    curl_options="${curl_options} --clobber --remote-time"
    if [[ -n ${additional_curl_options} ]]; then
        curl_options="${curl_options} ${additional_curl_options}"
    fi

    local output_directory=$(echo "${item_category}|${item_name}" | tr '|' '/')
    output_directory="${base_output_directory}/${output_directory}"
    mkdir --parents "${output_directory}"
    local watch_file=$(mktemp)
    bash -c "curl ${curl_options} --output-dir '${output_directory}' '${package_url}'"
    local output_file=$(find "${output_directory}" -type f -newercc "${watch_file}")
    rm --force "${watch_file}"
    if [[ $(echo "${output_file}" | wc --lines) -ne 1 ]]; then
        echo "$(p_warning "Could not identify package file for URL $(p_parameter "\"${package_url}\""); Skipped package.")"
        return 
    fi

    echo "$(p_info "Successfully retrieved package file $(p_parameter "\"${output_file}\"").")"
    
    local new_sha256=$(sha256sum "${output_file}" | cut --delimiter=' ' --fields=1 | tr '[:upper:]' '[:lower:]')
    local last_sha256=$(echo "${package_yaml}" | yq --raw-output '.sha256 // ""' | tr '[:upper:]' '[:lower:]')
    if [[ ${new_sha256} == ${last_sha256} ]]; then
        echo "$(p_info "The SHA256 hash for this package file matches.")"
        return 
    fi
    if [[ -n ${last_sha256} ]]; then
        echo "$(p_warning "The SHA256 hash for this package file has changed.  Is it a new release?")"
    fi
    update_sha256 ${config_yaml_file} ${yq_package_expression} ${new_sha256}
}

main() {
    if [[ $# -ne 2 ]]; then
        echo "$(p_error "A configuration YAML file and an output directory must be specified!")"
        return
    fi

    local config_yaml_file=$1
    local base_output_directory=$2

    if [[ ! -f ${config_yaml_file} ]]; then
        echo "$(p_error "The configuration YAML file $(p_parameter "\"${config_yaml_file}\"") does not exist!")"
        return
    fi

    if [[ ! -d ${base_output_directory} ]]; then
        echo "$(p_error "The output directory does not exist!")"
        return
    fi

    cp --preserve "${config_yaml_file}" "${config_yaml_file}.$(date +%y%m%d_%H%M%S)"

    local yq_items_expression='.software'
    local item_count=$(yq "${yq_items_expression} | length" "${config_yaml_file}")
    local item_index=0
    while [[ ${item_index} -lt ${item_count} ]]; do
        local yq_item_expression="${yq_items_expression}[${item_index}]"
        local item_index=$((item_index + 1))

        local item_name=$(yq --raw-output "${yq_item_expression}.name" "${config_yaml_file}")
        local item_category=$(yq --raw-output "${yq_item_expression}.category" "${config_yaml_file}")
        echo "$(p_info "Fetching package files for $(p_parameter "\"${item_name}\"")...")"

        local yq_packages_expression="${yq_item_expression}.packages"
        local package_count=$(yq --raw-output "${yq_packages_expression} | length" "${config_yaml_file}")
        local package_index=0
        while [[ ${package_index} -lt ${package_count} ]]; do
            yq_package_expression="${yq_packages_expression}[${package_index}]"
            package_index=$((package_index + 1))

            fetch_package ${config_yaml_file} ${yq_package_expression}
        done
    done
}

main ${@}
