https://github.com/catboost/catboost/releases/tag/v1.0.3

```bash
fit --learn-set train.tsv --test-set test.tsv --column-description train_description.txt --custom-loss="Precision,Recall" --logging-level Verbose --loss-function MultiClass --text-processing processing.json --has-header --task-type GPU

# Probability of each class
catboost calc -m model.bin --column-description test_description.txt -T 4 --output-columns "Class,BONE,Probability" --input-path test.tsv  --output-path output.tsv --has-header
```

Open in libreoffice calc and sort by class desc, uncertain #1, uncertain #2, bone name, vrm bone name

Todo: start probabilities from the root bone outwards