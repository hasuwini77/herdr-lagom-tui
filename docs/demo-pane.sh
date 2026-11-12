#!/bin/sh
# One stand-in agent pane for the demo picture: prints a few invented lines, then waits.
# No real agent runs. Usage: demo-pane.sh <lead|tests|ask|idle> [title]
c() { printf '\033[%sm' "$1"; }
r=$(c 0); dim=$(c 90); blue=$(c 34); cyan=$(c 36); green=$(c 32); yellow=$(c 33); red=$(c 31); bold=$(c 1)
[ -n "${2:-}" ] && printf '\033]0;%s\007' "$2"   # the terminal title: the topic `lagom status` shows
clear
case "${1:-lead}" in
lead) cat <<EOT

 ${dim}❯${r} ${bold}Add CSV import to the recipe API, with tests${r}

 ${cyan}●${r} Split into three parts, one worktree each
   ${dim}└${r} ${green}✓${r} parser        ${dim}feat/csv-parser    merged${r}
   ${dim}└${r} ${yellow}◐${r} upload route  ${dim}feat/csv-upload    waiting on an answer${r}
   ${dim}└${r} ${green}✓${r} error report  ${dim}feat/csv-errors    merging${r}

 ${cyan}●${r} Merging the error report into feat/csv-import
   ${dim}└ 31 tests passed, 0 failed${r}
   ${dim}└ no conflicts in src/import/${r}

 ${cyan}●${r} Waiting on the upload route before the last check
   ${dim}└ photo-sync asked a question${r}
EOT
;;
tests) cat <<EOT

 ${dim}❯${r} ${bold}Run the suite and fix what breaks${r}

 ${green}●${r} 48 tests passed in 2.7s
   ${dim}└ import/parser.test.ts   17 passed${r}
   ${dim}└ import/upload.test.ts   11 passed${r}
   ${dim}└ import/errors.test.ts    9 passed${r}
   ${dim}└ api/recipes.test.ts     11 passed${r}

 ${cyan}●${r} Nothing left to fix
EOT
;;
ask) cat <<EOT

 ${cyan}●${r} Compared the two albums
   ${dim}└ 412 photos match${r}
   ${dim}└ ${r}${red}6 photos differ only in their date${r}

 ${yellow}●${r} ${bold}Six photos have two dates.${r}
   Which one wins?

   ${blue}1.${r} The date in the file
   ${blue}2.${r} The date of the upload
   ${blue}3.${r} Ask for each photo
EOT
;;
*) printf '\n %s●%s Map tiles cached. Nothing to do.\n' "$green" "$r" ;;
esac
exec sleep 3600
