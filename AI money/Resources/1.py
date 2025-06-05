import json
import csv

# 1. JSON 파일 읽기
with open('questions_and_answers.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# 2. CSV 파일로 저장
with open('data.csv', 'w', newline='', encoding='utf-8') as f:
    writer = csv.DictWriter(f, fieldnames=["question", "answer"])
    writer.writeheader()
    writer.writerows(data)
