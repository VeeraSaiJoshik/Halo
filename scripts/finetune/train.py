"""
Halo LLM fine-tuning script.

Trains Qwen2.5-1.5B-Instruct on trading setup → verdict pairs using Unsloth
QLoRA. Run this in Google Colab with a free A100 runtime (~40 min for 300 examples).

Requirements (install at top of Colab notebook):
    pip install unsloth
    pip install --upgrade --no-cache-dir "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git"
    pip install trl datasets transformers

Input: scripts/finetune/data/training.jsonl
  Each line: {"messages": [{"role": "system", ...}, {"role": "user", ...}, {"role": "assistant", ...}]}

Output: halo-qwen-gguf/halo-qwen1.5b-ft-q4_k_m.gguf
  Upload this file to GitHub Releases as a model-v1 release asset, then
  update ModelDownloader.modelUrl in model_downloader.dart.
"""

import torch
from unsloth import FastLanguageModel
from trl import SFTTrainer
from transformers import TrainingArguments
from datasets import load_dataset

# ── Config ────────────────────────────────────────────────────────────────────

BASE_MODEL = "Qwen/Qwen2.5-1.5B-Instruct"
DATA_PATH = "data/training.jsonl"
OUTPUT_DIR = "halo-qwen-lora"
GGUF_DIR = "halo-qwen-gguf"
MAX_SEQ_LEN = 2048
LORA_RANK = 16
EPOCHS = 3
BATCH_SIZE = 4
GRAD_ACCUM = 4
LR = 2e-4

# ── Load base model ───────────────────────────────────────────────────────────

model, tokenizer = FastLanguageModel.from_pretrained(
    model_name=BASE_MODEL,
    max_seq_length=MAX_SEQ_LEN,
    dtype=None,
    load_in_4bit=True,
)

model = FastLanguageModel.get_peft_model(
    model,
    r=LORA_RANK,
    target_modules=[
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj",
    ],
    lora_alpha=LORA_RANK,
    lora_dropout=0,
    bias="none",
    use_gradient_checkpointing="unsloth",
    random_state=42,
)

# ── Load and format dataset ───────────────────────────────────────────────────

dataset = load_dataset("json", data_files=DATA_PATH, split="train")

def format_example(example):
    return {
        "text": tokenizer.apply_chat_template(
            example["messages"],
            tokenize=False,
            add_generation_prompt=False,
        )
    }

dataset = dataset.map(format_example, remove_columns=dataset.column_names)

print(f"Training on {len(dataset)} examples")
print("Sample prompt (first 500 chars):")
print(dataset[0]["text"][:500])

# ── Train ─────────────────────────────────────────────────────────────────────

trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=dataset,
    dataset_text_field="text",
    max_seq_length=MAX_SEQ_LEN,
    args=TrainingArguments(
        per_device_train_batch_size=BATCH_SIZE,
        gradient_accumulation_steps=GRAD_ACCUM,
        warmup_steps=10,
        num_train_epochs=EPOCHS,
        learning_rate=LR,
        fp16=not torch.cuda.is_bf16_supported(),
        bf16=torch.cuda.is_bf16_supported(),
        logging_steps=10,
        output_dir=OUTPUT_DIR,
        optim="adamw_8bit",
        save_strategy="no",
    ),
)

trainer_stats = trainer.train()
print(f"\nTraining complete. Time: {trainer_stats.metrics['train_runtime']:.1f}s")

# ── Export to GGUF ────────────────────────────────────────────────────────────

print("\nMerging LoRA and exporting to GGUF Q4_K_M...")
model.save_pretrained_gguf(GGUF_DIR, tokenizer, quantization_method="q4_k_m")

print(f"\nDone. GGUF saved to {GGUF_DIR}/")
print("Next steps:")
print("  1. Download the .gguf file from Colab")
print("  2. Create a GitHub Release tagged 'model-v1' on VeeraSaiJoshik/Halo")
print("  3. Upload the .gguf as a release asset")
print("  4. Update ModelDownloader.modelUrl in model_downloader.dart")
