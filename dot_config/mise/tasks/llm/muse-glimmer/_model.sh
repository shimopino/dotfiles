# Muse Glimmer 30B のモデル定義(download / serve から source される)
# 実行権限を付けないこと: mise は実行可能ファイルだけを File Task として検出する
readonly HF_REPOSITORY="meta-models/Muse-Glimmer-30B-GGUF"
readonly MODEL_DIR="$LLAMA_MODELS_DIR/$HF_REPOSITORY"
readonly MAIN_MODEL="$MODEL_DIR/muse-glimmer-30B-kquant-17gb.gguf"
readonly DRAFT_MODEL="$MODEL_DIR/dflash-kquant.gguf"
