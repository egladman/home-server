__logger() {
    # Usage: log <prefix> <message>
    #        log WARN "hello world"

    printf -v now '%(%m-%d-%Y %H:%M:%S)T' -1
    printf '%b\n' "[${1:: 4}] ${now} ${0##*/} ${2}"
}

log::warn() {
    __logger "WARN" "$*"
}

log::info() {
    __logger "INFO" "$*"
}

log::error() {
    __logger "ERROR" "$*"
}
