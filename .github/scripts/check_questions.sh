#!/bin/bash

readme_file="$README_PATH"/README.md
total_score=0

# Function to check and grade a single question
check_question() {
  local question_nbr="$1"
  local correct_answer_pattern="$2"
  local student_response="$3"
  local exit_on_fail="$4"

  # Extract question
  question_text=$(grep -i -E "\*\*Q$question_nbr\.\*\*.*\?$" "${readme_file}")

  # Pre-process student response to extract relevant lines
  student_q_response=$(grep -A 5 ".*$question_nbr" <<<"$student_response" | grep -i "\[X\]")

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

  # Count correctly checked answers using a more efficient method
  correct_count=$(grep -E -c "\[X\] \*\*\(($correct_answer_pattern)\)\*\*" <<<"$student_q_response")

  # Count all checked answers (including extras)
  checked_count=$(grep -c "\[X\]" <<<"$student_q_response")

  # Count all possible correct answers
  all_correct_count=$(echo "$correct_answer_pattern" | tr "|" "\n" | wc -l)
  # score_step=$((all_correct_count > 1 ? 1/all_correct_count : 1))
  # score_step=$(echo "scale=2; 1 / $all_correct_count" | bc)

  # Calculate score (1 for correct, -1 for extra)
  score=$((correct_count - (checked_count - correct_count)))
  score=$((score < 0 ? 0 : score))  # Ensure non-negative score
  
  if [[ $score -gt 1 && $score -eq $all_correct_count ]]; then
    score=1
  else
    if [[ $score -ne 1 ]]; then  # Only change score if it wasn't already 1
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

# Define questions and answers
# questions=(
#   "Quelles modifications sont apportées lorsque vous ajoutez une deuxième activité à votre application en choisissant"
#   "Que se passe-t-il si vous supprimez les éléments \`android:parentActivityName\` et \`<meta-data>\` de la deuxième déclaration d'activité du fichier \`AndroidManifest.xml\`\?"
# )

# answers=(
#   "La deuxième activité est ajoutée en tant que classe Java. Vous devez toujours ajouter le fichier de mise en page (layout) XML."
#   "Le deuxième fichier de mise en page (layout) XML d'activité est supprimé."
# )

IFS=$'\n'
readarray -t answers <.github/assets/answers.txt

nbQuestions=${#answers[@]}

# Read the student responses from the README.md file
student_responses=$(grep -i -E -A 5 "\*\*A[0-9]+\.\*\*.*\:$" "${readme_file}")

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

# echo "rdme-score=${total_score}\n" >> $GITHUB_OUTPUT
# echo "var_name: rdme-score"
# echo "rdme-questions=${nbQuestions}\n" >> $GITHUB_OUTPUT
# echo "var-name: rdme-questions"

exit 0