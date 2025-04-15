# game_resolver_julia
標準型ゲームのNash均衡を求めるプログラム。game_resolver の julia版。

## How to install
* Julia を使える環境を準備して下さい
* 基本的に `game_resolver.jl` と `samaple_games.jl` をダウンロードして同じディレクトリに置けば準備完了です。

## サンプルゲームの実行
### 実行手順
サンプルとして、囚人のジレンマ、男女の争い、クールノー競争、タカハトゲーム、非協力ゲーム理論（教科書）の3.3(a)の演習問題のゲームが実行できるようになっています。Juliaの実行環境のREPL を立ち上げ（ターミナルでjuliaのコマンドを実行する）、以下を実行してください。

```julia
julia> include("sample_games.jl")
julia> prisoners_dilemma1()
```

実行すれば、以下のような結果が表示されます。
```julia
Getting Nash Equilibrium:
100.0%┣███████████████████████████████████████┫ 4/4 [00:00<00:00, 15it/s]
┌ Info: Nash Equilibrium:
│   nash =
│    1-element Vector{Union{Vector{Float64}, Vector{String}}}:
└     ["d", "d"]
```
上記は囚人のジレンマのナッシュ均衡（d,d）= (裏切り, 裏切り) が示されています。

### 各サンプルゲームの説明
以下のサンプルゲームが含まれています。関数として定義していますので、REPLで各関数を呼び出して実行して下さい。

* **prisoners_dilemma1()** 
囚人のジレンマ。標準的な形式（後述）で実行したもの。ただし、実行速度は遅い。

* **prisoners_dilemma2()** 
囚人のジレンマ。利得関数をマトリクス形式に変形してから（後述）実行したもの。こちらの方が実行速度が早い。

* **prisoners_dilemma3()** 
囚人のジレンマ。利得関数を定義せずに、いきなり2次元配列として、利得をマトリクス形式でいきなり定義してから実行。マトリクスの数字だけが与えられている点に注意。

* **battle_of_sex()** 
男女の争い。利得関数をマトリクス形式に変換してから実行したもの。

* **cournot_game1()** 
クールノー競争。選択肢は1から100まで0.1刻みで1000通り。マトリクス形式に変換してから実行したもの。

* **cournot_game2()** 
クールノー競争。選択肢は1から100まで0.1刻みで1000通り。マトリクス形式に変換せずに、標準的な形式で実行したもの。`cournot_game1()` の10倍以上の時間がかかる。

* **hawk_dove_game()** 
タカハトゲーム。利得表は以下の通り。マトリクスを直接定義して実行。

|         |Hawk |Dove | 
| ---     | :---: | :---: | 
|**Hawk** |-2, -2| 4, 0   | 
|**Dove** | 0, 4| 2, 2    | 

* **textbook_ex33a()** 
非協力ゲーム理論（グレーヴァ香子 著）の3章の演習問題3.3(a)のゲーム。利得表は以下の通り。マトリクスを直接定義して実行。

|         | L | R | 
| ---     | :---: | :---: | 
|**U** |-2, -2| 4, 0   | 
|**M** | 0, 4| 2, 2    | 
|**D** | 0, 4| 2, 2    | 


## 自分で独自のゲームを作る場合
自分でゲームを作成する場合、以下の3つの方法があります。
1. **通常ケース：** 
各プレイヤが持つ行動と利得関数を用いてゲームを定義し、`get_Nash_equilibirum(game)` を実行する。サンプルゲームの、`prisoners_dilemma1()` がこれに相当します。

2. **Matrix変換ケース：** 
1.に加えて、利得関数をマトリクス表現に変換してから、`get_Nash_equilibirum_idx(game)` を実行する。サンプルゲームの、`prisoners_dilemma2()` がこれに相当します。

3. **Matrix定義ケース：** 
行動と利得関数を定義せずに、直接、利得表としてMatrix形式で定義し、`get_Nash_equilibirum_idx(game)` を実行する。サンプルゲームの、`prisoners_dilemma3()` がこれに相当します。

以下、それぞれについて説明します。


### 1. 通常ケース
以下は、`prisoners_dilemma1()` の内容です。

```julia
function prisoners_dilemma1()

    # 利得関数を定義する。
    # ゲーム理論の定式化と同様に、f(s, s_{-i}) となるように定義する。
    # ただし、s は自分の戦略、s_{-i} は自分以外の戦略を表す。
    # f(s1, s2, s3, s4) のようにプレイヤの数だけ引数を増やせば良い。
    function f(s1::String, s2::String)::Float64
        if s1 == "c"
            if s2 == "c"
                return 3.0
            elseif s2 == "d"
                return 0.0
            end
        elseif s1 == "d"
            if s2 == "c"
                return 5.0
            elseif s2 == "d"
                return 1.0
            end
        end
    end

    # 各プレイヤが取りうる行動を定義する。
    # Stringのリストか、Float64のリストで定義する。
    actions = ["c", "d"]

    # プレイヤを作成する。引数の説明は以下の通り。
    # 第１引数：プレイヤの id を設定する。重複しないようにすること。
    # 第２引数：プレイヤの行動の選択肢
    # 第３引数：プレイヤの利得関数
    p1 = Player(1, actions, f)
    p2 = Player(2, actions, f)
    p_list = [p1, p2]
    
    # 上記で定義したプレイヤのリストを引数にゲームを作成する
    g = Game(p_list)

    println("Getting Nash Equilibrium:")
    
    # 1つの戦略プロファイルがStringのリスト、もしくは、Float64のリストで表されます。
    # nash は、ナッシュ均衡となる戦略プロファイルのリストとなる。
    nash = get_Nash_equilibrium(g)
    
    # Logging を使って結果を標準出力に表示します。
    @info "Nash Equilibrium:" nash
end
```

### 2. Matrix変換ケース
以下は、`prisoners_dilemma2()` の内容です。

```julia
function prisoners_dilemma2()    

    function f(s1, s2)::Float64
        if s1 == "c"
            if s2 == "c"
                return 3
            elseif s2 == "d"
                return 0
            end
        elseif s1 == "d"
            if s2 == "c"
                return 5
            elseif s2 == "d"
                return 1
            end
        end
    end

    actions = ["c", "d"]

    println("Transforming to Payoff Matrix:")
    
    # これにより、利得関数をFloat64の2次元配列に変換します
    payoff_matrix::Array{Float64} = transform_to_payoff_matrix(f, actions, actions)
    
    # SimplifiedPlayer を使い、プレイヤを作成する。引数は以下の通り。
    # 第１引数：プレイヤの id
    # 第２引数：上記の変換で得られたマトリクス
    p1 = SimplifiedPlayer(1, payoff_matrix)
    p2 = SimplifiedPlayer(2, payoff_matrix)
    player_list = [p1, p2]
    g = Game(player_list)

    println("Getting Nash Equilibrium:")
    
    # get_Nash_equilibrium_idx() を使う。
    # ナッシュ均衡は、マトリクスのインデックスの値として得られる。
    nash_idx = get_Nash_equilibrium_idx(g)
    
    # インデックス値に対応する戦略プロファイルを strategy_profile() により得る。
    nash = [strategy_profile(i, actions, actions) for i in nash_idx]
    @info "Nash Equilibrium:" nash_idx nash
end

```

### 3. Matrix定義ケース
以下は、`prisoners_dilemma3()` の内容です。

```julia
function prisoners_dilemma3()
    
    # マトリクス（2次元配列) として利得行列を定義する
    payoff_matrix = [3 0; 5 1]

    # 以下は、Matrix変換ケースと同じ
    # payoff_matrix の行列は、常に行プレイヤとして定義する。
    p1 = SimplifiedPlayer(1, payoff_matrix)
    p2 = SimplifiedPlayer(2, payoff_matrix)
    player_list = [p1, p2]
    g = Game(player_list)

    println("Getting Nash Equilibrium:")
    nash_idx = get_Nash_equilibrium_idx(g)
    nash = [strategy_profile(i, ["c", "d"], ["c", "d"]) for i in nash_idx]
    @info "Nash Equilibrium:" nash_idx nash
end
```

以上の1.〜3.のように、`Game()` を自分で定義し、`get_Nash_equilibrium()` か `get_Nash_equilibrium_idx()` により、ナッシュ均衡を得ることができる。


<!-- ## 各関数の説明 -->

# DAO_nash
