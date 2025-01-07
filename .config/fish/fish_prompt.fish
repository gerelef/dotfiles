# set the TRANSIENT variable & execute
#  inspired by https://github.com/fish-shell/fish-shell/pull/8142
set -g __fish_git_prompt_showcolorhints true
set -g __fish_git_prompt_color_branch yellow
set -g __fish_git_prompt_color_branch_staged yellow
set -g __fish_git_prompt_color_branch_detached magenta
set -g __fish_git_prompt_color_merging red
set -g __fish_git_prompt_color_prefix normal
set -g __fish_git_prompt_color_suffix normal
set -g __fish_git_prompt_color_bare yellow

set -g __fish_git_prompt_showdirtystate true
set -g __fish_git_prompt_showuntrackedfiles true
set -g __fish_git_prompt_describe_style contains
set -g __fish_git_prompt_shorten_branch_len 14

function transient-execute --description 'Set TRANSIENT & execute' #--on-event fish_preexec
    if commandline --is-valid || test -z "$(commandline)" && not commandline --paging-mode && commandline --is-valid
        set -g TRANSIENT
        commandline -f repaint
    end
    commandline -f execute
end

# after executing, delete the TRANSIENT variable
function reset-transient --description 'Reset TRANSIENT' --on-event fish_postexec
    set -e TRANSIENT
end

function fish_prompt --description 'Write out the prompt'
    # pipestatus MUST be first
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix '>'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix '#'
    end

    if set -q TRANSIENT
        echo -n -s "$suffix "
        return
    else
        bind \r transient-execute
    end

    set -l normal (set_color normal)
    set -q fish_color_status; or set -g fish_color_status red

    # Write pipestatus
    # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    echo -n -s (set_color $color_cwd) (prompt_pwd) $normal " "$prompt_status $suffix " "
end

function fish_right_prompt -d "Write out the right prompt"
    if set -q TRANSIENT
        echo -n ""
        return
    end

    if test $CMD_DURATION -gt 0
        set -g msec_TAKEN $CMD_DURATION
        set -g sec_TAKEN (math -s0 "$msec_TAKEN / 1000")
        set -g min_TAKEN (math -s0 "$sec_TAKEN / 60")
        if test $min_TAKEN -ge 1
            # If the time scale is minutes we can omit the msec
            set -g sec_TAKEN "$(math "$sec_TAKEN - $min_TAKEN * 60")s"
            set -g TIME_TAKEN "$(echo "$min_TAKEN")m $sec_TAKEN"
        else if test $sec_TAKEN -ge 1
            set -g msec_TAKEN "$(math "$msec_TAKEN - $sec_TAKEN * 1000")ms"
            set -g TIME_TAKEN "$(echo "$sec_TAKEN")s $msec_TAKEN"
        else
            set -g TIME_TAKEN "$(echo "$msec_TAKEN")ms"
        end
    end

    echo -n -s (fish_vcs_prompt) $normal " " (set_color blue) $TIME_TAKEN
end
