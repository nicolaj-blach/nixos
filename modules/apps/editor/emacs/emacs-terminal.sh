# Parse arguments
CMD=""
DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e)
      shift
      CMD="$*"
      break
      ;;
    --title)
      shift
      shift
      ;;
    --directory)
      shift
      DIR="$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -n "$DIR" ]]; then
  cd "$DIR" || exit 1
fi

if [[ -n "$CMD" ]]; then
  exec emacsclient -c -e "(progn (cd \"$PWD\") (ghostel \"$CMD\"))"
else
  exec emacsclient -c -e "(progn (cd \"$PWD\") (ghostel))"
fi
