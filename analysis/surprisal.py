#!/usr/bin/env python3
"""
Compute corpus-level perplexity for a causal LM.
"""
import argparse
import json
import math
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

def compute_ppl(texts, model_id, max_length=128, stride=64):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    model = AutoModelForCausalLM.from_pretrained(model_id)
    model.to(device)
    model.eval()

    nlls = []
    total_tokens = 0

    for text in texts:
        enc = tokenizer(text, return_tensors="pt")
        input_ids = enc.input_ids.to(device)
        seq_len = input_ids.size(1)

        for i in range(0, seq_len, stride):
            begin = max(i + stride - max_length, 0)
            end = min(i + stride, seq_len)
            trg_len = end - i  # tokens to predict

            input_ids_slice = input_ids[:, begin:end]
            target_ids = input_ids_slice.clone()
            target_ids[:, :-trg_len] = -100

            with torch.no_grad():
                outputs = model(input_ids_slice, labels=target_ids)
                neg_log_likelihood = outputs.loss * trg_len

            nlls.append(neg_log_likelihood)
            total_tokens += trg_len

    ppl = torch.exp(torch.stack(nlls).sum() / total_tokens)
    return float(ppl.item())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Text file: one document per line")
    parser.add_argument("--model", required=True, help="HF model id")
    parser.add_argument("--max-tokens", type=int, default=128)
    parser.add_argument("--stride", type=int, default=64)
    parser.add_argument("--out", required=True, help="Output JSON path")
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        texts = [line.strip() for line in f if line.strip()]

    ppl = compute_ppl(texts, args.model, max_length=args.max_tokens, stride=args.stride)

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({"model": args.model, "perplexity": ppl}, f, indent=2)

    print(json.dumps({"model": args.model, "perplexity": ppl}))


if __name__ == "__main__":
    main()
