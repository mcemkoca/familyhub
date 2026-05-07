import json
import os

INPUT_DIR = "assets/data/content"
OUTPUT_DIR = "output/familyhub_content"
BATCH_SIZE = 10

categories = ["recipes", "travel", "indoor", "education", "family", "home"]

for cat in categories:
    input_file = os.path.join(INPUT_DIR, f"{cat}.json")
    if not os.path.exists(input_file):
        print(f"  ⚠️ {input_file} not found")
        continue
    
    with open(input_file, "r", encoding="utf-8") as f:
        items = json.load(f)
    
    print(f"📦 {cat}: {len(items)} items -> splitting into batches...")
    
    # Split into batches
    batch_count = 0
    for i in range(0, len(items), BATCH_SIZE):
        batch = items[i:i+BATCH_SIZE]
        batch_num = (i // BATCH_SIZE) + 1
        batch_file = os.path.join(OUTPUT_DIR, cat, f"batch_{batch_num}.json")
        with open(batch_file, "w", encoding="utf-8") as f:
            json.dump(batch, f, ensure_ascii=False, indent=2)
        batch_count += 1
    
    # Create combined final file
    final_file = os.path.join(OUTPUT_DIR, "final", f"all_{cat}.json")
    with open(final_file, "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, indent=2)
    
    print(f"  ✅ {batch_count} batches + final/all_{cat}.json created")

print("\n🎉 Batch splitting complete!")
