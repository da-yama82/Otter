#/bin/bash
export PYTHONPATH=.
function terminate() {
  exit
}
trap 'terminate' {1,2,3,15}
accelerate launch --config_file=./pipeline/accelerate_configs/accelerate_config_fsdp.yaml \
pipeline/train/instruction_following.py \
--pretrained_model_name_or_path="./weights/OTTER-Image-MPT7B" \
--mimicit_ic_path="/data/yyama_dataset/rename_ViEW_rearranged_20/train_instructions.json" \
--images_ic_path="/data/yyama_dataset/rename_ViEW_rearranged_20/train_images.json" \
--train_config_ic_path="/data/yyama_dataset/rename_ViEW_rearranged_20/train_pairs25_train.json" \
--external_save_dir="./log" \
--batch_size=32 \
--gradient_accumulation_steps=4 \
--logging_steps=300 \
--num_epochs=26 \
--run_name=rename_view_20/new_20_rand \
--wandb_entity=ia-gu \
--wandb_project=new_20_rand_20 \
--workers=1 \
--lr_scheduler=cosine \
--learning_rate=1e-5 \
--warmup_steps_ratio=0.01 \
--report_to_wandb \

#/bin/bash
export PYTHONPATH=.
function terminate() {
  exit
}
trap 'terminate' {1,2,3,15}
accelerate launch --config_file=./pipeline/accelerate_configs/accelerate_config_fsdp.yaml \
pipeline/train/instruction_following.py \
--pretrained_model_name_or_path="./weights/OTTER-Image-MPT7B" \
--mimicit_ic_path="/data/yyama_dataset/rename_ViEW_rearranged_20/train_instructions_json_based.json" \
--images_ic_path="/data/yyama_dataset/rename_ViEW_rearranged_20/train_images_json_based.json" \
--train_config_ic_path="/data/yyama_dataset/rename_ViEW_rearranged_20/train_pairs25_train_json_based.json" \
--external_save_dir="./log" \
--batch_size=32 \
--gradient_accumulation_steps=4 \
--logging_steps=300 \
--num_epochs=26 \
--run_name=rename_view_20/json_based_20_rand \
--wandb_entity=ia-gu \
--wandb_project=json_based_20_rand_20 \
--workers=1 \
--lr_scheduler=cosine \
--learning_rate=1e-5 \
--warmup_steps_ratio=0.01 \
--report_to_wandb \
