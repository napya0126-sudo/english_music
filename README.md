# J-pop AI English Vocal Project

J-popの楽曲を英語化し、自分の声を学習させたAIボーカルで歌わせた音源を作るプロジェクトです。
完成音源はAndroidスマートフォンへ転送して個人鑑賞用に使用します。

> **著作権について**：作成した音源は自身の端末内でのみ保管・再生し、公開・配布は一切行いません。

---

## ツールチェーン

| 用途 | ツール |
|------|--------|
| ボーカル分離（伴奏抽出） | [audio-separator](https://github.com/nomadkaraoke/python-audio-separator) |
| 声モデル学習・音声変換 | [Applio (RVC)](https://github.com/IAHispano/Applio) |
| ミックス・マスタリング | [Audacity](https://www.audacityteam.org/) |
| 英語歌詞作成 | Claude AI（意訳・音節調整） |

**動作環境**：M4 Mac Mini / macOS / Python 3.10

---

## セットアップ

```bash
git clone https://github.com/napya0126-sudo/english_music.git
cd english_music
bash setup.sh
```

初回実行で以下が自動インストールされます：
- ffmpeg
- Python 3.10（pyenv 経由）
- audio-separator（専用 venv）
- Applio + torch MPS対応版（専用 venv）
- Audacity（未インストール時のみ）

---

## フォルダ構成

```
english_music/
├── songs/
│   ├── originals/          # 購入済み原曲ファイル
│   ├── instrumentals/      # 分離した伴奏トラック
│   ├── vocals_original/    # 分離した原曲ボーカル（参考用）
│   └── output/             # 完成音源（Android転送用）
├── lyrics/
│   ├── japanese/           # 原曲日本語歌詞
│   └── english/            # 英語化した歌詞（音節調整済み）
├── guide_vocals/           # ガイドボーカル音源（変換前）
├── voice_model/
│   ├── recordings/         # 自分の声録音データ
│   └── models/             # 学習済みRVCモデル（.pth / .index）
├── setup.sh                # 環境構築スクリプト
└── ワークフロー手順書.md    # 各ステップの詳細手順
```

---

## 作業の流れ

```
原曲 → ボーカル分離 → 英語歌詞作成 → 声モデル学習
                                          ↓
                     ガイドボーカル → RVC変換 → Audacityでミックス → Android転送
```

詳細は **[ワークフロー手順書.md](./ワークフロー手順書.md)** を参照してください。

---

## よく使うコマンド

```bash
# ターミナルを再起動 or source ~/.zshrc 後に使用可能

separate-vocals   # audio-separator を起動
start-applio      # Applio WebUI を起動（http://localhost:7860）
jp-music          # このプロジェクトフォルダへ移動
```

---

## ターゲット楽曲

Super Beaver / 04 Limited Sazabys / BUMP OF CHICKEN など
