# GNU Stow owns config leaves; the manifest also tracks our two agent links and
# the checkout pointer. Manifests are data, never sourced as shell scripts.

link_absolute() {
    local path=$1 part result='' old_ifs=$IFS
    local -a parts=()
    IFS=/ read -r -a parts <<< "$path"
    IFS=$old_ifs
    for part in "${parts[@]}"; do
        case "$part" in
            ''|.) ;;
            ..) result=${result%/*} ;;
            *) result="$result/$part" ;;
        esac
    done
    printf '%s\n' "${result:-/}"
}

link_points_to() {
    local target=$1 source=$2 value
    [ -L "$target" ] || return 1
    value=$(readlink "$target") || return 1
    case "$value" in /*) ;; *) value="${target%/*}/$value" ;; esac
    [ "$(link_absolute "$value")" = "$(link_absolute "$source")" ]
}

link_add() {
    local target=$1 source=$2 index
    case "$target$source" in *$'\t'*|*$'\n'*) die 'Link paths cannot contain tabs or newlines.' ;; esac
    for ((index=0; index<${#LINK_TARGETS[@]}; index++)); do
        [ "${LINK_TARGETS[index]}" != "$target" ] || die "Multiple configurations own $target"
        case "$target/" in "${LINK_TARGETS[index]}/"*) die "Overlapping configuration destinations: $target and ${LINK_TARGETS[index]}" ;; esac
        case "${LINK_TARGETS[index]}/" in "$target/"*) die "Overlapping configuration destinations: $target and ${LINK_TARGETS[index]}" ;; esac
    done
    LINK_TARGETS+=("$target")
    LINK_SOURCES+=("$source")
}

link_package() {
    local layer=$1 package=$2 source relative
    [ -d "$DOTFILES_DIR/config/$layer/$package" ] || return 0
    LINK_LAYERS+=("$layer")
    LINK_PACKAGES+=("$package")
    while IFS= read -r -d '' source; do
        relative=${source#"$DOTFILES_DIR/config/$layer/$package/"}
        case "$relative" in .DS_Store|*/.DS_Store) continue ;; esac
        link_add "$HOME/$relative" "$source"
    done < <(find "$DOTFILES_DIR/config/$layer/$package" \( -type f -o -type l \) -print0)
}

plan_links() {
    local layer package target source extra path status_file status
    for path in "$DOTFILES_DIR" "$HOME" "${XDG_DATA_HOME:-$HOME/.local/share}" "$STATE_DIR"; do
        case "$path" in /*) ;; *) die "Expected an absolute path: $path" ;; esac
        case "$path" in *$'\t'*|*$'\n'*) die 'Installation paths cannot contain tabs or newlines.' ;; esac
        [ "$path" = "$(link_absolute "$path")" ] || die "Use a normalized installation path without trailing slash, '.' or '..': $path"
        [ "$path" != / ] || die 'Installation directories cannot be the filesystem root.'
    done
    for status_file in "$STATE_DIR"/recovery.*/status; do
        [ -f "$status_file" ] || continue
        status=''
        IFS= read -r status < "$status_file" || true
        if [ "$status" != complete ] && [ "$status" != rolled-back ]; then
            log "Unfinished configuration recovery: ${status_file%/status}/README.txt"
            if [ "$DRY_RUN" != 1 ] && [ "${CHECK:-0}" != 1 ]; then
                die 'Resolve the recorded interrupted run before installing again.'
            fi
        fi
    done
    LINK_TARGETS=() LINK_SOURCES=() LINK_LAYERS=() LINK_PACKAGES=()
    OLD_TARGETS=() OLD_SOURCES=() RETIRE_TARGETS=()
    LINK_CHANGED_TARGETS=() LINK_CHANGED_VALUES=() LINK_NEW_TARGETS=() LINK_NEW_SOURCES=()
    LINK_BACKUP_TARGETS=() LINK_BACKUP_PATHS=()
    LINK_RECOVERY='' LINK_ACTIVE=0 LINK_METADATA_ACTIVE=0
    for layer in shared "$OS"; do
        for package in shell nvim tmux; do link_package "$layer" "$package"; done
        if [ "$PROFILE" = desktop ]; then link_package "$layer" "$TERMINAL"; fi
    done
    LINK_DIRECT_START=${#LINK_TARGETS[@]}
    link_add "${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/repo" "$DOTFILES_DIR"
    link_add "$HOME/.codex/AGENTS.md" "$DOTFILES_DIR/agents/AGENTS.md"
    link_add "$HOME/.config/opencode/AGENTS.md" "$DOTFILES_DIR/agents/AGENTS.md"
    if [ -f "$STATE_DIR/links.tsv" ]; then
        while IFS=$'\t' read -r target source extra; do
            [ -n "$target" ] && [ -n "$source" ] && [ -z "$extra" ] || die 'Invalid managed-link manifest.'
            case "$target" in "$HOME"/*|"${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/repo") ;; *) die "Unsafe managed-link destination: $target" ;; esac
            case "$source" in /*) ;; *) die 'Managed-link sources must be absolute.' ;; esac
            [ "$(link_absolute "$target")" = "$target" ] || die "Non-normalized managed-link destination: $target"
            OLD_TARGETS+=("$target") OLD_SOURCES+=("$source")
        done < "$STATE_DIR/links.tsv"
    fi
    # Legacy Stow used these top-level packages. Inspect current source trees
    # even for deselected packages, so core can retire old desktop links.
    for layer in shared macos linux; do
        for package in shell nvim tmux ghostty wezterm; do
            [ -d "$DOTFILES_DIR/config/$layer/$package" ] || continue
            while IFS= read -r -d '' source; do
                target="$HOME/${source#"$DOTFILES_DIR/config/$layer/$package/"}"
                if link_points_to "$target" "$DOTFILES_DIR/$package/${target#"$HOME/"}"; then
                    OLD_TARGETS+=("$target") OLD_SOURCES+=("$DOTFILES_DIR/$package/${target#"$HOME/"}")
                fi
            done < <(find "$DOTFILES_DIR/config/$layer/$package" \( -type f -o -type l \) -print0)
        done
    done
    if link_points_to "$HOME/.aliases" "$DOTFILES_DIR/shell/.aliases"; then
        OLD_TARGETS+=("$HOME/.aliases") OLD_SOURCES+=("$DOTFILES_DIR/shell/.aliases")
    fi
}

link_ancestors_safe() {
    local target=$1 parent
    parent=${target%/*}
    while [ "$parent" != / ] && [ -n "$parent" ]; do
        if [ -L "$parent" ] || { [ -e "$parent" ] && [ ! -d "$parent" ]; }; then
            log "Configuration ancestor must be a real directory: $parent"
            return 1
        fi
        parent=${parent%/*}
    done
}

link_safe_ancestors() {
    link_ancestors_safe "$1" || die "Unsafe configuration destination: $1"
}

link_is_old() {
    local target=$1 index
    for ((index=0; index<${#OLD_TARGETS[@]}; index++)); do
        if [ "${OLD_TARGETS[index]}" = "$target" ] && link_points_to "$target" "${OLD_SOURCES[index]}"; then return 0; fi
    done
    return 1
}

preflight_links() {
    local index target source planned=0 old_index quiet=${1:-0}
    for ((index=0; index<${#LINK_TARGETS[@]}; index++)); do
        target=${LINK_TARGETS[index]} source=${LINK_SOURCES[index]}
        link_safe_ancestors "$target"
        if link_points_to "$target" "$source"; then continue; fi
        if link_is_old "$target"; then
            if [ "$quiet" != 1 ]; then log "Migrate link: $target"; fi
            planned=1
        elif [ -e "$target" ] || [ -L "$target" ]; then
            [ "$BACKUP_AND_REPLACE" = 1 ] || die "Configuration conflict: $target
Existing destination left untouched; wanted a link to: $source
To back up and replace all conflicting destinations, rerun with --backup-and-replace.
Existing settings will not be merged. Add --dry-run to preview first."
            if [ "$quiet" != 1 ]; then
                log "Planned backup and replacement: $target -> $source"
                log '  The original will be saved in the recovery directory; settings will not be merged.'
            fi
            planned=1
        fi
    done
    RETIRE_TARGETS=()
    for ((old_index=0; old_index<${#OLD_TARGETS[@]}; old_index++)); do
        target=${OLD_TARGETS[old_index]}
        link_points_to "$target" "${OLD_SOURCES[old_index]}" || continue
        for ((index=0; index<${#LINK_TARGETS[@]}; index++)); do
            [ "${LINK_TARGETS[index]}" != "$target" ] || break
        done
        if [ "$index" = "${#LINK_TARGETS[@]}" ]; then
            link_safe_ancestors "$target"
            RETIRE_TARGETS+=("$target")
            if [ "$quiet" != 1 ]; then log "Retire owned link: $target"; fi
            planned=1
        fi
    done
    if [ "$DRY_RUN" = 1 ]; then
        if ! command -v stow >/dev/null 2>&1; then
            log 'Stow simulation deferred: Stow is not installed.'
        elif [ "$planned" = 1 ]; then
            log 'Stow simulation deferred until the reported link migration/conflicts are resolved.'
        else
            simulate_links
        fi
    fi
}

simulate_links() {
    local index output line
    for ((index=0; index<${#LINK_TARGETS[@]}; index++)); do link_safe_ancestors "${LINK_TARGETS[index]}"; done
    for ((index=0; index<${#LINK_PACKAGES[@]}; index++)); do
        if output=$(stow --simulate --no-folding --ignore='(^|/)\.DS_Store$' --dir="$DOTFILES_DIR/config/${LINK_LAYERS[index]}" --target="$HOME" "${LINK_PACKAGES[index]}" 2>&1); then
            # Hide only Stow's routine notice; retain every other diagnostic.
            while IFS= read -r line; do
                case "$line" in
                    ''|'WARNING: in simulation mode so not modifying filesystem.') ;;
                    *) log "$line" ;;
                esac
            done <<< "$output"
        else
            printf '%s\n' "$output" >&2
            die 'Stow simulation failed.'
        fi
    done
    log "Stow simulation passed: ${#LINK_PACKAGES[@]} packages."
}

link_remove_owned() {
    local target=$1 value
    link_safe_ancestors "$target"
    link_is_old "$target" || die "Link changed during installation: $target"
    value=$(readlink "$target") || die "Cannot read link: $target"
    printf 'link\t%s\t%s\n' "$target" "$value" >> "$LINK_RECOVERY/journal.tsv" || die 'Cannot write recovery journal.'
    LINK_CHANGED_TARGETS+=("$target") LINK_CHANGED_VALUES+=("$value")
    unlink "$target" || die "Cannot remove owned link: $target"
}

apply_links() {
    local index target source backup
    [ "$DRY_RUN" != 1 ] || return 0
    preflight_links 1
    log 'Link destinations rechecked.'
    LINK_RECOVERY=$(mktemp -d "$STATE_DIR/recovery.XXXXXXXX") || die 'Cannot create link recovery directory.'
    chmod 700 "$LINK_RECOVERY" || die 'Cannot protect link recovery directory.'
    for target in links.tsv selection; do
        if [ -f "$STATE_DIR/$target" ]; then
            cp -p "$STATE_DIR/$target" "$LINK_RECOVERY/$target.before" || die 'Cannot snapshot installation metadata.'
        else
            touch "$LINK_RECOVERY/$target.absent" || die 'Cannot record installation metadata.'
        fi
    done
    printf '%s\n' \
        'This directory records a configuration-link transaction. Do not execute journal.tsv.' \
        'An in-progress status requires manual inspection before another installation.' \
        'Rows are tab-separated: operation, absolute destination, original link value or backup/source path.' \
        'Recover in this order, checking every destination has not since been changed:' \
        '1. For new rows, remove only symlinks that still resolve to the recorded source.' \
        '2. For link rows, recreate the original raw symlink value only when the destination is absent.' \
        '3. For backup rows, move the backup back only when it exists and the destination is absent.' \
        'Never traverse symlinked parent directories. Do not overwrite newer files.' \
        'Old-layout links require restoring their original repository layout/revision to become usable.' \
        '4. Restore links.tsv.before and selection.before into the parent state directory.' \
        '   An .absent marker means that corresponding state file did not previously exist.' \
        '5. Once all recovery is verified, replace the status text with rolled-back.' \
        'Package and runtime installations are not rolled back. Empty directories may remain.' \
        > "$LINK_RECOVERY/README.txt" || die 'Cannot write recovery instructions.'
    printf 'in-progress\n' > "$LINK_RECOVERY/status" || die 'Cannot record transaction status.'
    LINK_ACTIVE=1
    log "Link recovery records: $LINK_RECOVERY"
    for target in "${RETIRE_TARGETS[@]}"; do
        # Duplicate legacy/manifest entries can refer to the same link.
        [ -L "$target" ] || continue
        link_remove_owned "$target"
    done
    for ((index=0; index<${#LINK_TARGETS[@]}; index++)); do
        target=${LINK_TARGETS[index]} source=${LINK_SOURCES[index]}
        link_safe_ancestors "$target"
        link_points_to "$target" "$source" && continue
        if link_is_old "$target"; then
            link_remove_owned "$target"
        elif [ -e "$target" ] || [ -L "$target" ]; then
            [ "$BACKUP_AND_REPLACE" = 1 ] || die "Configuration changed during installation: $target"
            backup="$LINK_RECOVERY/files/$index"
            mkdir -p "$LINK_RECOVERY/files" || die 'Cannot create backup directory.'
            printf 'backup\t%s\t%s\n' "$target" "$backup" >> "$LINK_RECOVERY/journal.tsv" || die 'Cannot write recovery journal.'
            LINK_BACKUP_TARGETS+=("$target") LINK_BACKUP_PATHS+=("$backup")
            mv "$target" "$backup" || die "Cannot back up $target"
            log "Backed up: $target -> $backup"
        fi
        LINK_NEW_TARGETS+=("$target") LINK_NEW_SOURCES+=("$source")
        printf 'new\t%s\t%s\n' "$target" "$source" >> "$LINK_RECOVERY/journal.tsv" || die 'Cannot write recovery journal.'
    done
    simulate_links
    for ((index=0; index<${#LINK_PACKAGES[@]}; index++)); do
        stow --no-folding --ignore='(^|/)\.DS_Store$' --dir="$DOTFILES_DIR/config/${LINK_LAYERS[index]}" --target="$HOME" "${LINK_PACKAGES[index]}" || die 'Stow linking failed.'
    done
    # Create direct links declared after the Stow-managed package entries.
    for ((index=LINK_DIRECT_START; index<${#LINK_TARGETS[@]}; index++)); do
        target=${LINK_TARGETS[index]} source=${LINK_SOURCES[index]}
        link_safe_ancestors "$target"
        if ! link_points_to "$target" "$source"; then
            mkdir -p "${target%/*}" || die "Cannot create parent of $target"
            ln -s "$source" "$target" || die "Cannot link $target"
        fi
    done
    for ((index=0; index<${#LINK_TARGETS[@]}; index++)); do
        link_points_to "${LINK_TARGETS[index]}" "${LINK_SOURCES[index]}" || die "Link verification failed: ${LINK_TARGETS[index]}"
        printf '%s\t%s\n' "${LINK_TARGETS[index]}" "${LINK_SOURCES[index]}"
    done > "$LINK_RECOVERY/links.tsv"
    for ((index=0; index<${#LINK_NEW_TARGETS[@]}; index++)); do
        log "Linked: ${LINK_NEW_TARGETS[index]} -> ${LINK_NEW_SOURCES[index]}"
    done
}

commit_links() {
    [ "${LINK_ACTIVE:-0}" = 1 ] || return 0
    [ -f "$STATE_DIR/selection.new" ] || die 'Missing pending selection state.'
    LINK_METADATA_ACTIVE=1
    mv "$LINK_RECOVERY/links.tsv" "$STATE_DIR/links.tsv" || die 'Cannot commit managed links.'
    mv "$STATE_DIR/selection.new" "$STATE_DIR/selection" || die 'Cannot commit selected profile.'
    printf 'complete\n' > "$LINK_RECOVERY/status" || die 'Cannot complete link transaction.'
    LINK_ACTIVE=0
}

rollback_links() {
    local index target backup failed=0 name
    [ "${LINK_ACTIVE:-0}" = 1 ] || return 0
    LINK_ACTIVE=0
    log "Rolling back this run's configuration links; recovery records: $LINK_RECOVERY"
    for ((index=${#LINK_NEW_TARGETS[@]}-1; index>=0; index--)); do
        target=${LINK_NEW_TARGETS[index]}
        link_ancestors_safe "$target" || { log "Rollback skipped unsafe destination: $target"; failed=1; continue; }
        if link_points_to "$target" "${LINK_NEW_SOURCES[index]}"; then
            unlink "$target" || { log "Could not remove $target"; failed=1; }
        elif [ -e "$target" ] || [ -L "$target" ]; then
            log "Rollback skipped changed destination: $target"
            failed=1
        fi
    done
    for ((index=${#LINK_CHANGED_TARGETS[@]}-1; index>=0; index--)); do
        target=${LINK_CHANGED_TARGETS[index]}
        link_ancestors_safe "$target" || { log "Rollback skipped unsafe destination: $target"; failed=1; continue; }
        if [ ! -e "$target" ] && [ ! -L "$target" ]; then
            ln -s "${LINK_CHANGED_VALUES[index]}" "$target" || { log "Could not restore $target"; failed=1; }
        else
            log "Restore skipped; destination changed: $target"
            failed=1
        fi
    done
    for ((index=${#LINK_BACKUP_TARGETS[@]}-1; index>=0; index--)); do
        target=${LINK_BACKUP_TARGETS[index]} backup=${LINK_BACKUP_PATHS[index]}
        [ -e "$backup" ] || [ -L "$backup" ] || continue
        link_ancestors_safe "$target" || { log "Rollback skipped unsafe destination: $target"; failed=1; continue; }
        if [ ! -e "$target" ] && [ ! -L "$target" ]; then
            mv "$backup" "$target" || { log "Could not restore $target from $backup"; failed=1; }
        else
            log "Backup retained at $backup; destination changed: $target"
            failed=1
        fi
    done
    if [ "${LINK_METADATA_ACTIVE:-0}" = 1 ]; then
        for name in links.tsv selection; do
            if [ -f "$LINK_RECOVERY/$name.before" ]; then
                cp -p "$LINK_RECOVERY/$name.before" "$STATE_DIR/$name" || failed=1
            elif [ -f "$LINK_RECOVERY/$name.absent" ] && [ -f "$STATE_DIR/$name" ]; then
                unlink "$STATE_DIR/$name" || failed=1
            fi
        done
    fi
    if [ "$failed" = 0 ]; then printf 'rolled-back\n' > "$LINK_RECOVERY/status" || failed=1; fi
    return "$failed"
}
