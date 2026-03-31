#!/bin/bash
# ============================================================
# J-pop英語化・AIボーカル生成プロジェクト
# M4 Mac Mini 初期環境構築スクリプト
# ============================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo "============================================"
echo "  J-pop AI Vocal Project - Setup Script"
echo "  M4 Mac Mini 最適化版"
echo "============================================"
echo ""

# ----------------------------------------------------------
# 1. Homebrew チェック
# ----------------------------------------------------------
echo "▶ Step 1: Homebrew の確認"
if ! command -v brew &>/dev/null; then
  warn "Homebrew が見つかりません。インストールします..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon のパス設定
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  log "Homebrew はインストール済みです"
fi

# ----------------------------------------------------------
# 2. 基本ツール（ffmpeg, git）
# ----------------------------------------------------------
echo ""
echo "▶ Step 2: 基本ツールのインストール"

if ! command -v ffmpeg &>/dev/null; then
  brew install ffmpeg
  log "ffmpeg をインストールしました"
else
  log "ffmpeg はインストール済みです"
fi

if ! command -v git &>/dev/null; then
  brew install git
  log "git をインストールしました"
else
  log "git はインストール済みです"
fi

# ----------------------------------------------------------
# 3. Python 3.10（pyenv 経由）
# ----------------------------------------------------------
echo ""
echo "▶ Step 3: Python 3.10 のセットアップ（RVC推奨バージョン）"

if ! command -v pyenv &>/dev/null; then
  brew install pyenv
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zprofile
  echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zprofile
  echo 'eval "$(pyenv init -)"' >> ~/.zprofile
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  log "pyenv をインストールしました"
else
  log "pyenv はインストール済みです"
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

# Python 3.10 インストール
PYTHON_VERSION="3.10.14"
if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
  warn "Python $PYTHON_VERSION をインストール中（数分かかります）..."
  pyenv install "$PYTHON_VERSION"
  log "Python $PYTHON_VERSION をインストールしました"
else
  log "Python $PYTHON_VERSION はインストール済みです"
fi

# ----------------------------------------------------------
# 4. audio-separator（ボーカル分離ツール）
# ----------------------------------------------------------
echo ""
echo "▶ Step 4: audio-separator のインストール（ボーカル分離）"

# Python 3.10 で venv を作成
SEPARATOR_VENV="$HOME/.venvs/audio-separator"
if [ ! -d "$SEPARATOR_VENV" ]; then
  pyenv local "$PYTHON_VERSION" 2>/dev/null || true
  python3 -m venv "$SEPARATOR_VENV"
  log "audio-separator 用の仮想環境を作成しました: $SEPARATOR_VENV"
fi

source "$SEPARATOR_VENV/bin/activate"
pip install --upgrade pip -q
pip install audio-separator[cpu] -q
deactivate

log "audio-separator をインストールしました"
echo "  使い方: source $SEPARATOR_VENV/bin/activate && audio-separator <音声ファイル>"

# ----------------------------------------------------------
# 5. Applio（RVC フォーク / WebUI付きボイスコンバーター）
# ----------------------------------------------------------
echo ""
echo "▶ Step 5: Applio のセットアップ（RVCベース ボイスコンバーター）"

APPLIO_DIR="$HOME/Applio"
if [ ! -d "$APPLIO_DIR" ]; then
  warn "Applio をクローン中..."
  git clone https://github.com/IAHispano/Applio "$APPLIO_DIR"
  log "Applio をクローンしました: $APPLIO_DIR"
else
  log "Applio はすでに存在します: $APPLIO_DIR"
  cd "$APPLIO_DIR" && git pull --quiet && cd - > /dev/null
  log "Applio を最新版に更新しました"
fi

# Applio の Python 依存関係インストール
cd "$APPLIO_DIR"
APPLIO_VENV="$HOME/.venvs/applio"
if [ ! -d "$APPLIO_VENV" ]; then
  python3 -m venv "$APPLIO_VENV"
  log "Applio 用の仮想環境を作成しました"
fi
source "$APPLIO_VENV/bin/activate"
pip install --upgrade pip -q

# ---- torch は requirements.txt のバージョンピンを無視して個別インストール ----
# Applio の requirements.txt が存在しないバージョン（例: torch==2.7.1）を
# 指定している場合があるため、torch 系は先に Apple Silicon 対応の最新版を入れる
warn "torch (Apple Silicon / MPS対応) をインストール中..."
pip install torch torchaudio --quiet \
  || warn "torch のインストールに問題がありました。続行します..."

# requirements.txt から torch 系の行を除外してインストール
if [ -f "requirements.txt" ]; then
  warn "Applio の依存ライブラリをインストール中（torch 行はスキップ）..."
  grep -v -E "^torch(vision|audio)?(==|>=|<=|~=|!=|>|<| )" requirements.txt \
    > /tmp/applio_reqs_filtered.txt || true
  pip install -r /tmp/applio_reqs_filtered.txt --quiet \
    || warn "一部パッケージのインストールに警告が出ましたが続行します"
  rm -f /tmp/applio_reqs_filtered.txt
  log "Applio の依存関係をインストールしました"
fi
deactivate
cd - > /dev/null

# ----------------------------------------------------------
# 6. Audacity（GUIミックスツール）
# ----------------------------------------------------------
echo ""
echo "▶ Step 6: Audacity の確認"
if [ -d "/Applications/Audacity.app" ]; then
  log "Audacity はインストール済みです"
else
  warn "Audacity が見つかりません。Homebrew でインストールします..."
  brew install --cask audacity
  log "Audacity をインストールしました"
fi

# ----------------------------------------------------------
# 7. ショートカットコマンドの設定
# ----------------------------------------------------------
echo ""
echo "▶ Step 7: 便利コマンドの設定"

SHELL_RC="$HOME/.zshrc"
if ! grep -q "# J-pop AI Vocal Project" "$SHELL_RC" 2>/dev/null; then
  cat >> "$SHELL_RC" << 'EOF'

# J-pop AI Vocal Project - Shortcuts
alias separate-vocals='source $HOME/.venvs/audio-separator/bin/activate && echo "音声分離モード: audio-separator <ファイル名> でボーカル分離"'
alias start-applio='source $HOME/.venvs/applio/bin/activate && cd $HOME/Applio && python app.py'
alias jp-music='cd ~/English_music'
EOF
  log "ショートカットを ~/.zshrc に追加しました"
  log "  separate-vocals : 音声分離モードを起動"
  log "  start-applio    : Applio WebUI を起動"
  log "  jp-music        : プロジェクトフォルダへ移動"
fi

# ----------------------------------------------------------
# 完了メッセージ
# ----------------------------------------------------------
echo ""
echo "============================================"
echo "  ✅ セットアップ完了！"
echo "============================================"
echo ""
echo "【次のステップ】"
echo "  1. ターミナルを再起動（または: source ~/.zshrc）"
echo "  2. 最初の1曲の原曲ファイルを songs/originals/ に置く"
echo "  3. ボーカル分離: separate-vocals してから"
echo "       audio-separator songs/originals/曲名.mp3 \\"
echo "         --model_filename MDX23C-8KFFT-InstVoc_HQ.onnx \\"
echo "         --output_dir songs/instrumentals/"
echo "  4. 自分の声録音データを voice_model/recordings/ に置く"
echo "  5. Applio 起動: start-applio（ブラウザでWebUIが開く）"
echo "  6. Applio で声モデルを学習 → ガイドボーカルを変換"
echo ""
echo "  詳細はワークフロー手順書.md を参照してください"
echo ""
