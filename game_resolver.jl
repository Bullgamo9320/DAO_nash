module GameResolver
using ProgressBars
using Random
export AbstractPlayer, Player, SimplifiedPlayer, Game, get_Nash_equilibrium, get_Nash_equilibrium_idx, transform_to_payoff_matrix, strategy_profile, create_players, payoff_func

const Action = Union{Vector{String},Vector{Float64}}

abstract type AbstractPlayer end

struct SimplifiedPlayer <: AbstractPlayer
    id::Int64
    payoff_matrix::Array{Float64}
end

struct Player <: AbstractPlayer
    id::Int64
    actions::Action
    payoff_func::Function
end

struct Game
    players::Vector{Player}
end

function strategy_profiles(actions::Vector{<:Vector})
    return [collect(t) for t in Iterators.product(actions...)]
end

function nash_check(strategy_profile::Action, players::Vector{Player})::Bool
    for player in players
        i = player.id
        my_action = strategy_profile[i]
        other_actions = deleteat!(copy(strategy_profile), i)
        base_utility = player.payoff_func(my_action, other_actions)
        for alt in player.actions
            if player.payoff_func(alt, other_actions) > base_utility + 1e-8
                return false
            end
        end
    end
    return true
end

function get_Nash_equilibrium(game::Game)::Vector{Action}
    nash_list = Action[]
    actions_list = [p.actions for p in game.players]
    profiles = strategy_profiles(actions_list)
    for profile in ProgressBar(profiles)
        if nash_check(profile, game.players)
            push!(nash_list, profile)
        end
    end
    return nash_list
end

function best_response_check(payoff_matrix::Array{Float64}, profile_idx::CartesianIndex)::Bool
    current_payoff = payoff_matrix[profile_idx]
    reduced_idx = CartesianIndex(Tuple(profile_idx)[2:end])
    payoff_vector = payoff_matrix[:, reduced_idx]
    return all(current_payoff >= payoff for payoff in payoff_vector)
end

function get_Nash_equilibrium_idx(game::Game)::Vector{CartesianIndex}
    nash_list = CartesianIndex[]
    p1_payoff_matrix = game.players[1].payoff_matrix
    for profile_idx in ProgressBar(CartesianIndices(p1_payoff_matrix))
        if all(best_response_check(player.payoff_matrix, CartesianIndex(profile_idx[player.id], Tuple(deleteat!(collect(Tuple(profile_idx)), player.id)))) for player in game.players)
            push!(nash_list, profile_idx)
        end
    end
    return nash_list
end

function transform_to_payoff_matrix(payoff_function::Function, my_actions::Action, others_actions::Action...)::Array{Float64}
    dims = (length(my_actions), map(length, others_actions)...)
    payoff_matrix = Array{Float64}(undef, dims...)
    for idx in ProgressBar(CartesianIndices(dims))
        acts = [my_actions[idx[1]]; [others_actions[i][idx[i+1]] for i in 1:length(others_actions)]]
        payoff_matrix[idx] = payoff_function(acts...)
    end
    return payoff_matrix
end

import Distributions

global player_wjs = Dict{Int, Float64}()

function create_players(n)
    empty!(player_wjs)  # ← これ大事！
    players = Vector{Player}(undef, n)
    for i in 1:n
        w_j = rand()
        player_wjs[i] = w_j
        players[i] = Player(i, [0.0, 1.0, 2.0], (my_action, other_actions) -> payoff_func(i, my_action, other_actions, w_j))
    end
    return players
end

function payoff_func(player_id, my_action, other_actions, w_j)
    P, k, a, c = 0.5, 10, 0.3, 10000.0

    # 安全に他プレイヤーのw_j取得
    others = [player_wjs[i] for i in 1:length(player_wjs) if i != player_id]

    sum_w = sum((w for (a, w) in zip(other_actions, others) if a != 0.0); init=0.0)
    total_w = sum_w + w_j

    if my_action == 0.0  # leave
        return P * 0.7 * w_j - k
    elseif my_action == 1.0  # stay
        return w_j * (P * 0.7 + 0.1 * P) + a * P * 0.7 * w_j + c * (w_j / total_w)^2
    elseif my_action == 2.0  # buy
        buy_unit = 0.5 * w_j
        new_wj = w_j + buy_unit
        new_total_w = sum_w + new_wj
        governance_delta = c * (new_wj / new_total_w)^2 - c * (w_j / total_w)^2
        marginal_util = buy_unit * (P * 0.7 + 0.1 * P) + a * P * 0.7 * buy_unit
        return marginal_util + governance_delta - buy_unit * P
    else
        return -1e9
    end
end



end




# module GameResolver
# using ProgressBars
# using Random
# export AbstractPlayer, Player, SimplifiedPlayer, Game, get_Nash_equilibrium, get_Nash_equilibrium_idx, transform_to_payoff_matrix, strategy_profile, create_players, payoff_func


# #####################################################
# ###### Type alias #######################################
# #####################################################
# """
# プレイヤの持つアクションの型をエイリアスとして設定
# StringのリストかFloat64のリストとして設定
# """
# const Action = Union{Vector{String},Vector{Float64}}


# #####################################################
# ###### Struct #######################################
# #####################################################
# abstract type AbstractPlayer end

# struct SimplifiedPlayer <: AbstractPlayer
#     id::Int64 #プレイヤのindexを表す。重複しないこと。
#     payoff_matrix::Array{Float64}
# end

# struct Player <: AbstractPlayer
#     id::Int64 #プレイヤのindexを表す。重複しないこと。
#     actions::Action
#     payoff_func::Function #自分の行動を1つ目の引数に、他のプレイヤの行動のリストを第２引数にとる関数として定義すること（e.g f(s_1, s_{-i})）
# end

# struct Game
#     players::Vector{AbstractPlayer}
# end


# #####################################################
# ###### Function #####################################
# #####################################################
# """
#     strategy_profiles(actions1,actions2) -> Channel{Action}

# すべてのプレイヤのAction (行動のリスト) を引数として、その直積集合のcollectionを生成する　
# Generates the collection of the CartesianProduct created from all player's actions as arguments

# the arguments of actions1, actions2, ...

# # Arguments:
# * action::Action: The list of actions that a plyer has
# """
# function strategy_profiles(action::Action...)::Channel{Action}
#     #各プレイヤが持つ行動の数をリストにしたもの
#     size_of_each_action::Vector{Int} = [length(i) for i in action]

#     #PythonのGenerator的にChannelを使う
#     Channel{Action}() do channel
#         for indices in CartesianIndices(tuple(size_of_each_action...))
#             list = [action[i][indices[i]] for i in 1:length(indices)] #eachindexが使えない
#             put!(channel, list)
#         end
#     end
# end

# """
# CartesianIndexから対応する戦略プロファイル（Vector{String} or Vector{Float64}）を返す。
# """
# function strategy_profile(idx::CartesianIndex, actions::Action...)::Action
#     # CartesianIndex から戦略プロファイルを返す
#     #あとで作る
#     return [action[idx[i]] for (i, action) in enumerate(actions)]
# end


# """
# strategy_profileがナッシュ均衡であれば、trueを返す。ナッシュ均衡でなければ、falseを返す。
# """
# function nash_check(strategy_profile::Action, players::Player...)::Bool
#     for player in players
#         i = player.id
#         my_action = strategy_profile[i]
#         other_strategy_profile = deleteat!(copy(strategy_profile), i)

#         #引数で与えられた戦略プロファイルにおける利得の値を代入
#         payoff_value = player.payoff_func(my_action, other_strategy_profile...)

#         #上記の利得を上回る戦略があればfalseを返してループを中断
#         for action in player.actions
#             if payoff_value < player.payoff_func(action, other_strategy_profile...)
#                 return false
#             end
#         end
#     end
#     #全てのプレイヤーについて、payoff_value の方が高ければNash均衡となっている
#     return true
# end

# """
# 引数のgameからナッシュ均衡を計算し、リストとして返す。
# """
# function get_Nash_equilibrium(game::Game)::Vector{Action}
#     nash_list::Vector{Action} = []
#     actions_list = [p.actions for p in game.players]

#     total_repetition = reduce(*, [length(i) for i in actions_list])
#     p_bar = ProgressBar(total=total_repetition)
#     for strategy_profile in strategy_profiles(actions_list...)
#         if nash_check(strategy_profile, game.players...)
#             push!(nash_list, strategy_profile)
#         end
#         update(p_bar)
#     end
#     return nash_list
# end


# ############ 以下からMatrixバージョン ######################
# """
#     best_response_check(payoff_matrix, profile_idx) -> Bool

# Check if the strategy profile is a best reponse or not on a player basis

# # Arguments
# * `payoff_matrix::Array{Float16}`: The target player's payoff matrix
# * `idx::CartesianIndex`: the Cartesian index of the payoff matrix corresponding to a certain strategy profile to be checked
# """
# function best_response_check(payoff_matrix::Array{Float64}, profile_idx::CartesianIndex)::Bool
#     current_payoff = payoff_matrix[profile_idx]
#     reduced_idx = CartesianIndex(Tuple(profile_idx)[2:end]) #最初のプレイヤを除いたidx
#     payoff_vector = payoff_matrix[:, reduced_idx] #他のプレイヤの行動を固定した時の、Player1の取りうる利得を格納したVector

#     for payoff in payoff_vector
#         if current_payoff < payoff
#             return false
#         end
#     end
#     return true #current_payoffが最も高ければ、そればBest Reponse
# end


# """
#     get_Nash_equilibrium_idx(game) -> Array{CartesianIndex}

# Obtain the Nash equilibrium list. Please note that the list has the CartesianIndex values, each of which corresponds to a strartegy profile of Nash equilibria in the game.

# # Arguments
# * `game::Game`: The struct named Game
# """
# function get_Nash_equilibrium_idx(game::Game)::Vector{CartesianIndex}
#     nash_list::Vector{CartesianIndex} = []
#     p1_payoff_matrix = game.players[1].payoff_matrix #代表でPlayer1のものを代入

#     for profile_idx in ProgressBar(CartesianIndices(p1_payoff_matrix))
#         br_flg = true
#         for player in game.players
#             i = player.id #PlayerのIDがそのままindexになるように対応をとっておくこと！
#             value_at_i = profile_idx[i]
#             reduce_profile_idx = CartesianIndex(Tuple(deleteat!(collect(Tuple(profile_idx)), i)))
#             arranged_profile_idx = CartesianIndex(value_at_i, reduce_profile_idx)

#             if !best_response_check(player.payoff_matrix, arranged_profile_idx)
#                 br_flg = false
#                 break
#             end
#         end
#         if br_flg
#             push!(nash_list, profile_idx)
#         end
#     end
#     nash_list
# end

# """
# 利得関数からmatrix形式へ変換する。
# """
# function transform_to_payoff_matrix(payoff_function::Function, my_actions::Action, others_actions::Action...)::Array{Float64}
#     #Payoff matrixの次元を取得
#     dim = Tuple(Iterators.flatten([length(my_actions), [length(i) for i in others_actions]]))

#     # 0で初期化
#     payoff_matrix = zeros(dim)

#     # payoff matrix を生成
#     for idx in ProgressBar(CartesianIndices(dim))
#         action_list = [my_actions[idx[1]]]
#         temp_others_actions = [actions[idx[i+1]] for (i, actions) in enumerate(others_actions)]

#         #繋げて1つの strategy profile に
#         append!(action_list, temp_others_actions)
#         payoff_matrix[idx] = payoff_function(action_list...)
#     end
#     payoff_matrix
# end

# import Distributions

# # プレイヤーの w_j 値を格納するためのグローバル辞書
# global player_wjs = Dict{Int, Float64}()

# function create_players(n)
#     players = Vector{Player}(undef, n)
#     for i in 1:n
#         w_j = rand()
#         player_wjs[i] = w_j  # 辞書に w_j 値を格納
#         players[i] = Player(i, ["stay", "leave"], (my_action, other_actions...) -> payoff_func(i, my_action, other_actions, w_j))
#     end
#     return players
# end

# function payoff_func(player_id, my_action, other_actions, w_j)
#     P = 0.5
#     k = 10

#     # 他のプレイヤーの w_j 値の合計を計算
#     sum_w = sum([Float64(player_wjs[id]) for id in 1:length(other_actions) if other_actions[id] != "leave" && id != player_id])
#     sum_w -= my_action == "leave" ? w_j : 0.0

#     # 以下は以前と同じ
#     if my_action == "stay"
#         return w_j * (P + P) * 10 * w_j + 5 + 13 * (w_j / (sum_w + w_j))^2 + 7 * (w_j / (sum_w + w_j))
#     else  # "leave"
#         return w_j * P - k
#     end
# end




# # ナッシュ均衡の計算
# """
# function find_nash_equilibrium(n)
#     players = create_players(n)
#     game = Game(players)
#     return get_Nash_equilibrium(game)
# end
# """

# end # End of module
