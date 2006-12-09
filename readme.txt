Titanion  readme.txt
for Windows98/2000/XP (OpenGL required)
ver. 0.3
(C) Kenta Cho

超高速突撃虫を殲滅せよ。
古き良き時代の固定画面シューティング、Titanion。


* 始め方

'ttn0_3.zip'を展開し、'ttn.exe'を実行してください。
ゲームをフルスクリーンで起動したい場合は、
'ttn_fullscreen.bat'を起動してください。

タイトル画面では、上下キーでゲームモード（CLASSIC, BASIC, MODERN）を
選択できます。ゲームを始めるにはショットボタンを押してください。

 + CLASSICモード
  - 敵弾は少なめです。
  - キャプチャービームを使って敵を味方にできます。
  - 敵機にふれると自機は破壊されます。

 + BASICモード
  - 中庸。
  - いつでもキャプチャービームを使えます。
  - 敵機にふれると自機ははじき飛ばされます。

 + MODERNモード
  - 弾幕。
  - 挑発ビームを使うと敵により多くの弾を撃たせることができ、
    より多くの敵弾倍率ボーナスを得ることができます。
  - 敵機にふれても何もおきません。互いにすり抜けます。


* 遊び方

敵弾をよけてすべての敵を破壊しましょう。

- 操作

o 移動
 方向キー / テンキー / [WASD] / [IJKL]  / スティック

o ショット
 [Z][L-Ctrl][R-Ctrl][.]         / ボタン 1, 3, 5, 7, 9, 11

  ショットは押しっぱなしで連射されます。

 + MODERNモード
  挑発ビームボタンを同時に押すことで、自機のスピードを落とし、
  集中砲火を行うことができます。

o キャプチャービーム / 挑発ビーム
 [X][L-Alt][R-Alt][L-Shift][R-Shift][/][Return] / ボタン 2, 4, 6, 8, 10, 12

 + CLASSICモード - キャプチャービーム
  キャプチャービームで敵を捕獲することができます。
  キャプチャービームエナジー（画面左に表示）がフルでないと
  キャプチャービームは発射できません。
  キャプチャービームエナジーは敵を破壊すると増加します。
  捕獲された敵は自機の横に並び、ほかの敵に反撃します。
  キャプチャービーム発射中の自機は無敵です。

 + BASICモード - キャプチャービーム
  キャプチャービームはいつでも使えますが、発射中も無敵にはなりません。

 + MODERNモード - 挑発ビーム
  挑発ビームを使うと敵により多くの弾を撃たせることができ、
  より多くの敵弾倍率ボーナスを得ることができます。
  挑発ビームを撃つにはショットボタンをはなす必要があります。

o ポーズ
 [P]

o ゲーム終了 / タイトルに戻る
 [ESC]

- 倍率

画面の右上に得点倍率が表示されます。倍率は敵を破壊すると増加し、
敵が画面内にいるときに少しずつ減少します。

- 近接倍率

 + BASICモード
  敵を近距離で破壊すると、近接倍率を得ることができます（最大16倍）。

- 敵弾倍率

 + MODERNモード
  中型機を破壊した場合、隣接する敵弾は連鎖的に敵弾倍率に変換されます。
  挑発ビームを中型機に当てて、より多くの敵弾倍率を獲得しましょう。

- エクステンド

 + CLASSICモード
  自機は100,000点ごとに増えます。

 + BASICモード
  自機は1,000,000点ごとに増えます。

 + MODERNモード
  次のエクステンド点は画面左上に表示されます。


* オプション

以下のコマンドラインオプションが利用可能です。

 -brightness n    画面の明るさを設定します (n = 0 - 100, default = 100)
 -res x y         画面サイズを(x, y)に設定します (default = 640, 480)
 -nosound         音を再生しません
 -bgmvol n        BGMの音量を設定します (n = 0 - 128, default = 100)
 -sevol n         SEの音量を設定します (n = 0 - 128, default = 100)
 -fullscreen      フルスクリーンモードで起動します
 -exchange        ショットボタンとビームボタンを入れ替えます
 -trail           敵に軌跡エフェクトを追加します
 -noslowdown      意図的な処理落ちを起こさないようにします
 -randomized      敵の攻撃パターンを毎回ランダムに変更します


* コメント

ご意見、ご感想は cs8k-cyu@asahi-net.or.jp までお願いします。


* ウェブページ

Titanion webpage:
http://www.asahi-net.or.jp/~cs8k-cyu/windows/ttn.html


* 謝辞

TitanionはD言語(ver. 0.173)で記述されています。
 プログラミング言語D
 http://www.kmonos.net/alang/d/

メディアハンドリングにSimple DirectMedia Layerを利用しています。
 Simple DirectMedia Layer
 http://www.libsdl.org

BGMとSEの再生にSDL_mixerとOgg Vorbis CODECを利用しています。
 SDL_mixer 1.2
 http://www.libsdl.org/projects/SDL_mixer/
 Vorbis.com
 http://www.vorbis.com

D - portingのOpenGL, SDL, SDL_mixer用ヘッダファイルを利用しています。
 D - porting
 http://shinh.skr.jp/d/porting.html

乱数生成にMersenne Twisterを利用しています。
 Mersenne Twister: A random number generator (since 1997/10)
 http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html


* ヒストリ

2006 12/ 9  ver. 0.3
            Ver.0.1 game mode came back as the BASIC mode with
             the proximity multiplier.
            Adjusted visual effects.
            A provacation beam becomes brighter when provacating
             a midsize enemy.
            Added '-bgmvol', '-sevol' and '-randomized' options.
            Adjusted the difficulty settings.
2006 11/26  ver. 0.2
            Added the CLASSIC and MODERN mode.
            Adjusted the difficulty settings.
2006 11/23  ver. 0.1
            First released version.


* ライセンス

修正BSDライセンスを適用します。

License
-------

Copyright 2006 Kenta Cho. All rights reserved. 

Redistribution and use in source and binary forms, 
with or without modification, are permitted provided that 
the following conditions are met: 

 1. Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer. 

 2. Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
