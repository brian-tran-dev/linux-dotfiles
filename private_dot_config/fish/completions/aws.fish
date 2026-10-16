function __fish_aws_completer
    set -lx COMP_SHELL fish
    set -lx COMP_LINE (commandline)
    set -lx COMP_POINT (commandline -C)
    aws_completer | string trim --right
end

complete -e -c aws
complete -c aws -f -a '(__fish_aws_completer)'
