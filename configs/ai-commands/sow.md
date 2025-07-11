# Create SOW (ARGUMENTS: $0=path of the file or directory, $1=verb of the SOW, $2=output directory)

- Please create SOW with diffs.

## Arguments

- $0 : path of the file or directory
- $1 : verb of the SOW
- $2 : output directory
- e.g.: $0=`./main.go`, $1=`refactor`, $2=`./sows`
  - It means to create a SOW for `refactor` of the `./main.go` in the `./sows` directory.

## Rules

1. The SOW must be a markdown file.

2. The file name must be `{$1}_{$0}_sow.md`

- e.g.: $0=`./main.go`, $1=`refactor`, $2=`./sows`
  - file name would be `refactor_main.go_sow.md`

3. After execution, you must follow the instructions in the SOW in the session.

**IMPORTANT: SOW must be in English, but your reply must be in Japanese.**
