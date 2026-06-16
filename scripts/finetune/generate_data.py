"""
Training data generator for Halo LLM fine-tuning.

Uses the Claude API to generate Verdict JSON responses for raw LlmRequest
inputs. Review and correct outputs before using for training.

Usage:
    export ANTHROPIC_API_KEY=sk-ant-...
    python generate_data.py --input raw_requests/ --output data/training.jsonl

Input directory: one .json file per LlmRequest (from detection engine exports)
Output: data/training.jsonl — each line ready for train.py

Start with the seed examples in sample_requests.jsonl, then add more raw
requests from the detection engine and run this to generate their verdicts.
"""

import anthropic
import json
import argparse
from pathlib import Path

SYSTEM_PROMPT = """You are a financial trading setup analyzer for the Halo app.
Analyze the provided market setup JSON and output a structured trading verdict.

CRITICAL: Output ONLY a valid JSON object. No explanation, no markdown, no code fences.
Your response must begin with { and end with }.

REQUIRED OUTPUT FIELDS:
- "direction": must exactly match input setup.direction
- "confidence": integer 1-10
- "entry": object with "type" ("limit"), "price" (float inside the zone), "zone" ([zoneLower, zoneUpper])
- "invalidation": float — above zoneUpper for bearish, below zoneLower for bullish
- "target": float — below currentPrice for bearish, above currentPrice for bullish
- "thesis": string — max 400 chars, plain prose, specific to this setup (no markdown)
- "keyRisks": array of 0-3 strings, each specific to this setup

CONFIDENCE CALIBRATION (start from floor(setup.score)):
- chopZone flag: -2
- sameBarSweep flag: -1
- fastFill flag: -1
- counterTrend flag: -1
- score >= 4.5 and no flags: +1
- Clamp final value to [1, 10]"""


def generate_verdict(client: anthropic.Anthropic, request_json: dict) -> dict:
    response = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=512,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": json.dumps(request_json)}],
    )
    text = response.content[0].text.strip()
    return json.loads(text)


def request_to_training_example(request_json: dict, verdict_json: dict) -> dict:
    return {
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": json.dumps(request_json)},
            {"role": "assistant", "content": json.dumps(verdict_json)},
        ]
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Dir of raw LlmRequest JSON files")
    parser.add_argument("--output", default="data/training.jsonl")
    parser.add_argument("--seed", default="sample_requests.jsonl",
                        help="Existing JSONL to prepend (already paired)")
    args = parser.parse_args()

    client = anthropic.Anthropic()
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)

    examples = []

    # Prepend hand-curated seed examples
    seed_path = Path(args.seed)
    if seed_path.exists():
        with open(seed_path) as f:
            for line in f:
                line = line.strip()
                if line:
                    examples.append(json.loads(line))
        print(f"Loaded {len(examples)} seed examples from {seed_path}")

    # Generate verdicts for raw request files
    input_dir = Path(args.input)
    request_files = sorted(input_dir.glob("*.json"))
    print(f"Generating verdicts for {len(request_files)} raw requests...")

    for i, path in enumerate(request_files):
        with open(path) as f:
            request = json.load(f)
        try:
            verdict = generate_verdict(client, request)
            examples.append(request_to_training_example(request, verdict))
            print(f"  [{i+1}/{len(request_files)}] {path.name} → confidence={verdict.get('confidence')}")
        except Exception as e:
            print(f"  [{i+1}/{len(request_files)}] SKIPPED {path.name}: {e}")

    with open(args.output, "w") as f:
        for ex in examples:
            f.write(json.dumps(ex) + "\n")

    print(f"\nWrote {len(examples)} training examples to {args.output}")
    print("Review the output before running train.py — correct any bad verdicts.")


if __name__ == "__main__":
    main()
