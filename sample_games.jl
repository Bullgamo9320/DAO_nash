include("game_resolver.jl")
using .GameResolver
import Logging

#################################################
### Prisoner's dilemma (normal ver.)
#################################################
"""
囚人のジレンマ。
ノーマルなタイプ。利得関数を使ってそのまま計算する。Matrixへ変換した方が計算は早い。
"""
function prisoners_dilemma1()

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

    actions = ["c", "d"]

    p1 = Player(1, actions, f)
    p2 = Player(2, actions, f)
    p_list = [p1, p2]
    g = Game(p_list)

    println("Getting Nash Equilibrium:")
    nash = get_Nash_equilibrium(g)
    @info "Nash Equilibrium:" nash
end

#################################################
### Prisoner's dilemma (transform ver.)
#################################################
"""
囚人のジレンマ。
利得関数からMatrixへ変換するタイプ。
"""
function prisoners_dilemma2()
    actions = ["c", "d"]

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

    println("Transforming to Payoff Matrix:")
    payoff_matrix::Array{Float64} = transform_to_payoff_matrix(f, actions, actions)
    p1 = SimplifiedPlayer(1, payoff_matrix)
    p2 = SimplifiedPlayer(2, payoff_matrix)
    player_list = [p1, p2]
    g = Game(player_list)

    println("Getting Nash Equilibrium:")
    nash_idx = get_Nash_equilibrium_idx(g)
    nash = [strategy_profile(i, actions, actions) for i in nash_idx]
    @info "Nash Equilibrium:" nash_idx nash
end


#################################################
### Prisoner's dilemma (Matrix ver.)
#################################################
"""
囚人のジレンマ。
Payoff Matrixを直接定義して実行するタイプ。
"""
function prisoners_dilemma3()
    payoff_matrix = [3 0; 5 1]
    p1 = SimplifiedPlayer(1, payoff_matrix)
    p2 = SimplifiedPlayer(2, payoff_matrix)
    player_list = [p1, p2]
    g = Game(player_list)

    println("Getting Nash Equilibrium:")
    nash_idx = get_Nash_equilibrium_idx(g)
    nash = [strategy_profile(i, ["c", "d"], ["c", "d"]) for i in nash_idx]
    @info "Nash Equilibrium:" nash_idx nash
end


#################################################
### Battle of sex
#################################################
"""
男女の争い。
Matrixへ変換するタイプ。
"""
function battle_of_sex()

    actions = ["boxing", "ballet"]

    function f_male(s1, s2)
        if s1 == "boxing"
            if s2 == "boxing"
                return 2
            elseif s2 == "ballet"
                return 0
            end
        elseif s1 == "ballet"
            if s2 == "boxing"
                return 0
            elseif s2 == "ballet"
                return 1
            end
        end
    end

    function f_female(s1, s2)
        if s1 == "boxing"
            if s2 == "boxing"
                return 1
            elseif s2 == "ballet"
                return 0
            end
        elseif s1 == "ballet"
            if s2 == "boxing"
                return 0
            elseif s2 == "ballet"
                return 2
            end
        end
    end

    println("Transforming to Payoff Matrix:")
    male_payoff_matrix = transform_to_payoff_matrix(f_male, actions, actions)
    female_payoff_matrix = transform_to_payoff_matrix(f_female, actions, actions)
    p1 = SimplifiedPlayer(1, male_payoff_matrix)
    p2 = SimplifiedPlayer(2, female_payoff_matrix)
    g = Game([p1, p2])

    println("Getting Nash Equilibrium:")
    nash_idx = get_Nash_equilibrium_idx(g)
    nash = [strategy_profile(i, actions, actions) for i in nash_idx]
    @info "Nash Equilibrium:" nash_idx nash
end


#################################################
### Cournot game (Matrix ver.)
#################################################
"""
クールノー競争。
Matrixへ変換するタイプ。
"""
function cournot_game1()
    f(x1, x2) = (100.0 - x1 - x2) * x1 - 40.0 * x1
    #actions = [i for i in 19.4:0.1:20.7]
    actions::Vector{Float64} = [i for i in 1:0.1:100]

    println("Transforming to Payoff Matrix:")
    payoff_matrix = transform_to_payoff_matrix(f, actions, actions)
    p1 = SimplifiedPlayer(1, payoff_matrix)
    p2 = SimplifiedPlayer(2, payoff_matrix)
    player_list = [p1, p2]
    g = Game(player_list)

    println("Getting Nash Equilibrium:")
    nash_idx = get_Nash_equilibrium_idx(g)
    nash = [strategy_profile(i, actions, actions) for i in nash_idx]
    @info "Nash Equilibrium:" nash_idx nash
end


#################################################
### Cournot game (Normal ver.)
#################################################
"""
クールノー競争。
利得関数をそのまま使うタイプ。実行速度が遅い。
"""
function cournot_game2()
    f(x1, x2) = (100.0 - x1 - x2) * x1 - 40.0 * x1
    actions::Vector{Float64} = [i for i in 1:0.1:100]
    p1 = Player(1, actions, f)
    p2 = Player(2, actions, f)
    player_list = [p1, p2]
    g = Game(player_list)

    println("Getting Nash Equilibrium:")
    nash = get_Nash_equilibrium(g)
    @info "Nash Equilibrium:" nash
end


#################################################
### 　非協力ゲーム理論 演習問題　３.3(a) 
#################################################
"""
非協力ゲーム理論の書籍の3.3(a)の演習問題のゲーム。
"""
function textbook_ex33a()
    payoff_matrix1 = [0 3; 5 0; 1 1]
    payoff_matrix2 = [1 2 8; 3 0 7]
    p1 = SimplifiedPlayer(1, payoff_matrix1)
    p2 = SimplifiedPlayer(2, payoff_matrix2)
    player_list = [p1, p2]
    g = Game(player_list)

    println("Getting Nash Equilibrium:")
    nash_idx = get_Nash_equilibrium_idx(g)
    nash = [strategy_profile(i, ["x1", "x2", "x3"], ["y1", "y2"]) for i in nash_idx]
    @info "Nash Equilibrium:" nash_idx nash
end


#################################################
### 　タカハトゲーム
#################################################
"""
タカハトゲーム。
Payoff Matrixを直接定義して実行するタイプ。
"""
function hawk_dove_game()
    payoff_matrix = [-2 4; 0 2]
    p1 = SimplifiedPlayer(1, payoff_matrix)
    p2 = SimplifiedPlayer(2, payoff_matrix)
    playyer_list = [p1, p2]
    g = Game(playyer_list)

    println("Getting Nash Equilibrium:")
    nash_idx = get_Nash_equilibrium_idx(g)
    nash = [strategy_profile(i, ["Hawk", "Dove"], ["Hawk", "Dove"]) for i in nash_idx]
    @info "Nash Equilibrium:" nash_idx nash
end
