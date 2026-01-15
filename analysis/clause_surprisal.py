#!/usr/bin/env python3
"""
Compute average surprisal for clause texts.
Input: JSONL with {"clause_id":..., "text":...}
Output: JSONL with {"clause_id":..., "surprisal":..., "n_tokens":...}
"""
import argparse
import json
import math
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

def get_device():
    if torch.backends.mps.is_available():
        return "mps"
    if torch.cuda.is_available():
        return "cuda"
    return "cpu"


def avg_nll_for_text(text, tokenizer, model, max_length=128, stride=64, device="cpu"):
    enc = tokenizer(text, return_tensors="pt")
    input_ids = enc.input_ids.to(device)
    seq_len = input_ids.size(1)

    if seq_len < 2:
        return None, int(seq_len)

    nlls = []
    total_tokens = 0

    for i in range(0, seq_len, stride):
        begin = max(i + stride - max_length, 0)
        end = min(i + stride, seq_len)
        trg_len = end - i

        input_ids_slice = input_ids[:, begin:end]
        target_ids = input_ids_slice.clone()
        target_ids[:, :-trg_len] = -100

        with torch.no_grad():
            outputs = model(input_ids_slice, labels=target_ids)
            loss = outputs.loss
            if not torch.isfinite(loss):
                continue
            neg_log_likelihood = loss * trg_len

        nlls.append(neg_log_likelihood)
        total_tokens += trg_len

    if total_tokens == 0 or len(nlls) == 0:
        return None, int(seq_len)

    avg_nll = torch.stack(nlls).sum() / total_tokens
    value = float(avg_nll.item())
    if math.isnan(value) or math.isinf(value):
        return None, int(seq_len)
    return value, int(seq_len)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="JSONL with clause_id + text")
    parser.add_argument("--output", required=True, help="JSONL output")
    parser.add_argument("--model", required=True, help="HF model id")
    parser.add_argument("--max-tokens", type=int, default=128)
    parser.add_argument("--stride", type=int, default=64)
    args = parser.parse_args()

    device = get_device()
    tokenizer = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForCausalLM.from_pretrained(args.model)
    model.to(device)
    model.eval()

    with open(args.input, "r", encoding="utf-8") as fin, open(args.output, "w", encoding="utf-8") as fout:
        for line in fin:
            row = json.loads(line)
            clause_id = row.get("clause_id")
            text = row.get("text", "")
            surprisal, n_tokens = avg_nll_for_text(
                text, tokenizer, model,
                max_length=args.max_tokens,
                stride=args.stride,
                device=device
            )
            out = {
                "clause_id": clause_id,
                "surprisal": surprisal,
                "n_tokens": n_tokens,
                "model": args.model
            }
            fout.write(json.dumps(out) + "\n")

if __name__ == "__main__":
    main()
