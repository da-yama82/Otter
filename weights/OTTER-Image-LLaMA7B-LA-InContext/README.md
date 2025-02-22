---
license: other
---

# Please Dont User this version for Evaluation, this is the deprecated version.

## 🦦 Simple Code For Otter-9B

Here is an example of multi-modal ICL (in-context learning) with 🦦 Otter. We provide two demo images with corresponding instructions and answers, then we ask the model to generate an answer given our instruct. You may change your instruction and see how the model responds.

Please first clone [Otter](https://github.com/Luodian/Otter) to your local disk. Place following script inside the Otter folder to make sure it has the access to otter/modeling_otter.py.

``` python
import mimetypes
import os
from io import BytesIO
from typing import Union
import cv2
import requests
import torch
import transformers
from PIL import Image
from torchvision.transforms import Compose, Resize, ToTensor
from tqdm import tqdm
import sys

from otter.modeling_otter import OtterForConditionalGeneration


# Disable warnings
requests.packages.urllib3.disable_warnings()

# ------------------- Utility Functions -------------------


def get_content_type(file_path):
    content_type, _ = mimetypes.guess_type(file_path)
    return content_type


# ------------------- Image and Video Handling Functions -------------------

def get_image(url: str) -> Union[Image.Image, list]:
    if "://" not in url:  # Local file
        content_type = get_content_type(url)
    else:  # Remote URL
        content_type = requests.head(url, stream=True, verify=False).headers.get("Content-Type")

    if "image" in content_type:
        if "://" not in url:  # Local file
            return Image.open(url)
        else:  # Remote URL
            return Image.open(requests.get(url, stream=True, verify=False).raw)
    else:
        raise ValueError("Invalid content type. Expected image or video.")


# ------------------- OTTER Prompt and Response Functions -------------------


def get_formatted_prompt(prompt: str, in_context_prompts: list = []) -> str:
    in_context_string = ""
    for in_context_prompt, in_context_answer in in_context_prompts:
        in_context_string += f"<image>User: {in_context_prompt} GPT:<answer> {in_context_answer}<|endofchunk|>"
    return f"{in_context_string}<image>User: {prompt} GPT:<answer>"


def get_response(image_list, prompt: str, model=None, image_processor=None, in_context_prompts: list = []) -> str:
    input_data = image_list

    if isinstance(input_data, Image.Image):
        vision_x = image_processor.preprocess([input_data], return_tensors="pt")["pixel_values"].unsqueeze(1).unsqueeze(0)
    elif isinstance(input_data, list):  # list of video frames
        vision_x = image_processor.preprocess(input_data, return_tensors="pt")["pixel_values"].unsqueeze(1).unsqueeze(0)
    else:
        raise ValueError("Invalid input data. Expected PIL Image or list of video frames.")

    lang_x = model.text_tokenizer(
        [
            get_formatted_prompt(prompt, in_context_prompts),
        ],
        return_tensors="pt",
    )
    bad_words_id = tokenizer(["User:", "GPT1:", "GFT:", "GPT:"], add_special_tokens=False).input_ids
    generated_text = model.generate(
        vision_x=vision_x.to(model.device),
        lang_x=lang_x["input_ids"].to(model.device),
        attention_mask=lang_x["attention_mask"].to(model.device),
        max_new_tokens=512,
        num_beams=3,
        no_repeat_ngram_size=3,
        bad_words_ids=bad_words_id,
    )
    parsed_output = (
        model.text_tokenizer.decode(generated_text[0])
        .split("<answer>")[-1]
        .lstrip()
        .rstrip()
        .split("<|endofchunk|>")[0]
        .lstrip()
        .rstrip()
        .lstrip('"')
        .rstrip('"')
    )
    return parsed_output


# ------------------- Main Function -------------------

if __name__ == "__main__":
    model = OtterForConditionalGeneration.from_pretrained("luodian/OTTER-9B-LA-InContext", device_map="auto")
    model.text_tokenizer.padding_side = "left"
    tokenizer = model.text_tokenizer
    image_processor = transformers.CLIPImageProcessor()
    model.eval()

    while True:
        urls = [
            "https://images.cocodataset.org/train2017/000000339543.jpg",
            "https://images.cocodataset.org/train2017/000000140285.jpg",
        ]

        encoded_frames_list = []
        for url in urls:
            frames = get_image(url)
            encoded_frames_list.append(frames)

        in_context_prompts = []
        in_context_examples = [
            "What does the image describe?::A family is taking picture in front of a snow mountain.",
        ]
        for in_context_input in in_context_examples:
            in_context_prompt, in_context_answer = in_context_input.split("::")
            in_context_prompts.append((in_context_prompt.strip(), in_context_answer.strip()))

        # prompts_input = input("Enter the prompts separated by commas (or type 'quit' to exit): ")
        prompts_input = "What does the image describe?"

        prompts = [prompt.strip() for prompt in prompts_input.split(",")]

        for prompt in prompts:
            print(f"\nPrompt: {prompt}")
            response = get_response(encoded_frames_list, prompt, model, image_processor, in_context_prompts)
            print(f"Response: {response}")

        if prompts_input.lower() == "quit":
            break
```