#!/usr/bin/env bash

# Faster, single-pass per-question extraction (no multiple greps),
# accepts [x] or [X], and supports multi-answer keys like "a|c".

set -u

readme_file="${README_PATH:-.}/README.md"
total_score=0

# Function to check and grade a single question
check_question() {
  local question_nbr="$1"
  local correct_answer_pattern="$2"
  local _unused="${3-}"
  local exit_on_fail="${4-}"

  # Normalize the correct answer pattern (remove spaces) to support formats like "a|c"
  local pattern_clean="${correct_answer_pattern//[[:space:]]/}"

  # Compute number of correct answers without spawning processes:
  # count of '|' + 1
  local pipes_only="${pattern_clean//[^|]/}"
  local all_correct_count=$(( ${#pipes_only} + 1 ))

  # Single awk pass to:
  # - capture the question line (**Qn.** ...)
  # - capture only the checked options within the corresponding **An.** block
  # - count checked and correct checked answers
  # Output layout:
  #   [0..N] lines: the checked response lines
  #   last-1 line: "##QUESTION <question_line>"
  #   last   line: "##COUNTS <checked_count> <correct_count>"
  local awk_out
  awk_out="$(awk -v q="$question_nbr" -v pat="$pattern_clean" '
    BEGIN {
      IGNORECASE = 1;
      inblk = 0;
      checked = 0;
      correct = 0;
      question = "";
      qre = "\\*\\*Q" q "\\.\\*\\*.*$";
      are = "\\*\\*A" q "\\.\\*\\*.*:";
      anyA = "\\*\\*A[0-9]+\\.\\*\\*.*:";
    }
    {
      if (question == "" && $0 ~ qre) { question = $0 }
      if ($0 ~ are) { inblk = 1; next }
      if (inblk && $0 ~ anyA) { inblk = 0 }
      if (inblk) {
        if ($0 ~ /\[[xX]\]/) {
          print $0;
          checked++;
          if ($0 ~ ("\\*\\*\\((" pat ")\\)\\*\\*")) { correct++ }
        }
      }
    }
    END {
      # Always output markers so the caller can parse reliably
      print "##QUESTION " question;
      printf("##COUNTS %d %d\n", checked, correct);
    }
  ' "$readme_file")"

  # Parse awk output without external processes
  # Grab the last line (counts)
  local counts_line="${awk_out##*$'\n'}"
  # Remove last line
  local tmp="${awk_out%$'\n'*}"
  # Grab the second-to-last line (question marker)
  local question_line="${tmp##*$'\n'}"
  # Everything before that is the student response lines
  local student_q_response="${tmp%$'\n'*}"

  # Extract values
  local question_text="${question_line#\#\#QUESTION }"
  local _tag checked_count correct_count
  read -r _tag checked_count correct_count <<<"$counts_line"

  # Normalize when there were no checked response lines
  if [[ "$student_q_response" == "$tmp" ]]; then
    # There was no newline before markers, meaning no responses present
    student_q_response=""
  fi

  # Handle empty response
  local score=0
  if [[ -z "${student_q_response//[[:space:]]/}" || "$checked_count" -eq 0 ]]; then
    printf "Question %d: Aucune réponse\n" "$question_nbr"
    if [[ "${exit_on_fail:-false}" == true ]]; then
      exit 1
    else
      return
    fi
  fi

  # Scoring:
  # 1 point only if the set of checked answers exactly matches the set of correct answers.
  # Otherwise 0.
  if [[ "$checked_count" -eq "$all_correct_count" && "$correct_count" -eq "$all_correct_count" ]]; then
    score=1
  else
    score=0
  fi

  printf "###########################\n"
  printf "Question: %d \n%s\n" "$question_nbr" "$question_text"
  printf "\nStudent response(s):\n%s\n" "$student_q_response"
  printf "\nScore: %d\n" "$score"
  printf "###########################\n"

  if [[ "${exit_on_fail:-false}" == true && "$score" -eq 0 ]]; then
    exit 1
  fi

  total_score=$((total_score + score))
}

# Load answers (one question per line; multiple correct letters separated by '|')
IFS=$'\n' read -r -d '' -a answers < <(
  # Use printf to ensure a trailing NUL for -d ''
  # Trim whitespace-only lines and ignore blanks with pure bash after read
  cat .github/assets/answers.txt; printf '\0'
)

# Trim and drop empty lines (pure bash)
trimmed_answers=()
for a in "${answers[@]}"; do
  # ltrim
  a="${a#"${a%%[![:space:]]*}"}"
  # rtrim
  a="${a%"${a##*[![:space:]]}"}"
  [[ -n "$a" ]] && trimmed_answers+=("$a")
done
answers=("${trimmed_answers[@]}")

nbQuestions=${#answers[@]}

if [[ $# -eq 0 ]]; then
  # Grade all questions
  for i in "${!answers[@]}"; do
    qnbr=$((i + 1))
    check_question "$qnbr" "${answers[$i]}" ""
  done

  printf "===========================\n"
  printf "Total Score.........: %d\n" "$total_score"
  printf "Total Questions.....: %d\n" "$nbQuestions"
  printf "===========================\n"

  exit 0
elif [[ $# -gt 2 ]]; then
  echo "$0: Too many arguments: $*"
  exit 1
else
  if [[ "$1" -eq 0 ]]; then
    echo "Question number should start from 1"
    exit 1
  fi
  check_question "$1" "${answers[$(( $1 - 1 ))]}" "" true
fi

exit 0