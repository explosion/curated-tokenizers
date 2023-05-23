# 🥢 Curated Tokenizers

This Python library provides word-/sentencepiece tokenizers. The following
types of tokenizers are currenty supported:

| Tokenizer | Binding       | Example model |
| --------- | ------------- | ------------- |
| BPE       | sentencepiece |               |
| Byte BPE  | Native        | RoBERTa/GPT-2 |
| Unigram   | sentencepiece | XLM-RoBERTa   |
| Wordpiece | Native        | BERT          |

## ⚠️ Warning: experimental package

This package is experimental and it is likely that the APIs will change in
incompatible ways.

## ⏳ Install

Curated tokenizers is availble through PyPI:

```bash
pip install curated_tokenizers
```

## 🚀 Quickstart

The best way to get started with curated tokenizers is through the
[`curated-transformers`](https://github.com/explosion/curated-transformers)
library. `curated-transformers` also provides functionality to load tokenization
models from Huggingface Hub.
