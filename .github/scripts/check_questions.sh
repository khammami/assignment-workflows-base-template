#!/bin/bash

readme_file="${README_PATH}/README.md"
total_score=0

# Function to check and grade a single question
check_question() {
  local question_nbr="$1"
  local correct_answer_pattern="$2"
  local _unused="$3"
  local exit_on_fail="$4"

  # Normalize the correct answer pattern (remove spaces) to support formats like "a|c"
  local pattern_clean="${correct_answer_pattern//[[:space:]]/}"

  # Extract question text (do not force a trailing '?')
  question_text=$(grep -i -E "\*\*Q${question_nbr}\.\*\*.*$" "${readme_file}")

  # Extract only the block of answers for the requested A{question_nbr}
  # Capture lines after the **A{n}.** header up to (but not including) the next **A{m}.** header.
  student_q_block=$(awk -v q="$question_nbr" '
    BEGIN { IGNORECASE=1; inblk=0; }
    {
      curr = "\\*\\*A" q "\\.\\*\\*.*:";
      anyA = "\\*\\*A[0-9]+\\.\\*\\*.*:";
      if ($0 ~ curr) { inblk=1; next }
      if (inblk && $0 ~ anyA) { inblk=0 }
      if (inblk) { print }
    }
  ' "$readme_file")

  # Keep only checked answers within that block (accept [x] or [X])
  student_q_response=$(grep -E "\[[xX]\]" <<<"$student_q_block")

  # Init exit_on_fail to false
  if [[ -z "$exit_on_fail" ]]; then
    exit_on_fail=false
  fi

  # Check for empty response
  if [[ -z "$student_q_response" ]]; then
    echo "Question $question_nbr: Aucune réponse"
    score=0
    if [[ "$exit_on_fail" = true ]]; then
      exit 1
    else
      return
    fi
  fi

  # Count correctly checked answers (accept [x] or [X]) using the cleaned pattern (e.g., a|c)
  # Matches lines like: * [x] **(a)** ...
  correct_count=$(grep -E -i -c "^\s*\*\s*\[[xX]\]\s+\*\*\(($pattern_clean)\)\*\*" <<<"$student_q_response")

  # Count all checked answers (including extras) within the block
  checked_count=$(grep -E -c "\[[xX]\]" <<<"$student_q_response")

  # Count all possible correct answers (split on | after removing spaces)
  all_correct_count=$(echo "$pattern_clean" | tr "|" "\n" | wc -l | tr -d ' ')

  # Calculate score (1 for correct, -1 for extra); clamp to [0, 1]
  score=$((correct_count - (checked_count - correct_count)))
  score=$((score < 0 ? 0 : score))

  if [[ $score -gt 1 && $score -eq $all_correct_count ]]; then
    score=1
  else
    if [[ $score -ne 1 ]]; then
      score=0
    fi
  fi

  echo "###########################"
  echo -e "Question: $question_nbr \n$question_text"
  echo -e "\nStudent response(s):\n$student_q_response"
  echo -e "\nScore: $score"
  echo "###########################"

  if [[ "$exit_on_fail" = true ]] && [[ "$score" -eq 0 ]]; then
    exit 1
  fi

  total_score=$((total_score + score))
}

IFS=$'\n'
readarray -t answers < .github/assets/answers.txt

# Remove any empty lines from answers (robust to accidental blank lines)
answers=("${answers[@]/#/}")                      # no-op to ensure array exists
tmp_answers=()
for a in "${answers[@]}"; do
  a_trimmed="${a#"${a%%[![:space:]]*}"}"          # ltrim
  a_trimmed="${a_trimmed%"${a_trimmed##*[![:space:]]}"}"  # rtrim
  if [[ -n "$a_trimmed" ]]; then
    tmp_answers+=("$a_trimmed")
  fi
done
answers=("${tmp_answers[@]}")

nbQuestions=${#answers[@]}

# We extract per-question directly from the README, so we don't need pre-collected responses
student_responses=""

if [ $# -eq 0 ]; then
  # Loop through each question and grade
  for i in "${!answers[@]}"; do
    qnbr=$((i + 1))
    check_question "${qnbr}" "${answers[$i]}" "$student_responses"
  done

  echo "==========================="
  echo "Total Score.........: $total_score"
  echo "Total Questions.....: ${nbQuestions}"
  echo "==========================="

  exit 0
elif [ $# -gt 2 ]; then
  echo "$0: Too many arguments: $*"
  exit 1
else
  if [ "$1" -eq 0 ]; then
    echo "Question number should start from 1"
    exit 1
  fi

  check_question "$1" "${answers[$(( $1 - 1 ))]}" "$student_responses" true
fi

exit 0